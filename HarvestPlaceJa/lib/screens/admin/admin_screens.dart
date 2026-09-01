// HPJ RC2K HOTFIX 003 VERIFIED REPLACEMENT — 2026-08-27
// Compile repair base: Hotfix 002 + visible verification marker.
part of harvest_place_app;

List<HomeHeroSlide> _mergeHomeHeroSlidesToFour(
  List<HomeHeroSlide> savedSlides,
) {
  final byPosition = <int, HomeHeroSlide>{};

  for (final slide in savedSlides) {
    if (slide.position >= 1 && slide.position <= 4) {
      byPosition[slide.position] = slide;
    }
  }

  final defaults = defaultHomeHeroSlides();

  return List<HomeHeroSlide>.generate(
    4,
    (index) {
      final position = index + 1;

      final savedSlide = byPosition[position];
      if (savedSlide != null) {
        return savedSlide;
      }

      if (index < defaults.length) {
        return defaults[index];
      }

      return HomeHeroSlide(
        id: 'default-$position',
        position: position,
        imageUrl: defaults.isNotEmpty ? defaults.last.imageUrl : '',
        isActive: true,
      );
    },
  );
}

Future<List<HomeHeroSlide>> fetchAdminHomeHeroSlides() async {
  await requireAdminAccess();

  try {
    final response = await supabase
        .from('home_hero_slides')
        .select(
          'id, position, image_url, title, subtitle, is_active, updated_at',
        )
        .order('position', ascending: true);

    final slides = (response as List)
        .map(
          (row) => HomeHeroSlide.fromSupabase(
            Map<String, dynamic>.from(row),
          ),
        )
        .toList();

    return _mergeHomeHeroSlidesToFour(slides);
  } catch (error) {
    farmDebugLog(
      'Admin hero slides unavailable: $error',
    );

    return _mergeHomeHeroSlidesToFour(
      const <HomeHeroSlide>[],
    );
  }
}

Future<List<HomeHeroSlide>> fetchPublicHomeHeroSlides() async {
  try {
    final response = await supabase
        .from('home_hero_slides')
        .select(
          'id, position, image_url, title, subtitle, is_active, updated_at',
        )
        .eq('is_active', true)
        .order('position', ascending: true);

    final slides = (response as List)
        .map(
          (row) => HomeHeroSlide.fromSupabase(
            Map<String, dynamic>.from(row),
          ),
        )
        .toList();

    return _mergeHomeHeroSlidesToFour(slides);
  } catch (error) {
    farmDebugLog(
      'Public home hero slides unavailable: $error',
    );

    return _mergeHomeHeroSlidesToFour(
      const <HomeHeroSlide>[],
    );
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
  String? actionType,
  String? actionId,
  String? dedupeKey,
}) async {
  final cleanType = type.trim().toLowerCase().isEmpty
      ? 'admin'
      : type.trim().toLowerCase();
  final cleanOrderId = orderId?.trim() ?? '';
  var resolvedActionType =
      hpjCanonicalNotificationActionType(actionType);
  var resolvedActionId = actionId?.trim() ?? '';

  // Staff notifications must never inherit the shared customer order fallback.
  if (resolvedActionType.isEmpty && cleanOrderId.isNotEmpty) {
    resolvedActionType = 'admin_customer_order';
    resolvedActionId = cleanOrderId;
  }

  if (resolvedActionType.isEmpty) {
    switch (cleanType) {
      case 'stock':
      case 'product_ready':
        resolvedActionType = 'admin_inventory';
        break;
      case 'review':
        resolvedActionType = 'admin_review';
        break;
      case 'farmer':
        resolvedActionType = 'admin_farmer_application';
        break;
      case 'support':
        resolvedActionType = 'admin_support_chat';
        break;
    }
  }

  if (resolvedActionId.isEmpty &&
      cleanOrderId.isNotEmpty &&
      resolvedActionType == 'admin_customer_order') {
    resolvedActionId = cleanOrderId;
  }

  if (resolvedActionType.isEmpty) {
    farmDebugLog(
      'Admin notification has no explicit destination: "$title".',
    );
  } else if (hpjNotificationActionBenefitsFromId(resolvedActionType) &&
      resolvedActionId.isEmpty) {
    farmDebugLog(
      'Admin notification destination $resolvedActionType has no record id: '
      '"$title".',
    );
  }

  try {
    final targets = await fetchAdminNotificationTargets();
    if (targets.isEmpty) {
      farmDebugLog(
          'Admin notification skipped because no admin target was found.');
      return;
    }

    for (final target in targets) {
      final targetKey = target.userId?.trim().isNotEmpty == true
          ? target.userId!.trim()
          : (target.userEmail ?? '').trim().toLowerCase();

      await createFarmNotification(
        title: title,
        message: message,
        type: cleanType,
        userId: target.userId,
        userEmail: target.userEmail,
        orderId: cleanOrderId.isEmpty ? null : cleanOrderId,
        actionType:
            resolvedActionType.isEmpty ? null : resolvedActionType,
        actionId: resolvedActionId.isEmpty ? null : resolvedActionId,
        dedupeKey: dedupeKey == null || dedupeKey.trim().isEmpty
            ? null
            : '${dedupeKey.trim()}:${targetKey.isEmpty ? 'staff' : targetKey}',
      );
    }
  } catch (error) {
    farmDebugLog('Admin notification skipped: $error');
  }
}


// =====================================================
// ADMIN HELP & TUTORIALS
// Repair 030
// Owner/Manager can create, edit, publish, hide and delete tutorial links.
// =====================================================

Future<void> _requireHelpTutorialAdminAccess() async {
  await requireAdminAccess();

  final role = normalizeStaffRole(await fetchCurrentStaffRole());

  // Empty role is retained as a compatibility path for legacy admin_users
  // accounts. Current staff accounts must be Owner or Manager.
  if (role.isNotEmpty && role != 'owner' && role != 'manager') {
    throw Exception('Only Owner or Manager can manage help tutorials.');
  }
}

Future<List<HpjHelpTutorial>> fetchAdminHelpTutorials() async {
  await _requireHelpTutorialAdminAccess();

  try {
    final response = await supabase
        .from('help_tutorials')
        .select(
          'id, title, button_label, description, video_url, thumbnail_url, placement, audience, is_published, sort_order, created_at, updated_at',
        )
        .order('placement', ascending: true)
        .order('sort_order', ascending: true)
        .order('updated_at', ascending: false);

    return (response as List)
        .map(
          (item) => HpjHelpTutorial.fromSupabase(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  } catch (error) {
    throw Exception(
      'Could not load Help & Tutorials. Run Repair 030 SQL in Supabase, then retry.',
    );
  }
}

Future<void> saveAdminHelpTutorial({
  String? id,
  required String title,
  required String buttonLabel,
  required String description,
  required String videoUrl,
  String? thumbnailUrl,
  required String placement,
  required String audience,
  required bool isPublished,
  required int sortOrder,
}) async {
  await _requireHelpTutorialAdminAccess();

  final cleanId = id?.trim() ?? '';
  final cleanTitle = title.trim();
  final cleanButtonLabel = buttonLabel.trim();
  final cleanDescription = description.trim();
  final cleanVideoUrl = videoUrl.trim();
  final cleanThumbnailUrl = thumbnailUrl?.trim() ?? '';
  final cleanPlacement = placement.trim().toLowerCase();
  final cleanAudience = audience.trim().toLowerCase();

  if (cleanTitle.isEmpty) {
    throw Exception('Enter a tutorial title.');
  }

  if (cleanButtonLabel.isEmpty) {
    throw Exception('Enter a button label.');
  }

  if (!_isSafeHelpTutorialUrl(cleanVideoUrl)) {
    throw Exception(
      'Enter a valid https:// or http:// video URL.',
    );
  }

  if (cleanThumbnailUrl.isNotEmpty &&
      !_isSafeHelpTutorialUrl(cleanThumbnailUrl)) {
    throw Exception(
      'Thumbnail URL must start with https:// or http://.',
    );
  }

  if (!hpjHelpTutorialPlacementLabels.containsKey(cleanPlacement)) {
    throw Exception('Choose a valid tutorial placement.');
  }

  if (!hpjHelpTutorialAudienceLabels.containsKey(cleanAudience)) {
    throw Exception('Choose a valid tutorial audience.');
  }

  final safeSortOrder = sortOrder.clamp(0, 9999);

  final payload = <String, dynamic>{
    'title': cleanTitle,
    'button_label': cleanButtonLabel,
    'description': cleanDescription,
    'video_url': cleanVideoUrl,
    'thumbnail_url':
        cleanThumbnailUrl.isEmpty ? null : cleanThumbnailUrl,
    'placement': cleanPlacement,
    'audience': cleanAudience,
    'is_published': isPublished,
    'sort_order': safeSortOrder,
  };

  try {
    if (cleanId.isEmpty) {
      await supabase.from('help_tutorials').insert(payload);
    } else {
      await supabase
          .from('help_tutorials')
          .update(payload)
          .eq('id', cleanId);
    }
  } catch (error) {
    throw Exception(
      'Could not save the tutorial. Check Repair 030 SQL and your Owner/Manager permission.',
    );
  }
}

Future<void> setAdminHelpTutorialPublished({
  required HpjHelpTutorial tutorial,
  required bool isPublished,
}) async {
  await saveAdminHelpTutorial(
    id: tutorial.id,
    title: tutorial.title,
    buttonLabel: tutorial.buttonLabel,
    description: tutorial.description,
    videoUrl: tutorial.videoUrl,
    thumbnailUrl: tutorial.thumbnailUrl,
    placement: tutorial.placement,
    audience: tutorial.audience,
    isPublished: isPublished,
    sortOrder: tutorial.sortOrder,
  );
}

Future<void> deleteAdminHelpTutorial(
  HpjHelpTutorial tutorial,
) async {
  await _requireHelpTutorialAdminAccess();

  final id = tutorial.id.trim();
  if (id.isEmpty) return;

  try {
    await supabase
        .from('help_tutorials')
        .delete()
        .eq('id', id);
  } catch (error) {
    throw Exception(
      'Could not delete the tutorial. Check your Owner/Manager permission.',
    );
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
        actionType: 'admin_inventory',
        actionId: product.id,
        dedupeKey:
            'admin-stock:${product.id}:${product.stockQuantity}',
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
      return 'Can view only assigned delivery tasks, contact customers, open navigation, upload proof, and update delivery progress.';
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

bool _isSupabaseJwtTimingError(
  Object error,
) {
  if (error is PostgrestException) {
    final code = (error.code ?? '')
        .trim()
        .toUpperCase();
    final message = error.message
        .trim()
        .toLowerCase();

    return code == 'PGRST303' &&
        (message.contains(
              'jwt issued at future',
            ) ||
            message.contains(
              'jwt',
            ));
  }

  final raw =
      error.toString().toLowerCase();

  return raw.contains('pgrst303') &&
      raw.contains('jwt');
}

Future<bool> _refreshHpJAuthSession() async {
  final session =
      supabase.auth.currentSession;

  if (session == null) return false;

  try {
    final response =
        await supabase.auth.refreshSession();

    return response.session != null;
  } catch (error) {
    farmDebugLog(
      'HPJ auth session refresh failed: $error',
    );
    return false;
  }
}

Future<String> _fetchCurrentStaffRoleOnce() async {
  final user = supabase.auth.currentUser;
  if (user == null) return '';

  Object? rpcError;

  try {
    final response =
        await supabase.rpc(
      'current_staff_role',
    );

    final role = normalizeStaffRole(
      response?.toString(),
    );

    if (role.isNotEmpty) {
      return role;
    }
  } catch (error) {
    rpcError = error;

    if (!_isSupabaseJwtTimingError(
      error,
    )) {
      farmDebugLog(
        'Staff role RPC lookup skipped: $error',
      );
    }
  }

  final email =
      (user.email ?? '')
          .trim()
          .toLowerCase();

  if (email.isEmpty) {
    if (rpcError != null &&
        _isSupabaseJwtTimingError(
          rpcError,
        )) {
      throw rpcError;
    }

    return '';
  }

  try {
    final response = await supabase
        .from('staff_users')
        .select('role, is_active')
        .ilike('email', email)
        .eq('is_active', true)
        .maybeSingle();

    if (response == null) {
      if (rpcError != null &&
          _isSupabaseJwtTimingError(
            rpcError,
          )) {
        throw rpcError;
      }

      return '';
    }

    final row =
        Map<String, dynamic>.from(
      response as Map,
    );

    return normalizeStaffRole(
      row['role']?.toString(),
    );
  } catch (error) {
    if (_isSupabaseJwtTimingError(
      error,
    )) {
      rethrow;
    }

    farmDebugLog(
      'Staff role direct lookup skipped: $error',
    );

    return '';
  }
}

Future<String> fetchCurrentStaffRole() async {
  final user = supabase.auth.currentUser;
  if (user == null) return '';

  try {
    return await _fetchCurrentStaffRoleOnce();
  } catch (error) {
    if (!_isSupabaseJwtTimingError(error)) {
      farmDebugLog(
        'Staff role lookup unavailable: $error',
      );
      return '';
    }

    farmDebugLog(
      'HPJ session timing mismatch detected. Refreshing the signed-in session.',
    );

    final refreshed =
        await _refreshHpJAuthSession();

    if (!refreshed) {
      throw Exception(
        'Your HPJ sign-in session needs to be refreshed. Please sign out and sign in again, then retry.',
      );
    }

    try {
      return await _fetchCurrentStaffRoleOnce();
    } catch (retryError) {
      if (_isSupabaseJwtTimingError(
        retryError,
      )) {
        throw Exception(
          'HPJ could not verify your sign-in session yet. Please sign out and sign in again, then retry.',
        );
      }

      farmDebugLog(
        'Staff role lookup unavailable after session refresh: $retryError',
      );

      return '';
    }
  }
}

Future<bool> isCurrentUserAdminFromDatabase() async {
  final user = supabase.auth.currentUser;
  if (user == null) return false;

  // Preferred release-safe check. Migration 007 installs this as a
  // SECURITY DEFINER helper so Owner/Manager verification is not blocked by
  // staff_users/admin_users RLS. Older databases simply fall through to the
  // existing compatibility checks below.
  try {
    final secureRoleCheck = await supabase.rpc(
      'hpj_user_has_staff_role',
      params: {
        'p_roles': <String>[
          'owner',
          'manager',
          'packer',
          'delivery',
          'inventory',
          'support',
        ],
      },
    );

    if (secureRoleCheck == true) return true;
  } catch (error) {
    farmDebugLog(
      'Secure staff role helper unavailable; using compatibility checks: $error',
    );
  }

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
  try {
    final allowed =
        await isCurrentUserAdminFromDatabase();

    if (allowed) return;
  } catch (error) {
    final lower =
        error.toString().toLowerCase();

    if (!_isSupabaseJwtTimingError(
          error,
        ) &&
        !lower.contains(
          'sign-in session',
        )) {
      rethrow;
    }
  }

  // A valid owner/manager can temporarily look unauthorised when
  // PostgREST rejects a freshly issued JWT (PGRST303). Refresh once,
  // then perform the database permission check again.
  final refreshed =
      await _refreshHpJAuthSession();

  if (refreshed) {
    try {
      final allowedAfterRefresh =
          await isCurrentUserAdminFromDatabase();

      if (allowedAfterRefresh) {
        return;
      }
    } catch (error) {
      final lower =
          error.toString().toLowerCase();

      if (_isSupabaseJwtTimingError(
            error,
          ) ||
          lower.contains(
            'sign-in session',
          )) {
        throw Exception(
          'HPJ could not verify your sign-in session. Please sign out and sign in again, then retry.',
        );
      }

      rethrow;
    }
  }

  throw Exception(
    'Admin permission required. If you are an authorised staff member, sign out and sign in again before retrying.',
  );
}

Future<List<SupportTicket>> fetchAdminSupportTickets() async {
  final staffRole = await fetchCurrentStaffRole();
  if (staffRole.isNotEmpty &&
      !<String>{'owner', 'manager', 'support'}.contains(staffRole)) {
    return const <SupportTicket>[];
  }

  if (staffRole.isEmpty) {
    final allowed = await isCurrentUserAdminFromDatabase();
    if (!allowed) return const <SupportTicket>[];
  }

  try {
    final response = await supabase
        .from('support_tickets')
        .select(_supportTicketSelectFields)
        .order('last_message_at', ascending: false)
        .order('created_at', ascending: false)
        .limit(100);

    return (response as List)
        .map((item) =>
            SupportTicket.fromSupabase(Map<String, dynamic>.from(item as Map)))
        .toList();
  } catch (error) {
    farmDebugLog('Failed to fetch private Customer Care inbox: $error');
    return const <SupportTicket>[];
  }
}

class _FarmerAccessGateSnapshot {
  final MarketplaceProgramSettings settings;
  final FarmerProfile? profile;

  const _FarmerAccessGateSnapshot({
    required this.settings,
    required this.profile,
  });
}

Future<_FarmerAccessGateSnapshot> fetchFarmerAccessGateSnapshot() async {
  final values = await Future.wait<dynamic>([
    fetchMarketplaceProgramSettings(),
    fetchCurrentFarmerProfile(),
  ]);

  return _FarmerAccessGateSnapshot(
    settings: values[0] as MarketplaceProgramSettings,
    profile: values[1] as FarmerProfile?,
  );
}

PreferredSizeWidget _farmerWorkspaceAppBar(
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
      IconButton(
        tooltip: 'Switch Workspace',
        onPressed: () {
          navigator.push(
            MaterialPageRoute<void>(
              builder: (_) => const OwnerWorkspaceSwitcherScreen(
                currentWorkspace: 'farmer',
              ),
            ),
          );
        },
        icon: const Icon(Icons.apps_rounded),
      ),
    ],
  );
}

class FarmerAccessGate extends StatelessWidget {
  final int initialTab;
  final String? initialRecordId;

  const FarmerAccessGate({
    super.key,
    this.initialTab = 0,
    this.initialRecordId,
  });

  void _retryAccess(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => FarmerAccessGate(
          initialTab: initialTab,
          initialRecordId: initialRecordId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!isLoggedIn || supabase.auth.currentUser == null) {
      return const GuestProtectedScreen(
        title: 'Farmer Partner',
        subtitle: 'Apply to sell with us',
        message: 'Sign in with your customer account to apply as a farmer.',
      );
    }

    return FutureBuilder<_FarmerAccessGateSnapshot>(
      future: fetchFarmerAccessGateSnapshot(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            snapshot.data == null) {
          return Scaffold(
            backgroundColor: FarmColors.background,
            appBar: _farmerWorkspaceAppBar(context, 'Farmer Partner'),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data;
        if (data == null) {
          return Scaffold(
            backgroundColor: FarmColors.background,
            appBar: _farmerWorkspaceAppBar(context, 'Farmer Partner'),
            body: FarmPage(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
                children: [
                  _MarketplaceProgramNotice(
                    icon: Icons.error_outline,
                    title: 'Could not load farmer access',
                    message:
                        'Please check your connection and try again.',
                    actionLabel: 'Try Again',
                    onAction: () => _retryAccess(context),
                  ),
                ],
              ),
            ),
          );
        }

        final profile = data.profile;
        final settings = data.settings;

        if (profile == null && !settings.farmerApplicationsEnabled) {
          return Scaffold(
            backgroundColor: FarmColors.background,
            appBar: _farmerWorkspaceAppBar(context, 'Farmer Partner'),
            body: FarmPage(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
                children: [
                  _MarketplaceProgramNotice(
                    icon: Icons.agriculture_outlined,
                    title: 'Farmer applications are paused',
                    message:
                        'You can continue shopping as a customer. Please check again when farmer applications reopen.',
                    actionLabel: 'Refresh Status',
                    onAction: () => _retryAccess(context),
                  ),
                ],
              ),
            ),
          );
        }

        if (profile == null) {
          return const FarmerPartnerIntroScreen();
        }

        if (!profile.isApproved) {
          final status =
              profile.verificationStatus.trim().toLowerCase();
          final rejected = status == 'rejected';

          return Scaffold(
            backgroundColor: FarmColors.background,
            appBar: _farmerWorkspaceAppBar(
              context,
              'Farmer Partner',
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
                  FarmerStatusCard(profile: profile),
                  const SizedBox(height: 14),
                  _MarketplaceProgramNotice(
                    icon: rejected
                        ? Icons.info_outline_rounded
                        : Icons.schedule_outlined,
                    title: rejected
                        ? 'Farmer application needs attention'
                        : 'Farmer application under review',
                    message: rejected
                        ? 'Your Farmer workspace is not active. Review your application details or contact HPJ Support if you need help before trying again.'
                        : 'HPJ is reviewing your Farmer application. Supply, collections, payouts and Farmer market-demand tools will unlock after approval.',
                    actionLabel: 'Refresh Status',
                    onAction: () => _retryAccess(context),
                  ),
                ],
              ),
            ),
          );
        }

        if (!settings.farmerWorkspaceEnabled) {
          return Scaffold(
            backgroundColor: FarmColors.background,
            appBar: _farmerWorkspaceAppBar(context, 'Farmer Workspace'),
            body: FarmPage(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
                children: [
                  _MarketplaceProgramNotice(
                    icon: Icons.pause_circle_outline,
                    title: 'Farmer workspace is temporarily paused',
                    message:
                        'Your farmer profile and approval status are safe. Regular customer shopping remains available.',
                    actionLabel: 'Refresh Status',
                    onAction: () => _retryAccess(context),
                  ),
                ],
              ),
            ),
          );
        }

        return FarmerMarketplaceShell(
          profile: profile,
          initialIndex: initialTab,
          initialRecordId: initialRecordId,
        );
      },
    );
  }
}

class FarmerPartnerIntroScreen extends StatelessWidget {
  const FarmerPartnerIntroScreen({
    super.key,
  });

  void _join(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            const FarmerOnboardingScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: _farmerWorkspaceAppBar(
        context,
        'Farmer Partner',
      ),
      body: FarmPage(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            18,
            18,
            18,
            100,
          ),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(
                18,
                20,
                18,
                18,
              ),
              decoration: BoxDecoration(
                color: FarmColors.card,
                borderRadius:
                    BorderRadius.circular(24),
                border: Border.all(
                  color: FarmColors.line,
                ),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'FARMER PARTNER',
                    style: TextStyle(
                      color: FarmColors.primary,
                      fontSize: 9,
                      fontWeight:
                          FontWeight.w900,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Sell with better information.',
                    style: TextStyle(
                      color: FarmColors.ink,
                      fontSize: 25,
                      height: 1.05,
                      fontWeight:
                          FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tell HPJ what you expect to harvest. We use that information to help connect farmer supply with real buyer demand and collection planning.',
                    style: TextStyle(
                      color:
                          FarmColors.mutedText,
                      fontSize: 11.2,
                      height: 1.42,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 17),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () =>
                          _join(context),
                      child: const Text(
                        'Join as a Farmer',
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Start with basic farm details. You can add payment and other information later.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color:
                          FarmColors.mutedText,
                      fontSize: 8.9,
                      height: 1.3,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'What you get from HPJ',
              style: TextStyle(
                color: FarmColors.ink,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),

            const SizedBox(height: 9),

            const FarmCard(
              padding: EdgeInsets.all(14),
              child: Column(
                children: [
                  _FarmerBenefitRow(
                    icon:
                        Icons.storefront_outlined,
                    title: 'See buyer demand',
                    message:
                        'Know when HPJ has visible demand for produce you grow.',
                  ),
                  Divider(height: 20),
                  _FarmerBenefitRow(
                    icon:
                        Icons.calendar_month_outlined,
                    title: 'Plan before harvest',
                    message:
                        'Share expected quantities and harvest dates before produce is ready.',
                  ),
                  Divider(height: 20),
                  _FarmerBenefitRow(
                    icon:
                        Icons.local_shipping_outlined,
                    title:
                        'Collection coordination',
                    message:
                        'When supply is matched, HPJ can help organize the next collection steps.',
                  ),
                  Divider(height: 20),
                  _FarmerBenefitRow(
                    icon:
                        Icons.payments_outlined,
                    title: 'Track your money',
                    message:
                        'See payout progress and keep a record of your HPJ activity.',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4EC),
                borderRadius:
                    BorderRadius.circular(15),
                border: Border.all(
                  color: const Color(0xFFDCE4D8),
                ),
              ),
              child: const Text(
                'HPJ helps farmers share supply information and connect with market opportunities. Joining does not guarantee a sale, but keeping your supply current gives HPJ better information for matching and planning.',
                style: TextStyle(
                  color: Color(0xFF5F6D65),
                  fontSize: 9.5,
                  height: 1.4,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FarmerBenefitRow
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _FarmerBenefitRow({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: FarmColors.primarySoft,
            borderRadius:
                BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: FarmColors.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: FarmColors.ink,
                  fontSize: 11.4,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                message,
                style: const TextStyle(
                  color:
                      FarmColors.mutedText,
                  fontSize: 9.5,
                  height: 1.32,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class FarmerOnboardingScreen
    extends StatefulWidget {
  const FarmerOnboardingScreen({
    super.key,
  });

  @override
  State<FarmerOnboardingScreen>
      createState() =>
          _FarmerOnboardingScreenState();
}

class _FarmerOnboardingScreenState
    extends State<FarmerOnboardingScreen> {
  final farmNameController =
      TextEditingController();
  final farmerNameController =
      TextEditingController();
  final phoneController =
      TextEditingController();
  final parishController =
      TextEditingController();

  final addressController =
      TextEditingController();
  final bioController =
      TextEditingController();
  final payoutMethodController =
      TextEditingController();
  final payoutDetailsController =
      TextEditingController();

  bool showOptionalDetails = false;
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
    if (farmNameController.text
            .trim()
            .isEmpty ||
        farmerNameController.text
            .trim()
            .isEmpty ||
        phoneController.text
            .trim()
            .isEmpty ||
        parishController.text
            .trim()
            .isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Please complete farm name, farmer name, phone, and parish.',
          ),
        ),
      );
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      await saveFarmerProfile(
        farmName:
            farmNameController.text.trim(),
        farmerName:
            farmerNameController.text.trim(),
        phone:
            phoneController.text.trim(),
        parish:
            parishController.text.trim(),
        address:
            addressController.text.trim(),
        bio: bioController.text.trim(),
        payoutMethod:
            payoutMethodController.text.trim(),
        payoutDetails:
            payoutDetailsController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Farmer application submitted.',
          ),
        ),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => const FarmerAccessGate(),
        ),
        (route) => false,
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Could not save farmer profile: ${friendlyAppError(error)}',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          FarmColors.background,
      appBar: AppBar(
        title:
            const Text('Join as a Farmer'),
      ),
      body: FarmPage(
        child: ListView(
          padding:
              const EdgeInsets.fromLTRB(
            18,
            16,
            18,
            96,
          ),
          children: [
            const Text(
              'Start with the basics',
              style: TextStyle(
                color: FarmColors.ink,
                fontSize: 22,
                height: 1.05,
                fontWeight:
                    FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'This should take about a minute. HPJ only needs the essentials to start your farmer application.',
              style: TextStyle(
                color:
                    FarmColors.mutedText,
                fontSize: 10.5,
                height: 1.4,
                fontWeight:
                    FontWeight.w600,
              ),
            ),

            const SizedBox(height: 16),

            FarmCard(
              padding:
                  const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Farm details',
                    style: TextStyle(
                      color: FarmColors.ink,
                      fontSize: 13,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller:
                        farmNameController,
                    enabled: !loading,
                    decoration:
                        const InputDecoration(
                      labelText: 'Farm name',
                    ),
                  ),
                  const SizedBox(height: 11),

                  TextField(
                    controller:
                        farmerNameController,
                    enabled: !loading,
                    decoration:
                        const InputDecoration(
                      labelText:
                          'Farmer name',
                    ),
                  ),
                  const SizedBox(height: 11),

                  TextField(
                    controller:
                        phoneController,
                    enabled: !loading,
                    keyboardType:
                        TextInputType.phone,
                    decoration:
                        const InputDecoration(
                      labelText: 'Phone',
                    ),
                  ),
                  const SizedBox(height: 11),

                  JamaicaParishDropdown(
                    controller: parishController,
                    label: 'Parish *',
                    enabled: !loading,
                    prefixIcon: Icons.map_outlined,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Material(
              color: FarmColors.card,
              borderRadius:
                  BorderRadius.circular(18),
              child: InkWell(
                borderRadius:
                    BorderRadius.circular(
                  18,
                ),
                onTap: loading
                    ? null
                    : () {
                        setState(() {
                          showOptionalDetails =
                              !showOptionalDetails;
                        });
                      },
                child: Container(
                  padding:
                      const EdgeInsets.all(
                    14,
                  ),
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(
                      18,
                    ),
                    border: Border.all(
                      color: FarmColors.line,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            Text(
                              'Add more details',
                              style: TextStyle(
                                color:
                                    FarmColors.ink,
                                fontSize: 11.5,
                                fontWeight:
                                    FontWeight
                                        .w900,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Optional • address, farm notes and payout information',
                              style: TextStyle(
                                color: FarmColors
                                    .mutedText,
                                fontSize: 9.2,
                                fontWeight:
                                    FontWeight
                                        .w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        showOptionalDetails
                            ? Icons
                                .expand_less_rounded
                            : Icons
                                .expand_more_rounded,
                        color:
                            FarmColors.mutedText,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            if (showOptionalDetails) ...[
              const SizedBox(height: 10),

              FarmCard(
                padding:
                    const EdgeInsets.all(
                  14,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Optional details',
                      style: TextStyle(
                        color:
                            FarmColors.ink,
                        fontSize: 13,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'You can also add or update these later from Farmer Account.',
                      style: TextStyle(
                        color: FarmColors
                            .mutedText,
                        fontSize: 9.3,
                        height: 1.3,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller:
                          addressController,
                      enabled: !loading,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Farm address',
                      ),
                    ),
                    const SizedBox(height: 11),

                    TextField(
                      controller:
                          bioController,
                      enabled: !loading,
                      maxLines: 3,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Farm notes',
                        hintText:
                            'Optional information about your farm',
                      ),
                    ),
                    const SizedBox(height: 11),

                    TextField(
                      controller:
                          payoutMethodController,
                      enabled: !loading,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Payout method',
                        hintText:
                            'e.g. Bank transfer',
                      ),
                    ),
                    const SizedBox(height: 11),

                    TextField(
                      controller:
                          payoutDetailsController,
                      enabled: !loading,
                      maxLines: 2,
                      decoration:
                          const InputDecoration(
                        labelText:
                            'Payout details',
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: PrimaryFarmButton(
                label: loading
                    ? 'Submitting...'
                    : 'Submit Farmer Application',
                onPressed:
                    loading ? null : submit,
              ),
            ),

            const SizedBox(height: 9),

            const Text(
              'HPJ reviews farmer applications before marketplace access is activated.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color:
                    FarmColors.mutedText,
                fontSize: 8.9,
                height: 1.3,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FarmerMarketplaceShell extends StatefulWidget {
  final FarmerProfile profile;
  final int initialIndex;
  final String? initialRecordId;

  const FarmerMarketplaceShell({
    super.key,
    required this.profile,
    this.initialIndex = 0,
    this.initialRecordId,
  });

  @override
  State<FarmerMarketplaceShell> createState() => _FarmerMarketplaceShellState();
}

class _FarmerMarketplaceShellState extends State<FarmerMarketplaceShell>
    with WidgetsBindingObserver {
  int selectedIndex = 0;
  int refreshKey = 0;
  late FarmerProfile currentProfile;
  StreamSubscription<AuthState>? _authBoundarySubscription;
  String? _authBoundaryUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    selectedIndex = widget.initialIndex.clamp(0, 4).toInt();
    currentProfile = widget.profile;
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
            builder: (_) => nextUserId == null
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
        workspace: 'farmer',
        tab: selectedIndex,
      ),
    );
  }

  Future<void> _reloadProfile() async {
    final operationBoundary =
        captureHpjPrivateOperationBoundary();

    final latest = await fetchCurrentFarmerProfile();

    if (!mounted ||
        latest == null ||
        !isHpjPrivateOperationBoundaryCurrent(operationBoundary)) {
      return;
    }

    setState(() {
      currentProfile = latest;
      refreshKey++;
    });
  }

  Future<void> _revalidateFarmerWorkspace() async {
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

      final latest = access.farmerProfile;
      final active = latest != null &&
          latest.isApproved &&
          access.programSettings.farmerWorkspaceEnabled;

      if (!active) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute<void>(
              builder: (_) => const FarmerAccessGate(
                initialTab: 0,
              ),
            ),
            (route) => false,
          );
        });
        return;
      }

      setState(() {
        currentProfile = latest;
        refreshKey++;
      });
    } catch (error) {
      farmDebugLog(
        'Farmer workspace resume validation skipped: $error',
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    unawaited(_revalidateFarmerWorkspace());
  }

  @override
  void dispose() {
    _authBoundarySubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  static const _pageTitles = <String>[
    'Farmer Home',
    'My Supply',
    'Orders',
    'My Payments',
    'Account',
  ];

  void refresh() => setState(() => refreshKey++);

  void _selectFarmerTab(int index) {
    if (!mounted) return;
    final safeIndex = index.clamp(0, 4).toInt();
    setState(() => selectedIndex = safeIndex);
    unawaited(
      saveHpjNavigationPreference(
        workspace: 'farmer',
        tab: safeIndex,
      ),
    );
  }

  void _switchWorkspace() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const OwnerWorkspaceSwitcherScreen(
          currentWorkspace: 'farmer',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = currentProfile;
    final pages = [
      FarmerDashboardScreen(
        profile: profile,
        refreshKey: refreshKey,
        onOpenSupply: () => _selectFarmerTab(1),
        onOpenOrders: () => _selectFarmerTab(2),
        onOpenPayments: () => _selectFarmerTab(3),
        onOpenAccount: () => _selectFarmerTab(4),
        onRefreshFeed: refresh,
        onOpenDemand: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => FarmerDemandBoardScreen(profile: profile),
            ),
          );
        },
        onOpenCollections: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => FarmerCollectionScheduleScreen(profile: profile),
            ),
          );
        },
      ),
      FarmerSupplyScreen(
        profile: profile,
        refreshKey: refreshKey,
        initialSupplyId: selectedIndex == 1
            ? widget.initialRecordId
            : null,
      ),
      FarmerOrdersScreen(
        profile: profile,
        refreshKey: refreshKey,
      ),
      FarmerEarningsScreen(
        profile: profile,
        refreshKey: refreshKey,
        initialPayoutId: selectedIndex == 3
            ? widget.initialRecordId
            : null,
      ),
      FarmerAccountScreen(
        profile: profile,
        onProfileChanged: _reloadProfile,
      ),
    ];
    final destinations = <FarmBottomOption>[
      const FarmBottomOption(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home_rounded),
        label: 'Home',
      ),
      const FarmBottomOption(
        icon: Icon(Icons.agriculture_outlined),
        selectedIcon: Icon(Icons.agriculture),
        label: 'Supply',
      ),
      const FarmBottomOption(
        icon: Icon(Icons.receipt_long_outlined),
        selectedIcon: Icon(Icons.receipt_long),
        label: 'Orders',
      ),
      const FarmBottomOption(
        icon: Icon(Icons.payments_outlined),
        selectedIcon: Icon(Icons.payments),
        label: 'Payments',
      ),
      const FarmBottomOption(
        icon: Icon(Icons.person_outline),
        selectedIcon: Icon(Icons.person),
        label: 'Account',
      ),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || !mounted) return;

        if (selectedIndex != 0) {
          _selectFarmerTab(0);
        }
        // On Feed, Back intentionally does nothing. Switching workspaces is
        // available only through the Switch Workspace button in the app bar.
      },
      child: Scaffold(
        backgroundColor: FarmColors.background,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(_pageTitles[selectedIndex]),
          actions: [
            const HpjInboxActionButton(),
            IconButton(
              tooltip: 'Switch Workspace',
              onPressed: _switchWorkspace,
              icon: const Icon(Icons.apps_rounded),
            ),
          ],
        ),
        body: pages[selectedIndex],
        bottomNavigationBar: FarmBottomOptionsBar(
          selectedIndex: selectedIndex,
          destinations: destinations,
          onSelected: _selectFarmerTab,
        ),
      ),
    );
  }
}

DateTime _farmerSupplyFreshnessDate(
  FarmerSupplyForecast supply,
) {
  return supply.updatedAt ??
      supply.createdAt ??
      DateTime.now();
}

int _farmerSupplyAgeDays(
  FarmerSupplyForecast supply,
) {
  final now = DateTime.now();
  final age = now.difference(
    _farmerSupplyFreshnessDate(supply),
  ).inDays;

  return age < 0 ? 0 : age;
}

bool _farmerSupplyNeedsReview(
  FarmerSupplyForecast supply,
) {
  if (!supply.isActive) return false;

  final ageDays = _farmerSupplyAgeDays(supply);

  final harvestDate = supply.expectedHarvestDate;
  final now = DateTime.now();
  final today = DateTime(
    now.year,
    now.month,
    now.day,
  );

  final daysToHarvest = harvestDate == null
      ? null
      : DateTime(
          harvestDate.year,
          harvestDate.month,
          harvestDate.day,
        ).difference(today).inDays;

  final nearHarvest =
      daysToHarvest != null &&
      daysToHarvest <= 7 &&
      !supply.isHarvested;

  return ageDays >= 14 || nearHarvest;
}

String _farmerSupplyFreshnessLabel(
  FarmerSupplyForecast supply,
) {
  final age = _farmerSupplyAgeDays(supply);

  if (age <= 0) return 'Checked today';
  if (age == 1) return 'Checked yesterday';
  return 'Checked $age days ago';
}

class _FarmerTodaySnapshot {
  final List<FarmerSupplyForecast> supplies;
  final List<FarmerMarketDemandOpportunity> demand;
  final List<FarmerCollectionScheduleItem> collections;
  final List<FarmerPayout> payouts;
  final UserExperiencePreferences preferences;

  const _FarmerTodaySnapshot({
    required this.supplies,
    required this.demand,
    required this.collections,
    required this.payouts,
    this.preferences = UserExperiencePreferences.defaults,
  });
}

Future<_FarmerTodaySnapshot> fetchFarmerTodaySnapshot(
  FarmerProfile profile,
) async {
  var supplies = <FarmerSupplyForecast>[];
  var demand = <FarmerMarketDemandOpportunity>[];
  var collections = <FarmerCollectionScheduleItem>[];
  var payouts = <FarmerPayout>[];
  var preferences = UserExperiencePreferences.defaults;

  try {
    supplies = await fetchFarmerSupplyForecasts(profile.id);
  } catch (error) {
    farmDebugLog('Farmer Today — supply unavailable: $error');
  }

  try {
    demand = await fetchFarmerMarketDemandBoard(30);
  } catch (error) {
    farmDebugLog('Farmer Today — demand unavailable: $error');
  }

  try {
    collections = await fetchFarmerCollectionSchedule();
  } catch (error) {
    farmDebugLog('Farmer Today — collections unavailable: $error');
  }

  try {
    payouts = await fetchFarmerPayouts(farmerId: profile.id);
  } catch (error) {
    farmDebugLog('Farmer Today — payouts unavailable: $error');
  }

  try {
    preferences = await fetchCurrentUserExperiencePreferences();
  } catch (error) {
    farmDebugLog('Farmer Today — preferences unavailable: $error');
  }

  return _FarmerTodaySnapshot(
    supplies: supplies,
    demand: demand,
    collections: collections,
    payouts: payouts,
    preferences: preferences,
  );
}

class FarmerDashboardScreen extends StatelessWidget {
  final FarmerProfile profile;
  final int refreshKey;
  final VoidCallback onOpenSupply;
  final VoidCallback onOpenOrders;
  final VoidCallback onOpenPayments;
  final VoidCallback onOpenAccount;
  final VoidCallback onRefreshFeed;
  final VoidCallback onOpenDemand;
  final VoidCallback onOpenCollections;

  const FarmerDashboardScreen({
    super.key,
    required this.profile,
    required this.refreshKey,
    required this.onOpenSupply,
    required this.onOpenOrders,
    required this.onOpenPayments,
    required this.onOpenAccount,
    required this.onRefreshFeed,
    required this.onOpenDemand,
    required this.onOpenCollections,
  });

  String get _firstName {
    final value = profile.farmerName.trim();
    if (value.isEmpty) return 'Farmer';
    return value.split(RegExp(r'\s+')).first;
  }

  Future<void> _handleAgricultureFeedAction(
    BuildContext context,
    AgricultureFeedUpdate update,
  ) async {
    switch (update.actionType) {
      case 'farmer_demand':
        onOpenDemand();
        return;
      case 'farmer_supply':
        onOpenSupply();
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

  @override
  Widget build(BuildContext context) {
    return FarmPage(
      child: FutureBuilder<_FarmerTodaySnapshot>(
        key: ValueKey('farmer-feed-$refreshKey'),
        future: fetchFarmerTodaySnapshot(profile),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              snapshot.data == null) {
            return const SizedBox.expand(
              child: SkeletonList(count: 3),
            );
          }

          final data = snapshot.data ??
              const _FarmerTodaySnapshot(
                supplies: <FarmerSupplyForecast>[],
                demand: <FarmerMarketDemandOpportunity>[],
                collections: <FarmerCollectionScheduleItem>[],
                payouts: <FarmerPayout>[],
              );

          final preferences = data.preferences;

          final activeSupply = data.supplies
              .where((item) => item.isActive)
              .toList();

          final supplyNeedingReview = activeSupply
              .where(_farmerSupplyNeedsReview)
              .toList();

          final activeCropNames = activeSupply
              .map((item) => hpjSmartNormalizeSearch(item.cropName))
              .where((name) => name.isNotEmpty)
              .toSet();

          bool matchesMySupply(FarmerMarketDemandOpportunity item) {
            final demandName = hpjSmartNormalizeSearch(item.productName);
            return activeCropNames.any(
              (crop) => crop == demandName ||
                  crop.contains(demandName) ||
                  demandName.contains(crop),
            );
          }

          int demandPriority(FarmerMarketDemandOpportunity item) {
            var score = (item.opportunityGap * 10).round();
            if (matchesMySupply(item)) score += 100000;
            if (item.demandSignal == 'urgent') score += 50000;
            if (item.demandSignal == 'committed_need') score += 40000;
            final needBy = item.nextNeedBy;
            if (needBy != null) {
              final days = needBy.difference(DateTime.now()).inDays;
              if (days <= 3) score += 15000;
              else if (days <= 7) score += 8000;
            }
            return score;
          }

          final opportunities = data.demand
              .where(
                (item) =>
                    item.opportunityGap > 0.0001 &&
                    item.demandSignal != 'covered_by_you',
              )
              .toList()
            ..sort(
              (a, b) => demandPriority(b).compareTo(demandPriority(a)),
            );

          final topOpportunity =
              opportunities.isEmpty ? null : opportunities.first;

          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);

          final upcomingCollections = data.collections
              .where(
                (item) =>
                    !item.collectionDate.isBefore(today) &&
                    item.stopStatus != 'cancelled' &&
                    item.stopStatus != 'completed',
              )
              .toList()
            ..sort(
              (a, b) => a.collectionDate.compareTo(b.collectionDate),
            );

          final nextCollection =
              upcomingCollections.isEmpty ? null : upcomingCollections.first;

          final pendingPayout = data.payouts
              .where((item) => item.payoutStatus == 'pending')
              .fold<double>(0, (sum, item) => sum + item.netAmount);

          final heldPayout = data.payouts
              .where((item) => item.payoutStatus == 'held')
              .fold<double>(0, (sum, item) => sum + item.netAmount);

          final contactReady =
              profile.phone.trim().isNotEmpty && profile.parish.trim().isNotEmpty;

          final payoutReady =
              profile.payoutMethod.trim().isNotEmpty &&
              profile.payoutDetails.trim().isNotEmpty;

          final supplyReady = activeSupply.isNotEmpty;

          // First-rollout activation should create farmer value before asking
          // for secondary administrative details such as payout setup.
          final activationComplete = contactReady && supplyReady;

          final setupAction = !contactReady
              ? onOpenAccount
              : !supplyReady
                  ? onOpenSupply
                  : onOpenAccount;

          final farmerNotifications = <_FarmerTodayNotification>[
            if (supplyNeedingReview.isNotEmpty)
              _FarmerTodayNotification(
                title:
                    '${supplyNeedingReview.length} supply report${supplyNeedingReview.length == 1 ? '' : 's'} need a quick check',
                message: 'Confirm what is still accurate or update what changed.',
                icon: Icons.agriculture_outlined,
                actionLabel: 'Review supply',
                onTap: onOpenSupply,
              ),
            if (heldPayout > 0)
              _FarmerTodayNotification(
                title: 'Payment needs review',
                message: '${formatJmd(heldPayout)} is currently held.',
                icon: Icons.account_balance_wallet_outlined,
                actionLabel: 'View payments',
                onTap: onOpenPayments,
              ),
            if (topOpportunity != null)
              _FarmerTodayNotification(
                title: '${topOpportunity.productName} buyer demand',
                message:
                    '${_farmerPartnerNumber(topOpportunity.opportunityGap)} ${topOpportunity.unit} currently needed.',
                icon: Icons.storefront_outlined,
                actionLabel: 'View demand',
                onTap: onOpenDemand,
              ),
            if (nextCollection != null)
              _FarmerTodayNotification(
                title: 'Upcoming collection',
                message:
                    '${nextCollection.productName} • ${_farmerPartnerDate(nextCollection.collectionDate)}',
                icon: Icons.local_shipping_outlined,
                actionLabel: 'View collection',
                onTap: onOpenCollections,
              ),
          ];

          final hasPaymentUpdate = pendingPayout > 0 || heldPayout > 0;
          final feedUpdateCount =
              (preferences.farmerShowBuyingRequests ? opportunities.length : 0) +
              (supplyNeedingReview.isNotEmpty ? 1 : 0) +
              (nextCollection != null ? 1 : 0) +
              (hasPaymentUpdate ? 1 : 0);

          final thirtyDaysAgo = now.subtract(const Duration(days: 30));
          final ninetyDaysAgo = now.subtract(const Duration(days: 90));

          bool payoutSince(FarmerPayout payout, DateTime cutoff) {
            final created = payout.createdAt;
            return created != null && !created.isBefore(cutoff);
          }

          final sales30 = data.payouts
              .where((item) => payoutSince(item, thirtyDaysAgo))
              .fold<double>(0, (sum, item) => sum + item.grossAmount);
          final sales90 = data.payouts
              .where((item) => payoutSince(item, ninetyDaysAgo))
              .fold<double>(0, (sum, item) => sum + item.grossAmount);
          final supplyTransactions30 = data.payouts
              .where((item) => payoutSince(item, thirtyDaysAgo))
              .length;
          final demandForMyCrops = opportunities
              .where(matchesMySupply)
              .toList(growable: false);
          final confirmedCropCount = activeSupply
              .where(
                (item) => item.isHpjConfirmed ||
                    (item.hpjConfirmedQuantity ?? 0) > 0,
              )
              .map((item) => hpjSmartNormalizeSearch(item.cropName))
              .where((name) => name.isNotEmpty)
              .toSet()
              .length;

          var feedFilter = 'For You';

          return StatefulBuilder(
            builder: (context, setFeedState) {
              bool categoryEnabled(String category) {
                switch (category) {
                  case 'Demand':
                    return preferences.farmerShowBuyingRequests;
                  case 'Market':
                    return preferences.farmerShowMarketUpdates;
                  case 'News':
                    return preferences.farmerShowAgricultureNews ||
                        preferences.farmerShowTrainingOpportunities;
                  default:
                    return true;
                }
              }

              bool showFeed(String category) {
                if (!categoryEnabled(category)) return false;
                return feedFilter == 'For You' || feedFilter == category;
              }

              final demandLimit = feedFilter == 'Demand' ? 5 : 2;
              final newsLimit = feedFilter == 'News' ? 6 : 1;

              return RefreshIndicator(
                onRefresh: () async {
                  onRefreshFeed();
                  await Future<void>.delayed(Duration.zero);
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
                  children: [
                    _FarmerSocialFeedFilters(
                      selected: feedFilter,
                      showDemand: preferences.farmerShowBuyingRequests,
                      showMarket: preferences.farmerShowMarketUpdates,
                      showNews: preferences.farmerShowAgricultureNews ||
                          preferences.farmerShowTrainingOpportunities,
                      onSelected: (value) {
                        setFeedState(() => feedFilter = value);
                      },
                    ),
                    const SizedBox(height: 14),

                    if (feedFilter == 'For You') ...[
                      _FarmerBusinessSnapshotCard(
                        farmName: profile.farmName,
                        sales30: sales30,
                        sales90: sales90,
                        supplyTransactions30: supplyTransactions30,
                        confirmedCropCount: confirmedCropCount,
                        opportunityCount: demandForMyCrops.length,
                        upcomingCollections: upcomingCollections.length,
                        topOpportunity: demandForMyCrops.isEmpty
                            ? null
                            : demandForMyCrops.first,
                        onOpenDemand: onOpenDemand,
                        onOpenSupply: onOpenSupply,
                        onOpenPayments: onOpenPayments,
                      ),
                      if (!activationComplete) ...[
                        const SizedBox(height: 12),
                        _FarmerSetupNudge(
                          contactReady: contactReady,
                          payoutReady: payoutReady,
                          supplyReady: supplyReady,
                          onTap: setupAction,
                        ),
                      ],
                      const SizedBox(height: 16),
                    ],

                    if (showFeed('Market')) ...[
                      HpjJamaicaMarketPulseSection(
                        audience: 'farmer',
                        refreshKey: refreshKey,
                        limit: 8,
                        socialStyle: true,
                        preferredCropNames: activeSupply
                            .map((item) => item.cropName)
                            .toList(growable: false),
                        onPrimaryAction: (insight) async {
                          if (insight.hasShortage) {
                            onOpenDemand();
                          } else {
                            onOpenSupply();
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                    ],

                    if (feedFilter == 'For You' &&
                        preferences.showFreshReels) ...[
                      FreshReelFeedPreviewCard(
                        preferences: preferences,
                        audience: 'farmer',
                        placement: freshReelPlacementFarmerFeed,
                        refreshKey: refreshKey,
                      ),
                      const SizedBox(height: 12),
                    ],

                    if (showFeed('News')) ...[
                      HpjAgricultureUpdatesSection(
                        audience: 'farmer',
                        workspace: 'farmer',
                        limit: newsLimit,
                        refreshKey: refreshKey,
                        socialStyle: true,
                        showImages: preferences.showFeedImages,
                        showEducation:
                            preferences.farmerShowTrainingOpportunities,
                        onlyEducation:
                            !preferences.farmerShowAgricultureNews &&
                                preferences.farmerShowTrainingOpportunities,
                        title: 'Agriculture intelligence',
                        subtitle:
                            'Market news, official notices and opportunities relevant to farmers.',
                        onAction: (update) =>
                            _handleAgricultureFeedAction(context, update),
                      ),
                    ],

                    if (showFeed('Alerts') && supplyNeedingReview.isNotEmpty) ...[
                      _FarmerFeedActionCard(
                        eyebrow: 'SUPPLY CHECK',
                        productName: supplyNeedingReview.first.cropName,
                        title: 'Keep your supply current',
                        message:
                            '${supplyNeedingReview.length} crop report${supplyNeedingReview.length == 1 ? '' : 's'} need a quick check so HPJ can match you accurately.',
                        actionLabel: 'Review supply',
                        icon: Icons.agriculture_rounded,
                        onTap: onOpenSupply,
                      ),
                      const SizedBox(height: 12),
                    ],

                    if (showFeed('Demand'))
                      ...opportunities.take(demandLimit).map(
                            (opportunity) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _FarmerOpportunityCard(
                                opportunity: opportunity,
                                matchesMySupply: matchesMySupply(opportunity),
                                onTap: onOpenDemand,
                                onSupplied: onRefreshFeed,
                              ),
                            ),
                          ),

                    if (showFeed('Alerts') && nextCollection != null) ...[
                      _FarmerFeedActionCard(
                        eyebrow: 'COLLECTION',
                        productName: nextCollection.productName,
                        title: 'Collection coming up',
                        message:
                            '${nextCollection.productName} • ${_farmerPartnerNumber(nextCollection.plannedQuantity)} ${nextCollection.unit} • ${_farmerPartnerDate(nextCollection.collectionDate)}',
                        actionLabel: 'View collection',
                        icon: Icons.local_shipping_rounded,
                        onTap: onOpenCollections,
                      ),
                      const SizedBox(height: 12),
                    ],

                    if (showFeed('Alerts') && hasPaymentUpdate) ...[
                      _FarmerFeedActionCard(
                        eyebrow: heldPayout > 0 ? 'PAYMENT REVIEW' : 'PAYMENT',
                        title: heldPayout > 0
                            ? '${formatJmd(heldPayout)} needs review'
                            : '${formatJmd(pendingPayout)} on the way',
                        message: heldPayout > 0
                            ? 'Open Payments to see what needs attention.'
                            : 'Your pending HPJ settlement is visible in Payments.',
                        actionLabel: 'View payments',
                        icon: Icons.payments_rounded,
                        onTap: onOpenPayments,
                      ),
                      const SizedBox(height: 12),
                    ],

                    if (feedFilter == 'Demand' && opportunities.length > demandLimit)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: onOpenDemand,
                          icon: const Icon(Icons.arrow_forward_rounded, size: 17),
                          label: Text('See all ${opportunities.length} buyer needs'),
                        ),
                      ),

                    if (feedUpdateCount == 0 && activationComplete)
                      const _FarmerAllClearCard(),
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

class _FarmerBusinessSnapshotCard extends StatelessWidget {
  final String farmName;
  final double sales30;
  final double sales90;
  final int supplyTransactions30;
  final int confirmedCropCount;
  final int opportunityCount;
  final int upcomingCollections;
  final FarmerMarketDemandOpportunity? topOpportunity;
  final VoidCallback onOpenDemand;
  final VoidCallback onOpenSupply;
  final VoidCallback onOpenPayments;

  const _FarmerBusinessSnapshotCard({
    required this.farmName,
    required this.sales30,
    required this.sales90,
    required this.supplyTransactions30,
    required this.confirmedCropCount,
    required this.opportunityCount,
    required this.upcomingCollections,
    required this.topOpportunity,
    required this.onOpenDemand,
    required this.onOpenSupply,
    required this.onOpenPayments,
  });

  String _qty(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final opportunity = topOpportunity;

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
                decoration: const BoxDecoration(
                  color: FarmColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.query_stats_rounded,
                  color: FarmColors.primary,
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      farmName.trim().isEmpty ? 'My farm business' : farmName.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: FarmColors.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Private HPJ activity • last 30 days',
                      style: TextStyle(
                        color: FarmColors.mutedText,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.lock_outline_rounded,
                  size: 16, color: FarmColors.mutedText),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _FarmerBusinessMetric(
                  label: 'Sales to HPJ',
                  value: formatJmd(sales30),
                  note: '$supplyTransactions30 transaction${supplyTransactions30 == 1 ? '' : 's'}',
                  onTap: onOpenPayments,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _FarmerBusinessMetric(
                  label: 'Demand gaps',
                  value: '$opportunityCount',
                  note: opportunityCount == 0 ? 'No open gap' : 'For your crops',
                  onTap: onOpenDemand,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _FarmerBusinessMetric(
                  label: 'Confirmed crops',
                  value: '$confirmedCropCount',
                  note: 'Ready for matching',
                  onTap: onOpenSupply,
                ),
              ),
            ],
          ),
          if (opportunity != null) ...[
            const SizedBox(height: 13),
            const Divider(height: 1),
            const SizedBox(height: 11),
            Row(
              children: [
                Expanded(
                  child: Text(
                    opportunity.productName,
                    style: const TextStyle(
                      color: FarmColors.ink,
                      fontWeight: FontWeight.w900,
                      fontSize: 13.5,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onOpenDemand,
                  child: const Text('View demand'),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: _FarmerDecisionMetric(
                    label: 'Demand',
                    value: '${_qty(opportunity.visibleDemand)} ${opportunity.unit}',
                  ),
                ),
                Expanded(
                  child: _FarmerDecisionMetric(
                    label: 'My confirmed',
                    value: '${_qty(opportunity.myHpjConfirmedSupply)} ${opportunity.unit}',
                  ),
                ),
                Expanded(
                  child: _FarmerDecisionMetric(
                    label: 'Opportunity',
                    value: '${_qty(opportunity.opportunityGap)} ${opportunity.unit}',
                    emphasize: true,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 11),
          Text(
            '90-day sales ${formatJmd(sales90)} • $upcomingCollections upcoming collection${upcomingCollections == 1 ? '' : 's'}',
            style: const TextStyle(
              color: FarmColors.mutedText,
              fontSize: 10.5,
              height: 1.3,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Demand is planning guidance, not a guaranteed HPJ purchase.',
            style: TextStyle(
              color: FarmColors.mutedText,
              fontSize: 9.5,
              height: 1.25,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FarmerBusinessMetric extends StatelessWidget {
  final String label;
  final String value;
  final String note;
  final VoidCallback onTap;

  const _FarmerBusinessMetric({
    required this.label,
    required this.value,
    required this.note,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
              style: const TextStyle(
                color: FarmColors.primary,
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

class _FarmerDecisionMetric extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasize;

  const _FarmerDecisionMetric({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: FarmColors.mutedText,
              fontSize: 9.3,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: emphasize ? FarmColors.success : FarmColors.ink,
              fontSize: 11.2,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _FarmerSocialFeedFilters extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;
  final bool showDemand;
  final bool showMarket;
  final bool showNews;

  const _FarmerSocialFeedFilters({
    required this.selected,
    required this.onSelected,
    this.showDemand = true,
    this.showMarket = true,
    this.showNews = true,
  });

  @override
  Widget build(BuildContext context) {
    final filters = <(String, IconData)>[
      ('For You', Icons.home_rounded),
      if (showDemand) ('Demand', Icons.storefront_outlined),
      if (showMarket) ('Market', Icons.query_stats_rounded),
      if (showNews) ('News', Icons.newspaper_rounded),
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

class _FarmerTodayNotification {
  final String title;
  final String message;
  final IconData icon;
  final String actionLabel;
  final VoidCallback onTap;

  const _FarmerTodayNotification({
    required this.title,
    required this.message,
    required this.icon,
    required this.actionLabel,
    required this.onTap,
  });
}

Future<void> _showFarmerNotifications(
  BuildContext context,
  List<_FarmerTodayNotification>
      notifications,
) async {
  await showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) =>
        _FarmerNotificationsSheet(
      notifications: notifications,
    ),
  );
}

class _FarmerNotificationsSheet
    extends StatelessWidget {
  final List<_FarmerTodayNotification>
      notifications;

  const _FarmerNotificationsSheet({
    required this.notifications,
  });

  void _openNotification(
    BuildContext context,
    _FarmerTodayNotification notification,
  ) {
    Navigator.of(context).pop();

    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        notification.onTap();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight =
        MediaQuery.of(context).size.height *
            0.74;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: maxHeight,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: FarmColors.card,
            borderRadius:
                BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(
                  18,
                  12,
                  18,
                  10,
                ),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration:
                          BoxDecoration(
                        color: FarmColors.line,
                        borderRadius:
                            BorderRadius.circular(
                          99,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Text(
                                'Notifications',
                                style: TextStyle(
                                  color:
                                      FarmColors.ink,
                                  fontSize: 18,
                                  fontWeight:
                                      FontWeight
                                          .w900,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Only updates that are useful to act on.',
                                style: TextStyle(
                                  color: FarmColors
                                      .mutedText,
                                  fontSize: 9.6,
                                  fontWeight:
                                      FontWeight
                                          .w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close',
                          onPressed: () =>
                              Navigator.of(
                                context,
                              ).pop(),
                          icon: const Icon(
                            Icons.close_rounded,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              Flexible(
                child: notifications.isEmpty
                    ? const Padding(
                        padding:
                            EdgeInsets.all(
                          24,
                        ),
                        child: Column(
                          mainAxisSize:
                              MainAxisSize.min,
                          children: [
                            Icon(
                              Icons
                                  .notifications_none_rounded,
                              color: FarmColors
                                  .mutedText,
                              size: 30,
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            Text(
                              'You are all caught up.',
                              style:
                                  TextStyle(
                                color:
                                    FarmColors.ink,
                                fontSize: 13,
                                fontWeight:
                                    FontWeight
                                        .w900,
                              ),
                            ),
                            SizedBox(
                              height: 4,
                            ),
                            Text(
                              'Buyer demand, collection, supply review, and payment updates will appear here.',
                              textAlign:
                                  TextAlign
                                      .center,
                              style:
                                  TextStyle(
                                color: FarmColors
                                    .mutedText,
                                fontSize: 9.6,
                                height: 1.35,
                                fontWeight:
                                    FontWeight
                                        .w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        padding:
                            const EdgeInsets
                                .fromLTRB(
                          12,
                          10,
                          12,
                          18,
                        ),
                        itemCount:
                            notifications
                                .length,
                        separatorBuilder:
                            (_, __) =>
                                const Divider(
                          height: 1,
                        ),
                        itemBuilder:
                            (context, index) {
                          final item =
                              notifications[
                                  index];

                          return Material(
                            color: Colors
                                .transparent,
                            child: InkWell(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                14,
                              ),
                              onTap: () =>
                                  _openNotification(
                                context,
                                item,
                              ),
                              child: Padding(
                                padding:
                                    const EdgeInsets
                                        .symmetric(
                                  horizontal: 6,
                                  vertical: 12,
                                ),
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                  children: [
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration:
                                          BoxDecoration(
                                        color:
                                            FarmColors
                                                .primarySoft,
                                        borderRadius:
                                            BorderRadius
                                                .circular(
                                          12,
                                        ),
                                      ),
                                      child: Icon(
                                        item.icon,
                                        color:
                                            FarmColors
                                                .primary,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 10,
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment
                                                .start,
                                        children: [
                                          Text(
                                            item.title,
                                            style:
                                                const TextStyle(
                                              color:
                                                  FarmColors
                                                      .ink,
                                              fontSize:
                                                  11.2,
                                              fontWeight:
                                                  FontWeight
                                                      .w900,
                                            ),
                                          ),
                                          const SizedBox(
                                            height: 3,
                                          ),
                                          Text(
                                            item.message,
                                            style:
                                                const TextStyle(
                                              color:
                                                  FarmColors
                                                      .mutedText,
                                              fontSize:
                                                  9.5,
                                              height:
                                                  1.3,
                                              fontWeight:
                                                  FontWeight
                                                      .w600,
                                            ),
                                          ),
                                          const SizedBox(
                                            height: 5,
                                          ),
                                          Text(
                                            item.actionLabel,
                                            style:
                                                const TextStyle(
                                              color:
                                                  FarmColors
                                                      .primary,
                                              fontSize:
                                                  9.2,
                                              fontWeight:
                                                  FontWeight
                                                      .w900,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 6,
                                    ),
                                    const Padding(
                                      padding:
                                          EdgeInsets
                                              .only(
                                        top: 8,
                                      ),
                                      child: Icon(
                                        Icons
                                            .chevron_right_rounded,
                                        color: FarmColors
                                            .mutedText,
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
        ),
      ),
    );
  }
}

class _FarmerWelcomePanel
    extends StatelessWidget {
  final String firstName;
  final String farmName;
  final String parish;
  final int notificationCount;
  final VoidCallback onNotificationsTap;
  final VoidCallback onUpdateSupply;

  const _FarmerWelcomePanel({
    required this.firstName,
    required this.farmName,
    required this.parish,
    required this.notificationCount,
    required this.onNotificationsTap,
    required this.onUpdateSupply,
  });

  @override
  Widget build(BuildContext context) {
    final details = <String>[
      if (farmName.trim().isNotEmpty)
        farmName.trim(),
      if (parish.trim().isNotEmpty)
        parish.trim(),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        17,
        17,
        17,
        16,
      ),
      decoration: BoxDecoration(
        color: FarmColors.card,
        borderRadius: BorderRadius.circular(
          22,
        ),
        border: Border.all(
          color: FarmColors.line,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Welcome back, $firstName',
                  style: const TextStyle(
                    color: FarmColors.ink,
                    fontSize: 22,
                    height: 1.05,
                    fontWeight:
                        FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _FarmerNotificationBell(
                count: notificationCount,
                onTap: onNotificationsTap,
              ),
            ],
          ),

          if (details.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              details.join(' • '),
              style: const TextStyle(
                color:
                    FarmColors.mutedText,
                fontSize: 11.6,
                height: 1.25,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
          ],

          const SizedBox(height: 8),

          const Text(
            'Fresh buyer demand, collections and payments appear in your feed.',
            style: TextStyle(
              color: FarmColors.mutedText,
              fontSize: 12.6,
              height: 1.42,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 13),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onUpdateSupply,
              child: const Text(
                'Update My Supply',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FarmerNotificationBell extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _FarmerNotificationBell({
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: fetchUnreadNotificationCount(),
      builder: (context, snapshot) {
        final unread = snapshot.data ?? count;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Material(
              color: FarmColors.background,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onTap,
                child: const SizedBox(
                  width: 42,
                  height: 42,
                  child: Icon(
                    Icons.notifications_none_rounded,
                    color: FarmColors.primary,
                    size: 22,
                  ),
                ),
              ),
            ),
            if (unread > 0)
              Positioned(
                right: -2,
                top: -3,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: FarmColors.danger,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                      color: FarmColors.card,
                      width: 2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    unread > 9 ? '9+' : '$unread',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _FarmerSetupNudge
    extends StatelessWidget {
  final bool contactReady;
  final bool payoutReady;
  final bool supplyReady;
  final VoidCallback onTap;

  const _FarmerSetupNudge({
    required this.contactReady,
    required this.payoutReady,
    required this.supplyReady,
    required this.onTap,
  });

  String get message {
    if (!contactReady) {
      return 'Add your phone and parish so HPJ can coordinate with you.';
    }

    if (!supplyReady) {
      return 'Tell HPJ one crop you expect to harvest so we can start looking for matching buyer demand.';
    }

    return 'Add payout details when you are ready to receive farmer payments.';
  }

  String get action {
    if (!contactReady) {
      return 'Finish setup';
    }

    if (!supplyReady) {
      return 'Add first crop';
    }

    return 'Payment setup';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F1E7),
        borderRadius: BorderRadius.circular(
          16,
        ),
        border: Border.all(
          color: const Color(0xFFE4DDCC),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Start here',
                  style: TextStyle(
                    color: FarmColors.ink,
                    fontSize: 11.5,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: const TextStyle(
                    color:
                        FarmColors.mutedText,
                    fontSize: 9.6,
                    height: 1.3,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: onTap,
            child: Text(action),
          ),
        ],
      ),
    );
  }
}

class _FarmerFeedStories extends StatelessWidget {
  final FarmerMarketDemandOpportunity? topOpportunity;
  final int demandCount;
  final FarmerCollectionScheduleItem? nextCollection;
  final double paymentAmount;
  final int supplyReviewCount;
  final VoidCallback onOpenDemand;
  final VoidCallback onOpenCollections;
  final VoidCallback onOpenPayments;
  final VoidCallback onOpenSupply;

  const _FarmerFeedStories({
    required this.topOpportunity,
    required this.demandCount,
    required this.nextCollection,
    required this.paymentAmount,
    required this.supplyReviewCount,
    required this.onOpenDemand,
    required this.onOpenCollections,
    required this.onOpenPayments,
    required this.onOpenSupply,
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
              _FarmerFeedStory(
                label: 'Demand',
                count: demandCount,
                productName: topOpportunity?.productName,
                icon: Icons.storefront_rounded,
                onTap: onOpenDemand,
              ),
              const SizedBox(width: 13),
              _FarmerFeedStory(
                label: 'Collection',
                count: nextCollection == null ? 0 : 1,
                productName: nextCollection?.productName,
                icon: Icons.local_shipping_rounded,
                onTap: onOpenCollections,
              ),
              const SizedBox(width: 13),
              _FarmerFeedStory(
                label: 'Payments',
                count: paymentAmount > 0 ? 1 : 0,
                icon: Icons.payments_rounded,
                onTap: onOpenPayments,
              ),
              const SizedBox(width: 13),
              _FarmerFeedStory(
                label: 'Supply',
                count: supplyReviewCount,
                icon: Icons.agriculture_rounded,
                onTap: onOpenSupply,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FarmerFeedStory extends StatelessWidget {
  final String label;
  final int count;
  final String? productName;
  final IconData icon;
  final VoidCallback onTap;

  const _FarmerFeedStory({
    required this.label,
    required this.count,
    this.productName,
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
                    child: productName != null && productName!.trim().isNotEmpty
                        ? HpjProductThumb(
                            productName: productName!,
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

class _FarmerDailyFeedHeader extends StatelessWidget {
  final int count;

  const _FarmerDailyFeedHeader({required this.count});

  @override
  Widget build(BuildContext context) {
    final today = _farmerPartnerDate(DateTime.now());

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
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
                  const Text(
                    "Today's feed",
                    style: TextStyle(
                      color: FarmColors.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                count == 0
                    ? '$today • You are caught up'
                    : '$today • $count useful update${count == 1 ? '' : 's'}',
                style: const TextStyle(
                  color: FarmColors.mutedText,
                  fontSize: 12.2,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Demand matching crops you already report is shown first. Pull down anytime to refresh.',
                style: TextStyle(
                  color: FarmColors.mutedText,
                  fontSize: 12,
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

class _FarmerOpportunityCard extends StatefulWidget {
  final FarmerMarketDemandOpportunity opportunity;
  final bool matchesMySupply;
  final VoidCallback onTap;
  final VoidCallback onSupplied;

  const _FarmerOpportunityCard({
    required this.opportunity,
    this.matchesMySupply = false,
    required this.onTap,
    required this.onSupplied,
  });

  @override
  State<_FarmerOpportunityCard> createState() => _FarmerOpportunityCardState();
}

class _FarmerOpportunityCardState extends State<_FarmerOpportunityCard> {
  bool seen = true;

  String get feedKey => hpjFarmerDemandFeedItemKey(widget.opportunity);

  @override
  void initState() {
    super.initState();
    _loadSeen();
  }

  @override
  void didUpdateWidget(covariant _FarmerOpportunityCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (hpjFarmerDemandFeedItemKey(oldWidget.opportunity) != feedKey) {
      _loadSeen();
    }
  }

  Future<void> _loadSeen() async {
    final value = await isHpjFeedItemSeen(
      workspace: 'farmer',
      itemKey: feedKey,
    );
    if (mounted) setState(() => seen = value);
  }

  Future<void> _markSeen() async {
    if (!seen && mounted) setState(() => seen = true);
    await markHpjFeedItemSeen(
      workspace: 'farmer',
      itemKey: feedKey,
    );
  }

  Future<void> _openDetails() async {
    await _markSeen();
    if (!mounted) return;
    widget.onTap();
  }

  Future<void> _supply() async {
    await _markSeen();
    if (!mounted) return;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FarmerDemandSupplySheet(
        demand: widget.opportunity,
      ),
    );

    if (!mounted || saved != true) return;
    widget.onSupplied();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${widget.opportunity.productName} supply reported. HPJ can now review the match.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final opportunity = widget.opportunity;
    final needDate = opportunity.nextNeedBy == null
        ? null
        : _farmerPartnerDate(opportunity.nextNeedBy!);

    return FarmCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'LIVE BUYER DEMAND',
                  style: TextStyle(
                    color: FarmColors.primary,
                    fontSize: 10.5,
                    letterSpacing: .55,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (!seen) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: FarmColors.danger,
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: const Text(
                    'NEW',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9.1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: FarmColors.primarySoft,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  widget.matchesMySupply ? 'MATCHES YOUR SUPPLY' : 'ACTIVE',
                  style: const TextStyle(
                    color: FarmColors.primary,
                    fontSize: 9.3,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              HpjProductThumb(
                productName: opportunity.productName,
                size: 92,
                radius: 17,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      opportunity.productName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: FarmColors.ink,
                        fontSize: 19,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      '${_farmerPartnerNumber(opportunity.opportunityGap)} ${opportunity.unit} needed',
                      style: const TextStyle(
                        color: FarmColors.ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (needDate != null) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 14,
                            color: FarmColors.mutedText,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              'Needed by $needDate',
                              style: const TextStyle(
                                color: FarmColors.mutedText,
                                fontSize: 11.8,
                                fontWeight: FontWeight.w700,
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
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: opportunity.opportunityGap > 0.0001 ? _supply : null,
              icon: const Icon(Icons.agriculture_rounded, size: 18),
              label: const Text('I Can Supply This'),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: HpjWatchButton(
                  workspace: 'farmer',
                  watchType: 'farmer_demand',
                  entityKey: hpjFarmerDemandWatchKey(
                    opportunity.productName,
                    opportunity.unit,
                  ),
                  entityName: '${opportunity.productName} buyer demand',
                  compact: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _openDetails,
                  icon: const Icon(Icons.storefront_outlined, size: 17),
                  label: const Text('View Demand'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FarmerFeedActionCard extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String message;
  final String actionLabel;
  final IconData icon;
  final String? productName;
  final VoidCallback onTap;

  const _FarmerFeedActionCard({
    required this.eyebrow,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.icon,
    this.productName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FarmCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          productName != null && productName!.trim().isNotEmpty
              ? HpjProductThumb(
                  productName: productName!,
                  size: 72,
                  radius: 15,
                )
              : Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: FarmColors.primarySoft,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: FarmColors.primary, size: 27),
                ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow,
                  style: const TextStyle(
                    color: FarmColors.primary,
                    fontSize: 10.2,
                    letterSpacing: .45,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    color: FarmColors.ink,
                    fontSize: 15.5,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    color: FarmColors.mutedText,
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                TextButton.icon(
                  onPressed: onTap,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: Icon(icon, size: 16),
                  label: Text(actionLabel),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FarmerAllClearCard
    extends StatelessWidget {
  const _FarmerAllClearCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4EC),
        borderRadius: BorderRadius.circular(
          17,
        ),
        border: Border.all(
          color: const Color(0xFFDCE4D8),
        ),
      ),
      child: const Text(
        'You are up to date. New buyer opportunities and collection updates will appear here when there is something useful to act on.',
        style: TextStyle(
          color: Color(0xFF5F6D65),
          fontSize: 11.5,
          height: 1.4,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _FarmerActivationCard
    extends StatelessWidget {
  final bool contactReady;
  final bool payoutReady;
  final bool supplyReady;
  final VoidCallback onOpenAccount;
  final VoidCallback onOpenSupply;

  const _FarmerActivationCard({
    required this.contactReady,
    required this.payoutReady,
    required this.supplyReady,
    required this.onOpenAccount,
    required this.onOpenSupply,
  });

  int get completed {
    return 1 +
        (contactReady ? 1 : 0) +
        (payoutReady ? 1 : 0) +
        (supplyReady ? 1 : 0);
  }

  @override
  Widget build(BuildContext context) {
    final progress = completed / 4;

    final nextTitle = !contactReady
        ? 'Complete contact details'
        : !payoutReady
            ? 'Add payout details'
            : 'Report your first crop';

    final nextMessage = !contactReady
        ? 'HPJ needs a reliable phone and parish for matching and collection planning.'
        : !payoutReady
            ? 'Add how you want HPJ to pay you so your account is ready before the first settlement.'
            : 'Tell HPJ what you are growing so buyer demand can be compared with your expected harvest.';

    final nextAction =
        (!contactReady || !payoutReady)
            ? onOpenAccount
            : onOpenSupply;

    return FarmCard(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Get ready to earn with HPJ',
                  style: TextStyle(
                    color: FarmColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                '$completed/4',
                style: const TextStyle(
                  color: FarmColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: FarmColors.line,
              color: FarmColors.primary,
            ),
          ),
          const SizedBox(height: 12),

          const _ActivationStepRow(
            complete: true,
            label: 'Farmer account approved',
          ),
          _ActivationStepRow(
            complete: contactReady,
            label: 'Contact & parish ready',
          ),
          _ActivationStepRow(
            complete: payoutReady,
            label: 'Payout details ready',
          ),
          _ActivationStepRow(
            complete: supplyReady,
            label: 'First crop reported',
          ),

          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: FarmColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: FarmColors.line,
              ),
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  nextTitle,
                  style: const TextStyle(
                    color: FarmColors.ink,
                    fontSize: 11.2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  nextMessage,
                  style: const TextStyle(
                    color: FarmColors.mutedText,
                    fontSize: 9.6,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: nextAction,
              child: Text(nextTitle),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivationStepRow extends StatelessWidget {
  final bool complete;
  final String label;

  const _ActivationStepRow({
    required this.complete,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 4,
      ),
      child: Row(
        children: [
          Icon(
            complete
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked,
            color: complete
                ? FarmColors.success
                : FarmColors.mutedText,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: complete
                    ? FarmColors.ink
                    : FarmColors.mutedText,
                fontSize: 10.3,
                fontWeight: complete
                    ? FontWeight.w800
                    : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FarmerAttentionRow extends StatelessWidget {
  final String title;
  final String message;
  final String action;
  final VoidCallback onTap;

  const _FarmerAttentionRow({
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
                  fontSize: 12.2,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                message,
                style: const TextStyle(
                  color: FarmColors.mutedText,
                  fontSize: 10.1,
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

class _FarmerProgressCard extends StatelessWidget {
  final int supplyReports;
  final int currentOpportunities;
  final int completedCollections;
  final double releasedPayout;
  final VoidCallback onOpenPayments;

  const _FarmerProgressCard({
    required this.supplyReports,
    required this.currentOpportunities,
    required this.completedCollections,
    required this.releasedPayout,
    required this.onOpenPayments,
  });

  String get _message {
    if (releasedPayout > 0.0001) {
      return 'HPJ records show ${formatJmd(releasedPayout)} released to you so far. Your supply and collection history continues to build from real completed activity.';
    }

    if (completedCollections > 0) {
      return '$completedCollections completed collection${completedCollections == 1 ? '' : 's'} now form part of your HPJ supply history.';
    }

    return '$supplyReports supply report${supplyReports == 1 ? '' : 's'} on file. Keeping them current helps turn your activity into stronger matching and collection history.';
  }

  @override
  Widget build(BuildContext context) {
    return FarmCard(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your HPJ progress',
            style: TextStyle(
              color: FarmColors.ink,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'A factual view of the activity you have built with HPJ.',
            style: TextStyle(
              color: FarmColors.mutedText,
              fontSize: 9.8,
              height: 1.3,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          LayoutBuilder(
            builder: (context, constraints) {
              final width =
                  (constraints.maxWidth - 9) / 2;

              return Wrap(
                spacing: 9,
                runSpacing: 9,
                children: [
                  SizedBox(
                    width: width,
                    child: _FarmerProgressMetric(
                      label: 'Supply reports',
                      value: '$supplyReports',
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _FarmerProgressMetric(
                      label: 'Current opportunities',
                      value: '$currentOpportunities',
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _FarmerProgressMetric(
                      label: 'Collections completed',
                      value: '$completedCollections',
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _FarmerProgressMetric(
                      label: 'Released payouts',
                      value: releasedPayout > 0.0001
                          ? formatJmd(releasedPayout)
                          : 'J\$0',
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 12),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: FarmColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: FarmColors.line,
              ),
            ),
            child: Text(
              _message,
              style: const TextStyle(
                color: FarmColors.mutedText,
                fontSize: 9.7,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          if (releasedPayout > 0.0001) ...[
            const SizedBox(height: 9),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: onOpenPayments,
                child: const Text(
                  'View My Payments',
                ),
              ),
            ),
          ],

          const SizedBox(height: 4),

          const Text(
            'This is your own HPJ activity history — not a rating or score.',
            style: TextStyle(
              color: FarmColors.mutedText,
              fontSize: 8.8,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FarmerProgressMetric extends StatelessWidget {
  final String label;
  final String value;

  const _FarmerProgressMetric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 66,
      ),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: FarmColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: FarmColors.line,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: FarmColors.mutedText,
              fontSize: 8.7,
              height: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
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
        ],
      ),
    );
  }
}

class _FarmerQuickActionGrid extends StatelessWidget {
  final List<Widget> children;

  const _FarmerQuickActionGrid({
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 9) / 2;

        return Wrap(
          spacing: 9,
          runSpacing: 9,
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

class _FarmerQuickAction extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _FarmerQuickAction({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: FarmColors.card,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        borderRadius: BorderRadius.circular(17),
        onTap: onTap,
        child: Container(
          height: 84,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: FarmColors.line,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: FarmColors.ink,
                        fontSize: 11.2,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: FarmColors.mutedText,
                        fontSize: 9.2,
                        height: 1.25,
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
                size: 19,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FarmerSupplyEntrySheet extends StatefulWidget {
  final List<FarmerSupplyForecast> recentSupplies;

  const _FarmerSupplyEntrySheet({
    required this.recentSupplies,
  });

  @override
  State<_FarmerSupplyEntrySheet> createState() =>
      _FarmerSupplyEntrySheetState();
}

class _FarmerSupplyEntrySheetState
    extends State<_FarmerSupplyEntrySheet> {
  final cropController = TextEditingController();
  final quantityController = TextEditingController();
  final notesController = TextEditingController();

  static const allowedCategories = <String>[
    'Vegetables',
    'Fruits',
    'Ground Provisions',
    'Herbs',
    'Other',
  ];

  static const allowedUnits = <String>[
    'lb',
    'kg',
    'bundle',
    'each',
    'crate',
  ];

  int step = 0;
  String selectedCategory = 'Vegetables';
  String selectedUnit = 'lb';

  DateTime expectedHarvestDate =
      DateTime.now().add(
    const Duration(days: 14),
  );

  bool saving = false;
  bool showMoreDetails = false;

  List<FarmerSupplyForecast> get recentCrops {
    final unique =
        <String, FarmerSupplyForecast>{};

    for (final item
        in widget.recentSupplies) {
      final key =
          item.cropName.trim().toLowerCase();

      if (key.isEmpty ||
          unique.containsKey(key)) {
        continue;
      }

      unique[key] = item;

      if (unique.length >= 4) break;
    }

    return unique.values.toList();
  }

  @override
  void initState() {
    super.initState();

    if (widget.recentSupplies.isNotEmpty) {
      _reuseDefaults(
        widget.recentSupplies.first,
        setCrop: false,
      );
    }

    cropController.addListener(_persistSmartDraft);
    quantityController.addListener(_persistSmartDraft);
    notesController.addListener(_persistSmartDraft);
    unawaited(_restoreSmartDraft());
  }

  Future<void> _restoreSmartDraft() async {
    final crop = await HpjSmartLocalStore.readString('farmer_supply_crop');
    final quantity = await HpjSmartLocalStore.readString('farmer_supply_quantity');
    final notes = await HpjSmartLocalStore.readString('farmer_supply_notes');
    final category = await HpjSmartLocalStore.readString('farmer_supply_category');
    final unit = await HpjSmartLocalStore.readString('farmer_supply_unit');
    final harvestMs = await HpjSmartLocalStore.readInt('farmer_supply_harvest_ms');
    final savedStep = await HpjSmartLocalStore.readInt('farmer_supply_step');

    if (!mounted) return;
    final hasDraft = (crop?.isNotEmpty ?? false) || (quantity?.isNotEmpty ?? false);
    if (!hasDraft) return;

    setState(() {
      cropController.text = crop ?? cropController.text;
      quantityController.text = quantity ?? quantityController.text;
      notesController.text = notes ?? notesController.text;
      if (category != null && allowedCategories.contains(category)) {
        selectedCategory = category;
      }
      if (unit != null && allowedUnits.contains(unit)) selectedUnit = unit;
      if (harvestMs != null && harvestMs > 0) {
        expectedHarvestDate = DateTime.fromMillisecondsSinceEpoch(harvestMs);
      }
      step = (savedStep ?? 0).clamp(0, 1).toInt();
    });
  }

  void _persistSmartDraft() {
    unawaited(HpjSmartLocalStore.writeString('farmer_supply_crop', cropController.text));
    unawaited(HpjSmartLocalStore.writeString('farmer_supply_quantity', quantityController.text));
    unawaited(HpjSmartLocalStore.writeString('farmer_supply_notes', notesController.text));
    unawaited(HpjSmartLocalStore.writeString('farmer_supply_category', selectedCategory));
    unawaited(HpjSmartLocalStore.writeString('farmer_supply_unit', selectedUnit));
    unawaited(HpjSmartLocalStore.writeInt(
      'farmer_supply_harvest_ms',
      expectedHarvestDate.millisecondsSinceEpoch,
    ));
    unawaited(HpjSmartLocalStore.writeInt('farmer_supply_step', step));
  }

  Future<void> _clearSmartDraft() async {
    for (final key in const <String>[
      'farmer_supply_crop',
      'farmer_supply_quantity',
      'farmer_supply_notes',
      'farmer_supply_category',
      'farmer_supply_unit',
      'farmer_supply_harvest_ms',
      'farmer_supply_step',
    ]) {
      await HpjSmartLocalStore.remove(key);
    }
  }

  @override
  void dispose() {
    cropController.dispose();
    quantityController.dispose();
    notesController.dispose();
    super.dispose();
  }

  void _reuseDefaults(
    FarmerSupplyForecast supply, {
    bool setCrop = true,
  }) {
    final category =
        supply.category?.trim() ?? '';
    final unit = supply.unit.trim();

    setState(() {
      if (setCrop) {
        cropController.text =
            supply.cropName;
      }

      if (allowedCategories
          .contains(category)) {
        selectedCategory = category;
      }

      if (allowedUnits.contains(unit)) {
        selectedUnit = unit;
      }
    });
    _persistSmartDraft();
  }

  void _setHarvestDays(int days) {
    final now = DateTime.now();

    setState(() {
      expectedHarvestDate = DateTime(
        now.year,
        now.month,
        now.day,
      ).add(
        Duration(days: days),
      );
    });
    _persistSmartDraft();
  }

  Future<void> _chooseHarvestDate() async {
    final now = DateTime.now();

    final selected = await showDatePicker(
      context: context,
      initialDate: expectedHarvestDate,
      firstDate: now,
      lastDate: now.add(
        const Duration(days: 730),
      ),
    );

    if (!mounted || selected == null) {
      return;
    }

    setState(() {
      expectedHarvestDate = selected;
    });
    _persistSmartDraft();
  }

  Future<void> _chooseCropByPicture() async {
    if (saving) return;

    final product = await showHpjProductPicturePicker(
      context,
      title: 'What are you growing?',
    );

    if (!mounted || product == null) return;

    final category = product.category.trim();
    final unit = (product.unit ?? '').trim().toLowerCase();

    setState(() {
      cropController.text = product.name;

      selectedCategory = allowedCategories.contains(category)
          ? category
          : 'Other';

      if (allowedUnits.contains(unit)) {
        selectedUnit = unit;
      }
    });
    _persistSmartDraft();
  }

  bool _validateStepOne() {
    if (cropController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Tell HPJ which crop you are growing.',
          ),
        ),
      );
      return false;
    }

    final quantity = double.tryParse(
      quantityController.text
          .trim()
          .replaceAll(',', ''),
    );

    if (quantity == null ||
        quantity <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Add your best estimate of the quantity you expect to harvest.',
          ),
        ),
      );
      return false;
    }

    return true;
  }

  void _continue() {
    if (saving || !_validateStepOne()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      step = 1;
    });
    _persistSmartDraft();
  }

  void _back() {
    if (saving) return;

    FocusScope.of(context).unfocus();

    setState(() {
      step = 0;
    });
    _persistSmartDraft();
  }

  Future<void> _submit() async {
    if (saving ||
        !_validateStepOne()) {
      return;
    }

    final crop =
        cropController.text.trim();

    final quantity = double.parse(
      quantityController.text
          .trim()
          .replaceAll(',', ''),
    );

    setState(() {
      saving = true;
    });

    try {
      await createFarmerSupplyForecast(
        cropName: crop,
        category: selectedCategory,
        quantityGrowing: quantity,
        expectedQuantity: quantity,
        unit: selectedUnit,
        expectedHarvestDate:
            expectedHarvestDate,
        status: 'growing',
        notes: notesController.text.trim(),
      );

      if (!mounted) return;

      await _clearSmartDraft();
      if (!mounted) return;
      Navigator.of(context).pop(crop);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        saving = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceFirst(
                  'Exception: ',
                  '',
                ),
          ),
        ),
      );
    }
  }

  String get _dateLabel {
    return '${expectedHarvestDate.year}-'
        '${expectedHarvestDate.month.toString().padLeft(2, '0')}-'
        '${expectedHarvestDate.day.toString().padLeft(2, '0')}';
  }

  Widget _progress() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              color: FarmColors.primary,
              borderRadius:
                  BorderRadius.circular(99),
            ),
          ),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              color: step == 1
                  ? FarmColors.primary
                  : FarmColors.line,
              borderRadius:
                  BorderRadius.circular(99),
            ),
          ),
        ),
      ],
    );
  }

  Widget _stepOne() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'What are you growing?',
          style: TextStyle(
            color: FarmColors.ink,
            fontSize: 22,
            fontWeight:
                FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Start with one crop and your best quantity estimate. You can update it later.',
          style: TextStyle(
            color: FarmColors.mutedText,
            fontSize: 10.5,
            height: 1.38,
            fontWeight:
                FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),

        if (recentCrops.isNotEmpty) ...[
          const Text(
            'Report again',
            style: TextStyle(
              color: FarmColors.ink,
              fontSize: 10.5,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          SizedBox(
            height: 104,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: recentCrops.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final supply = recentCrops[index];

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: saving
                        ? null
                        : () => _reuseDefaults(supply),
                    child: Ink(
                      width: 112,
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
                            productName: supply.cropName,
                            size: 58,
                            radius: 12,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            supply.cropName,
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
          const SizedBox(height: 14),
        ],

        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: saving ? null : _chooseCropByPicture,
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Choose crop by picture'),
          ),
        ),

        const SizedBox(height: 10),

        TextField(
          controller: cropController,
          enabled: !saving,
          textCapitalization:
              TextCapitalization.words,
          autofocus:
              recentCrops.isEmpty,
          decoration:
              const InputDecoration(
            labelText: 'Crop',
            hintText:
                'e.g. Callaloo',
          ),
        ),

        const SizedBox(height: 11),

        Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller:
                    quantityController,
                enabled: !saving,
                keyboardType:
                    const TextInputType
                        .numberWithOptions(
                  decimal: true,
                ),
                decoration:
                    const InputDecoration(
                  labelText:
                      'Approx. quantity',
                  hintText: '100',
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child:
                  DropdownButtonFormField<
                      String>(
                value: selectedUnit,
                isExpanded: true,
                decoration:
                    const InputDecoration(
                  labelText: 'Unit',
                ),
                items: allowedUnits
                    .map(
                      (value) =>
                          DropdownMenuItem<
                              String>(
                        value: value,
                        child: Text(value),
                      ),
                    )
                    .toList(),
                onChanged: saving
                    ? null
                    : (value) {
                        if (value == null) {
                          return;
                        }

                        setState(() {
                          selectedUnit =
                              value;
                        });
                        _persistSmartDraft();
                      },
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        const Text(
          'A good estimate is enough. HPJ can work with an updated estimate better than waiting until harvest day.',
          style: TextStyle(
            color: FarmColors.mutedText,
            fontSize: 9.3,
            height: 1.35,
            fontWeight:
                FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _stepTwo() {
    final today = DateTime.now();

    final selectedDays = DateTime(
      expectedHarvestDate.year,
      expectedHarvestDate.month,
      expectedHarvestDate.day,
    )
        .difference(
          DateTime(
            today.year,
            today.month,
            today.day,
          ),
        )
        .inDays;

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'When should it be ready?',
          style: TextStyle(
            color: FarmColors.ink,
            fontSize: 22,
            fontWeight:
                FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'This helps HPJ compare your expected harvest with when buyers may need it.',
          style: TextStyle(
            color: FarmColors.mutedText,
            fontSize: 10.5,
            height: 1.38,
            fontWeight:
                FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),

        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            for (final days
                in const <int>[
              7,
              14,
              30,
              60,
            ])
              ChoiceChip(
                label: Text(
                  days == 7
                      ? 'About 1 week'
                      : days == 14
                          ? 'About 2 weeks'
                          : days == 30
                              ? 'About 1 month'
                              : 'About 2 months',
                ),
                selected:
                    selectedDays == days,
                onSelected: saving
                    ? null
                    : (_) =>
                        _setHarvestDays(
                          days,
                        ),
              ),
          ],
        ),

        const SizedBox(height: 12),

        InkWell(
          onTap: saving
              ? null
              : _chooseHarvestDate,
          borderRadius:
              BorderRadius.circular(16),
          child: InputDecorator(
            decoration:
                const InputDecoration(
              labelText:
                  'Expected harvest date',
              suffixIcon: Icon(
                Icons
                    .calendar_month_outlined,
              ),
            ),
            child: Text(
              _dateLabel,
              style: const TextStyle(
                color: FarmColors.ink,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        Material(
          color: FarmColors.background,
          borderRadius:
              BorderRadius.circular(14),
          child: InkWell(
            borderRadius:
                BorderRadius.circular(14),
            onTap: saving
                ? null
                : () {
                    setState(() {
                      showMoreDetails =
                          !showMoreDetails;
                    });
                  },
            child: Padding(
              padding:
                  const EdgeInsets.all(11),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          'More details',
                          style: TextStyle(
                            color:
                                FarmColors.ink,
                            fontSize: 10.5,
                            fontWeight:
                                FontWeight
                                    .w900,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Optional category and notes',
                          style: TextStyle(
                            color: FarmColors
                                .mutedText,
                            fontSize: 8.9,
                            fontWeight:
                                FontWeight
                                    .w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    showMoreDetails
                        ? Icons
                            .expand_less_rounded
                        : Icons
                            .expand_more_rounded,
                    color:
                        FarmColors.mutedText,
                  ),
                ],
              ),
            ),
          ),
        ),

        if (showMoreDetails) ...[
          const SizedBox(height: 10),

          DropdownButtonFormField<String>(
            value: selectedCategory,
            isExpanded: true,
            decoration:
                const InputDecoration(
              labelText: 'Category',
            ),
            items: allowedCategories
                .map(
                  (value) =>
                      DropdownMenuItem<
                          String>(
                    value: value,
                    child: Text(value),
                  ),
                )
                .toList(),
            onChanged: saving
                ? null
                : (value) {
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      selectedCategory =
                          value;
                    });
                  },
          ),

          const SizedBox(height: 10),

          TextField(
            controller:
                notesController,
            enabled: !saving,
            minLines: 2,
            maxLines: 3,
            decoration:
                const InputDecoration(
              labelText:
                  'Notes (optional)',
              hintText:
                  'Quality, variety, or anything HPJ should know',
            ),
          ),
        ],

        const SizedBox(height: 12),

        Container(
          width: double.infinity,
          padding:
              const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: const Color(
              0xFFF0F4EC,
            ),
            borderRadius:
                BorderRadius.circular(14),
            border: Border.all(
              color: const Color(
                0xFFDCE4D8,
              ),
            ),
          ),
          child: const Text(
            'After you save, HPJ will immediately check this crop against visible buyer demand.',
            style: TextStyle(
              color: Color(0xFF5D6A63),
              fontSize: 9.6,
              height: 1.35,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight =
        MediaQuery.of(context)
                .size
                .height *
            0.84;

    return AnimatedPadding(
      duration:
          const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(
        bottom:
            MediaQuery.of(context)
                .viewInsets
                .bottom,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: maxHeight,
        ),
        child: Container(
          decoration:
              const BoxDecoration(
            color: FarmColors.card,
            borderRadius:
                BorderRadius.vertical(
              top:
                  Radius.circular(26),
            ),
          ),
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.fromLTRB(
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
                    decoration:
                        BoxDecoration(
                      color:
                          FarmColors.line,
                      borderRadius:
                          BorderRadius
                              .circular(99),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Text(
                      'Step ${step + 1} of 2',
                      style:
                          const TextStyle(
                        color: FarmColors
                            .mutedText,
                        fontSize: 9.4,
                        fontWeight:
                            FontWeight
                                .w900,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: saving
                          ? null
                          : () =>
                              Navigator.of(
                                context,
                              ).pop(),
                      icon: const Icon(
                        Icons.close_rounded,
                      ),
                    ),
                  ],
                ),

                _progress(),
                const SizedBox(height: 18),

                if (step == 0)
                  _stepOne()
                else
                  _stepTwo(),

                const SizedBox(height: 20),

                Row(
                  children: [
                    if (step == 1) ...[
                      Expanded(
                        child:
                            OutlinedButton(
                          onPressed:
                              saving
                                  ? null
                                  : _back,
                          child:
                              const Text(
                            'Back',
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 9,
                      ),
                    ],
                    Expanded(
                      flex:
                          step == 1 ? 2 : 1,
                      child: step == 0
                          ? ElevatedButton(
                              onPressed:
                                  saving
                                      ? null
                                      : _continue,
                              child:
                                  const Text(
                                'Continue',
                              ),
                            )
                          : PrimaryFarmButton(
                              label: saving
                                  ? 'Saving...'
                                  : 'Save Supply',
                              onPressed:
                                  saving
                                      ? null
                                      : _submit,
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class _FarmerRecordFocusNotice extends StatelessWidget {
  final bool found;
  final String foundMessage;
  final String missingMessage;

  const _FarmerRecordFocusNotice({
    required this.found,
    required this.foundMessage,
    required this.missingMessage,
  });

  @override
  Widget build(BuildContext context) {
    final accent = found
        ? FarmColors.primary
        : FarmColors.warning;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: found
            ? FarmColors.primarySoft
            : const Color(0xFFFFF7E8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: accent.withOpacity(0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            found
                ? Icons.notifications_active_outlined
                : Icons.info_outline_rounded,
            size: 18,
            color: accent,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              found ? foundMessage : missingMessage,
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
    );
  }
}

class FarmerSupplyScreen extends StatefulWidget {
  final FarmerProfile profile;
  final int refreshKey;
  final String? initialSupplyId;

  const FarmerSupplyScreen({
    super.key,
    required this.profile,
    required this.refreshKey,
    this.initialSupplyId,
  });

  @override
  State<FarmerSupplyScreen> createState() =>
      _FarmerSupplyScreenState();
}

class _FarmerSupplyScreenState
    extends State<FarmerSupplyScreen> {
  int localRefreshKey = 0;

  void refreshSupply() {
    setState(() {
      localRefreshKey++;
    });
  }

  Future<void> openSupplyForm(
    List<FarmerSupplyForecast>
        recentSupplies,
  ) async {
    final savedCrop =
        await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor:
          Colors.transparent,
      builder: (_) =>
          _FarmerSupplyEntrySheet(
        recentSupplies:
            recentSupplies,
      ),
    );

    if (!mounted ||
        savedCrop == null ||
        savedCrop.trim().isEmpty) {
      return;
    }

    refreshSupply();

    await _showSupplyValueFeedback(
      savedCrop.trim(),
    );
  }

  Future<void>
      _showSupplyValueFeedback(
    String cropName,
  ) async {
    FarmerMarketDemandOpportunity?
        match;

    try {
      final board =
          await fetchFarmerMarketDemandBoard(
        30,
      );

      final wanted =
          cropName.trim().toLowerCase();

      for (final item in board) {
        if (item.productName
                .trim()
                .toLowerCase() ==
            wanted) {
          match = item;
          break;
        }
      }
    } catch (error) {
      farmDebugLog(
        'Farmer supply value feedback unavailable: $error',
      );
    }

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor:
          Colors.transparent,
      builder: (_) =>
          _FarmerSupplyValueSheet(
        cropName: cropName,
        opportunity: match,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FarmPage(
      child:
          FutureBuilder<List<FarmerSupplyForecast>>(
        key: ValueKey(
          'farmer-supply-${widget.refreshKey}-$localRefreshKey',
        ),
        future:
            fetchFarmerSupplyForecasts(
          widget.profile.id,
        ),
        builder: (
          context,
          snapshot,
        ) {
          final supplies =
              snapshot.data ??
                  const <
                      FarmerSupplyForecast>[];

          final requestedSupplyId =
              widget.initialSupplyId?.trim() ?? '';

          final focusedSupplies = requestedSupplyId.isEmpty
              ? const <FarmerSupplyForecast>[]
              : supplies
                  .where(
                    (item) =>
                        item.id.trim() == requestedSupplyId,
                  )
                  .toList();

          final exactSupplyFound = focusedSupplies.isNotEmpty;
          final visibleSupplies =
              exactSupplyFound ? focusedSupplies : supplies;

          final active = visibleSupplies
              .where(
                (item) =>
                    item.isActive,
              )
              .toList();

          final past = visibleSupplies
              .where(
                (item) =>
                    !item.isActive,
              )
              .toList();

          if (snapshot.connectionState ==
                  ConnectionState.waiting &&
              supplies.isEmpty) {
            return ListView(
              padding:
                  const EdgeInsets.fromLTRB(
                18,
                24,
                18,
                100,
              ),
              children: const [
                SizedBox(
                  height: 320,
                  child:
                      SkeletonList(
                    count: 3,
                  ),
                ),
              ],
            );
          }

          return ListView(
            padding:
                const EdgeInsets.fromLTRB(
              18,
              18,
              18,
              100,
            ),
            children: [
              const Text(
                'What are you growing?',
                style: TextStyle(
                  color: FarmColors.ink,
                  fontSize: 21,
                  height: 1.05,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),

              const SizedBox(height: 5),

              const Text(
                'Keep your expected harvest current. HPJ uses it to look for buyer demand and plan collections.',
                style: TextStyle(
                  color:
                      FarmColors.mutedText,
                  fontSize: 10.3,
                  height: 1.38,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),

              const SizedBox(height: 14),

              SizedBox(
                width: double.infinity,
                child: PrimaryFarmButton(
                  label: active.isEmpty
                      ? 'Add My First Crop'
                      : '+ Add Another Crop',
                  onPressed: () =>
                      openSupplyForm(
                    supplies,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              if (requestedSupplyId.isNotEmpty) ...[
                _FarmerRecordFocusNotice(
                  found: exactSupplyFound,
                  foundMessage:
                      'Opened from your notification. Showing the related supply report.',
                  missingMessage:
                      'That supply report is no longer available. Showing your current supply instead.',
                ),
                const SizedBox(height: 14),
              ],

              if (active.isEmpty && past.isEmpty)
                _FarmerFirstCropCard(
                  onTap: () =>
                      openSupplyForm(
                    supplies,
                  ),
                )
              else ...[
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Current supply',
                        style: TextStyle(
                          color:
                              FarmColors.ink,
                          fontSize: 14,
                          fontWeight:
                              FontWeight.w900,
                        ),
                      ),
                    ),
                    Text(
                      '${active.length} active',
                      style: const TextStyle(
                        color: FarmColors
                            .mutedText,
                        fontSize: 9.2,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 9),

                ...active.map(
                  (supply) =>
                      Padding(
                    padding:
                        const EdgeInsets
                            .only(
                      bottom: 10,
                    ),
                    child:
                        _FarmerSupplyCard(
                      supply: supply,
                      onChanged:
                          refreshSupply,
                    ),
                  ),
                ),
              ],

              if (past.isNotEmpty) ...[
                const SizedBox(height: 10),

                FarmCard(
                  padding: EdgeInsets.zero,
                  child: ExpansionTile(
                    tilePadding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 14,
                    ),
                    childrenPadding:
                        const EdgeInsets
                            .fromLTRB(
                      12,
                      0,
                      12,
                      12,
                    ),
                    title: const Text(
                      'Past supply',
                      style: TextStyle(
                        color:
                            FarmColors.ink,
                        fontSize: 11.5,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                    subtitle: Text(
                      '${past.length} previous report${past.length == 1 ? '' : 's'}',
                      style:
                          const TextStyle(
                        color: FarmColors
                            .mutedText,
                        fontSize: 9,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                    children: past
                        .map(
                          (supply) =>
                              Padding(
                            padding:
                                const EdgeInsets
                                    .only(
                              top: 8,
                            ),
                            child:
                                _FarmerSupplyCard(
                              supply:
                                  supply,
                              onChanged:
                                  refreshSupply,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _FarmerFirstCropCard
    extends StatelessWidget {
  final VoidCallback onTap;

  const _FarmerFirstCropCard({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F4EC),
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: const Color(
            0xFFDCE4D8,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Start with one crop',
            style: TextStyle(
              color: FarmColors.ink,
              fontSize: 14,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'You only need the crop, an approximate quantity, and when you expect it to be ready.',
            style: TextStyle(
              color: Color(0xFF5F6D65),
              fontSize: 9.8,
              height: 1.38,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: onTap,
            child:
                const Text('Add crop'),
          ),
        ],
      ),
    );
  }
}

class _FarmerSupplyValueSheet
    extends StatelessWidget {
  final String cropName;
  final FarmerMarketDemandOpportunity?
      opportunity;

  const _FarmerSupplyValueSheet({
    required this.cropName,
    required this.opportunity,
  });

  String get headline {
    final item = opportunity;

    if (item == null) {
      return 'Supply saved';
    }

    switch (item.demandSignal) {
      case 'committed_need':
        return 'Buyer demand is waiting';
      case 'urgent':
        return 'Buyers need this soon';
      case 'opportunity':
        return 'There is buyer demand';
      case 'covered_by_you':
        return 'Your supply is helping cover demand';
      default:
        return 'HPJ is watching demand for this crop';
    }
  }

  String get message {
    final item = opportunity;

    if (item == null) {
      return 'HPJ now has your latest supply information. We will surface matching demand when it becomes available.';
    }

    if (item.opportunityGap > 0.0001) {
      return '${_farmerPartnerNumber(item.opportunityGap)} ${item.unit} of ${item.productName} is currently uncovered.';
    }

    if (item.visibleDemand > 0.0001) {
      return 'HPJ is tracking ${_farmerPartnerNumber(item.visibleDemand)} ${item.unit} of visible demand for ${item.productName}.';
    }

    return 'Your updated supply will help HPJ plan future matching and collection.';
  }

  @override
  Widget build(BuildContext context) {
    final item = opportunity;
    final maxHeight =
        MediaQuery.of(context).size.height *
            0.72;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: maxHeight,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: FarmColors.card,
            borderRadius:
                BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.fromLTRB(
              18,
              12,
              18,
              18,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: FarmColors.line,
                      borderRadius:
                          BorderRadius.circular(
                        99,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HpjProductThumb(
                      productName: cropName,
                      size: 76,
                      radius: 15,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SUPPLY SAVED',
                            style: TextStyle(
                              color: FarmColors.success,
                              fontSize: 8.7,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.4,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            headline,
                            style: const TextStyle(
                              color: FarmColors.ink,
                              fontSize: 19,
                              height: 1.08,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Text(
                  message,
                  style: const TextStyle(
                    color:
                        FarmColors.mutedText,
                    fontSize: 10.6,
                    height: 1.38,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),

                if (item != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child:
                            _FarmerValueStat(
                          label:
                              'Demand signal',
                          value:
                              item.signalLabel,
                        ),
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      Expanded(
                        child:
                            _FarmerValueStat(
                          label: 'Next need',
                          value:
                              item.nextNeedBy ==
                                      null
                                  ? 'Watching'
                                  : _farmerPartnerDate(
                                      item.nextNeedBy!,
                                    ),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 11),

                const Text(
                  'Demand is shown in aggregate. HPJ does not reveal another farmer’s private supply or a buyer’s private commercial details.',
                  style: TextStyle(
                    color:
                        FarmColors.mutedText,
                    fontSize: 8.9,
                    height: 1.35,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () =>
                        Navigator.of(context)
                            .pop(),
                    child:
                        const Text('Done'),
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

class _FarmerValueStat extends StatelessWidget {
  final String label;
  final String value;

  const _FarmerValueStat({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: FarmColors.background,
        borderRadius: BorderRadius.circular(14),
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
              fontSize: 8.6,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: FarmColors.ink,
              fontSize: 11.2,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// COMPACT FARMER SUPPLY CARD
// =====================================================

class _FarmerSupplyUpdateSheet extends StatefulWidget {
  final FarmerSupplyForecast supply;

  const _FarmerSupplyUpdateSheet({
    required this.supply,
  });

  @override
  State<_FarmerSupplyUpdateSheet> createState() =>
      _FarmerSupplyUpdateSheetState();
}

class _FarmerSupplyUpdateSheetState
    extends State<_FarmerSupplyUpdateSheet> {
  late final TextEditingController expectedController;
  late final TextEditingController harvestedController;

  static const editableStatuses = <String>[
    'planning',
    'growing',
    'expected',
    'harvest_ready',
    'harvested',
  ];

  late String selectedStatus;
  bool saving = false;

  FarmerSupplyForecast get supply => widget.supply;

  @override
  void initState() {
    super.initState();

    expectedController = TextEditingController(
      text: supply.expectedQuantity == null
          ? ''
          : supply.expectedQuantity!.toString(),
    );

    harvestedController = TextEditingController(
      text: supply.harvestedQuantity == null
          ? ''
          : supply.harvestedQuantity!.toString(),
    );

    selectedStatus = editableStatuses.contains(supply.status)
        ? supply.status
        : 'growing';
  }

  @override
  void dispose() {
    expectedController.dispose();
    harvestedController.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (saving) return;

    final expected = double.tryParse(
      expectedController.text.trim(),
    );

    final harvested = double.tryParse(
      harvestedController.text.trim(),
    );

    if ((expected ?? 0) < 0 || (harvested ?? 0) < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Quantities cannot be negative.',
          ),
        ),
      );
      return;
    }

    setState(() {
      saving = true;
    });

    try {
      await updateFarmerSupplyForecast(
        forecastId: supply.id,
        expectedQuantity: expected,
        harvestedQuantity: harvested,
        status: selectedStatus,
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
            error.toString().replaceFirst(
                  'Exception: ',
                  '',
                ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          18,
          12,
          18,
          18,
        ),
        decoration: const BoxDecoration(
          color: FarmColors.card,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(26),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
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
              const SizedBox(height: 16),

              Row(
                children: [
                  HpjProductThumb(
                    productName: supply.cropName,
                    size: 70,
                    radius: 14,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          supply.cropName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: FarmColors.ink,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'Update harvest progress',
                          style: TextStyle(
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

              const SizedBox(height: 18),

              DropdownButtonFormField<String>(
                value: selectedStatus,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Current stage',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'planning',
                    child: Text('Planning'),
                  ),
                  DropdownMenuItem(
                    value: 'growing',
                    child: Text('Growing'),
                  ),
                  DropdownMenuItem(
                    value: 'expected',
                    child: Text('Expected'),
                  ),
                  DropdownMenuItem(
                    value: 'harvest_ready',
                    child: Text('Harvest ready'),
                  ),
                  DropdownMenuItem(
                    value: 'harvested',
                    child: Text('Harvested'),
                  ),
                ],
                onChanged: saving
                    ? null
                    : (value) {
                        if (value == null) return;
                        setState(() {
                          selectedStatus = value;
                        });
                      },
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: expectedController,
                      enabled: !saving,
                      keyboardType:
                          const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Expected',
                        suffixText: supply.unit,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: harvestedController,
                      enabled: !saving,
                      keyboardType:
                          const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Harvested',
                        suffixText: supply.unit,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: saving
                      ? const SizedBox(
                          width: 17,
                          height: 17,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.check_rounded,
                        ),
                  label: Text(
                    saving ? 'Saving...' : 'Save Update',
                  ),
                  onPressed: saving ? null : save,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FarmerSupplyCard extends StatelessWidget {
  final FarmerSupplyForecast supply;
  final VoidCallback onChanged;

  const _FarmerSupplyCard({
    required this.supply,
    required this.onChanged,
  });

  String _quantity(double? value) {
    if (value == null) return '—';

    final text = value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);

    return '$text ${supply.unit}';
  }

  String _dateLabel(DateTime? date) {
    if (date == null) return 'Not set';

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

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Color _statusColor() {
    if (supply.isHpjConfirmed) {
      return FarmColors.green;
    }

    if (supply.isHarvested || supply.isHarvestReady) {
      return FarmColors.warning;
    }

    if (supply.isCancelled) {
      return FarmColors.danger;
    }

    return FarmColors.deepGreen;
  }

  bool get _locked {
    return supply.isHpjConfirmed || supply.isCompleted || supply.isCancelled;
  }

  Widget _metric({
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: FarmColors.cardSoft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: FarmColors.line,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const SizedBox(height: 3),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: FarmColors.ink,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openUpdate(
    BuildContext context,
  ) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FarmerSupplyUpdateSheet(
        supply: supply,
      ),
    );

    if (saved != true) return;

    onChanged();

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${supply.cropName} updated.',
        ),
      ),
    );
  }

  Future<void> _confirmStillAccurate(
    BuildContext context,
  ) async {
    try {
      await updateFarmerSupplyForecast(
        forecastId: supply.id,
        expectedQuantity: supply.expectedQuantity,
        harvestedQuantity: supply.harvestedQuantity,
        status: supply.status,
      );

      onChanged();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${supply.cropName} confirmed as current.',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceFirst(
                  'Exception: ',
                  '',
                ),
          ),
        ),
      );
    }
  }

  Future<void> _cancelSupply(
    BuildContext context,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Cancel crop report?',
          ),
          content: Text(
            '${supply.cropName} will be removed from your active supply planning.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('Keep'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text('Cancel report'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await cancelFarmerSupplyForecast(
        supply.id,
      );

      onChanged();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${supply.cropName} cancelled.',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor();

    final category = (supply.category ?? '').trim();

    final notes = (supply.notes ?? '').trim();

    return FarmCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---------------------------------------------
          // CROP + STATUS
          // ---------------------------------------------

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HpjProductThumb(
                productName: supply.cropName,
                size: 58,
                radius: 14,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      supply.cropName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: FarmColors.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (category.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        category,
                        style: const TextStyle(
                          color: FarmColors.mutedText,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  supply.statusLabel,
                  style: TextStyle(
                    color: color,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 13),

          // ---------------------------------------------
          // COMPACT NUMBERS
          // ---------------------------------------------

          Row(
            children: [
              _metric(
                label: 'Growing',
                value: _quantity(
                  supply.quantityGrowing,
                ),
              ),
              const SizedBox(width: 7),
              _metric(
                label: 'Expected',
                value: _quantity(
                  supply.expectedQuantity,
                ),
              ),
              const SizedBox(width: 7),
              _metric(
                label: 'Harvested',
                value: _quantity(
                  supply.harvestedQuantity,
                ),
              ),
            ],
          ),

          const SizedBox(height: 11),

          // ---------------------------------------------
          // HARVEST DATE
          // ---------------------------------------------

          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 15,
                color: FarmColors.mutedText,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Expected ${_dateLabel(supply.expectedHarvestDate)}',
                  style: const TextStyle(
                    color: FarmColors.mutedText,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: _farmerSupplyNeedsReview(supply)
                  ? const Color(0xFFFFF7E8)
                  : FarmColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _farmerSupplyNeedsReview(supply)
                    ? FarmColors.warning.withOpacity(0.28)
                    : FarmColors.line,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _farmerSupplyNeedsReview(supply)
                      ? Icons.schedule_outlined
                      : Icons.check_circle_outline,
                  size: 16,
                  color: _farmerSupplyNeedsReview(supply)
                      ? FarmColors.warning
                      : FarmColors.success,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    _farmerSupplyNeedsReview(supply)
                        ? '${_farmerSupplyFreshnessLabel(supply)} • Please confirm or update'
                        : _farmerSupplyFreshnessLabel(supply),
                    style: const TextStyle(
                      color: FarmColors.mutedText,
                      fontSize: 9.8,
                      height: 1.25,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (notes.isNotEmpty) ...[
            const SizedBox(height: 9),
            Text(
              notes,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: FarmColors.ink,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ],

          if (supply.isHpjConfirmed) ...[
            const SizedBox(height: 11),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 11,
                vertical: 9,
              ),
              decoration: BoxDecoration(
                color: FarmColors.green.withOpacity(
                  0.08,
                ),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.verified_outlined,
                    color: FarmColors.green,
                    size: 17,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      supply.hpjConfirmedQuantity == null
                          ? 'Supply confirmed by HPJ'
                          : 'HPJ confirmed ${_quantity(supply.hpjConfirmedQuantity)}',
                      style: const TextStyle(
                        color: FarmColors.green,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (!_locked) ...[
            const SizedBox(height: 12),

            if (_farmerSupplyNeedsReview(supply)) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(
                    Icons.check_rounded,
                    size: 17,
                  ),
                  label: const Text(
                    'Still Accurate',
                  ),
                  onPressed: () =>
                      _confirmStillAccurate(context),
                ),
              ),
              const SizedBox(height: 8),
            ],

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 17,
                    ),
                    label: const Text('Update'),
                    onPressed: () => _openUpdate(context),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => _cancelSupply(context),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ],
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
  final String? initialPayoutId;

  const FarmerEarningsScreen({
    super.key,
    required this.profile,
    required this.refreshKey,
    this.initialPayoutId,
  });

  @override
  Widget build(BuildContext context) {
    return FarmPage(
      child: FutureBuilder<List<FarmerPayout>>(
        key: ValueKey('farmer-payouts-$refreshKey'),
        future: fetchFarmerPayouts(farmerId: profile.id),
        builder: (context, snapshot) {
          final allPayouts = snapshot.data ?? const <FarmerPayout>[];

          final requestedPayoutId =
              initialPayoutId?.trim() ?? '';

          final focusedPayouts = requestedPayoutId.isEmpty
              ? const <FarmerPayout>[]
              : allPayouts
                  .where(
                    (payout) =>
                        payout.id.trim() == requestedPayoutId,
                  )
                  .toList();

          final exactPayoutFound = focusedPayouts.isNotEmpty;
          final payouts =
              exactPayoutFound ? focusedPayouts : allPayouts;

          final pending = allPayouts
              .where((p) => p.payoutStatus == 'pending')
              .fold<double>(0, (sum, p) => sum + p.netAmount);
          final released = allPayouts
              .where((p) => p.payoutStatus == 'released')
              .fold<double>(0, (sum, p) => sum + p.netAmount);
          final held = allPayouts
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
              if (requestedPayoutId.isNotEmpty) ...[
                _FarmerRecordFocusNotice(
                  found: exactPayoutFound,
                  foundMessage:
                      'Opened from your notification. Showing the related payout.',
                  missingMessage:
                      'That payout is no longer available. Showing your current payout history instead.',
                ),
                const SizedBox(height: 12),
              ],
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
  final Future<void> Function() onProfileChanged;

  const FarmerAccountScreen({
    super.key,
    required this.profile,
    required this.onProfileChanged,
  });

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }

  Future<void> _editProfile(BuildContext context) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => _FarmerProfileEditScreen(
          profile: profile,
        ),
      ),
    );

    if (changed == true) {
      await onProfileChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final payoutReady =
        profile.payoutMethod.trim().isNotEmpty &&
        profile.payoutDetails.trim().isNotEmpty;

    final farmTitle = profile.farmName.trim().isEmpty
        ? profile.farmerName
        : profile.farmName;

    final subtitleParts = <String>[
      if (profile.farmerName.trim().isNotEmpty) profile.farmerName.trim(),
      if (profile.parish.trim().isNotEmpty) profile.parish.trim(),
    ];

    final statusColor = profile.isApproved
        ? FarmColors.success
        : profile.verificationStatus == 'rejected'
            ? FarmColors.danger
            : FarmColors.warning;

    return FarmPage(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 120),
        children: [
          HpjCompactAccountHero(
            icon: Icons.agriculture_outlined,
            title: farmTitle,
            subtitle: subtitleParts.join(' • '),
            badge: profile.statusLabel,
            badgeColor: statusColor,
          ),
          const SizedBox(height: 12),

          const _FarmerWorkspaceSwitchCard(),
          const SizedBox(height: 14),

          FarmCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AccountSectionHeading(
                  title: 'Quick access',
                  subtitle: 'The farmer tools used most often.',
                ),
                const SizedBox(height: 14),
                AccountActionGrid(
                  actions: [
                    AccountActionItem(
                      icon: Icons.grass_rounded,
                      title: 'Supply',
                      subtitle: 'Update crops',
                      onTap: () => _open(
                        context,
                        FarmerSupplyScreen(
                          profile: profile,
                          refreshKey: 0,
                        ),
                      ),
                    ),
                    AccountActionItem(
                      icon: Icons.trending_up_rounded,
                      title: 'Demand',
                      subtitle: 'Buyer needs',
                      onTap: () => _open(
                        context,
                        FarmerDemandBoardScreen(profile: profile),
                      ),
                    ),
                    AccountActionItem(
                      icon: Icons.local_shipping_outlined,
                      title: 'Collections',
                      subtitle: 'Pickup schedule',
                      onTap: () => _open(
                        context,
                        FarmerCollectionScheduleScreen(profile: profile),
                      ),
                    ),
                    AccountActionItem(
                      icon: Icons.payments_outlined,
                      title: 'Payments',
                      subtitle: 'Track earnings',
                      onTap: () => _open(
                        context,
                        FarmerEarningsScreen(
                          profile: profile,
                          refreshKey: 0,
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
                    title: 'Farmer account',
                    subtitle: 'Profile, records and preferences.',
                  ),
                ),
                AccountListTile(
                  icon: Icons.badge_outlined,
                  title: 'Farm details',
                  subtitle: payoutReady
                      ? 'Contact, location and payout details.'
                      : 'Complete your payout details.',
                  onTap: () => _editProfile(context),
                ),
                AccountListTile(
                  icon: Icons.description_outlined,
                  title: 'Activity Statement',
                  subtitle: 'Supply, collection and payout history.',
                  onTap: () => _open(
                    context,
                    _FarmerActivityStatementScreen(profile: profile),
                  ),
                ),
                AccountListTile(
                  icon: Icons.play_circle_outline_rounded,
                  title: 'Fresh Reels',
                  subtitle: 'Submit farm videos and track approval.',
                  onTap: () => _open(
                    context,
                    FarmerFreshReelsHubScreen(profile: profile),
                  ),
                ),
                AccountListTile(
                  icon: Icons.tune_rounded,
                  title: 'Settings & Preferences',
                  subtitle: 'Feed, media, alerts, privacy and password.',
                  isLast: true,
                  onTap: () => _open(
                    context,
                    const HpjSettingsPreferencesScreen(
                      audience: HpjPreferenceAudience.farmer,
                    ),
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
                  supportSubject: 'Farmer support',
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
      ),
    );
  }
}



String _farmerStatementDate(
  DateTime? value,
) {
  if (value == null) return '-';

  return '${value.year}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}

String _farmerStatementStatus(
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

Future<Uint8List> _buildFarmerActivityStatementPdf(
  FarmerProfile profile,
  _FarmerTodaySnapshot data,
) async {
  final pdf = pw.Document();

  pw.MemoryImage? logo;

  try {
    final bytes = await rootBundle.load(
      'lib/assets/images/logo.png',
    );

    logo = pw.MemoryImage(
      bytes.buffer.asUint8List(),
    );
  } catch (_) {
    logo = null;
  }

  final green =
      PdfColor.fromInt(0xFF1F6B3A);
  final softGreen =
      PdfColor.fromInt(0xFFEAF3EC);

  final released = data.payouts
      .where(
        (item) =>
            item.payoutStatus
                .trim()
                .toLowerCase() ==
            'released',
      )
      .fold<double>(
        0,
        (sum, item) =>
            sum + item.netAmount,
      );

  final completedCollections =
      data.collections
          .where(
            (item) =>
                item.stopStatus
                    .trim()
                    .toLowerCase() ==
                'completed',
          )
          .length;

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
              pdfSafe(value),
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
                .map(pdfSafe)
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

  final supplies = List<FarmerSupplyForecast>.from(
    data.supplies,
  )
    ..sort(
      (a, b) =>
          (b.updatedAt ??
                  b.createdAt ??
                  DateTime(2000))
              .compareTo(
        a.updatedAt ??
            a.createdAt ??
            DateTime(2000),
      ),
    );

  final collections =
      List<FarmerCollectionScheduleItem>.from(
    data.collections,
  )
        ..sort(
          (a, b) => b.collectionDate
              .compareTo(a.collectionDate),
        );

  final payouts =
      List<FarmerPayout>.from(
    data.payouts,
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
        pw.Row(
          crossAxisAlignment:
              pw.CrossAxisAlignment.center,
          children: [
            if (logo != null)
              pw.Container(
                width: 54,
                height: 54,
                child: pw.Image(
                  logo,
                  fit: pw.BoxFit.contain,
                ),
              ),
            if (logo != null)
              pw.SizedBox(width: 12),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment:
                    pw.CrossAxisAlignment
                        .start,
                children: [
                  pw.Text(
                    'FARMER ACTIVITY STATEMENT',
                    style: pw.TextStyle(
                      color: green,
                      fontSize: 16,
                      fontWeight:
                          pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    pdfSafe(
                      profile.farmName
                              .trim()
                              .isEmpty
                          ? profile.farmerName
                          : profile.farmName,
                    ),
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight:
                          pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    'Generated ${_farmerStatementDate(DateTime.now())}',
                    style:
                        const pw.TextStyle(
                      fontSize: 7.5,
                      color:
                          PdfColors.grey600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        pw.SizedBox(height: 16),

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
                pdfSafe(
                  profile.farmerName,
                ),
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight:
                      pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                pdfSafe(
                  [
                    if (profile.parish
                        .trim()
                        .isNotEmpty)
                      profile.parish,
                    if (profile.phone
                        .trim()
                        .isNotEmpty)
                      profile.phone,
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
              'Supply reports',
              '${data.supplies.length}',
            ),
            pw.SizedBox(width: 7),
            metric(
              'Collections completed',
              '$completedCollections',
            ),
            pw.SizedBox(width: 7),
            metric(
              'Released payouts',
              formatJmd(released),
            ),
          ],
        ),

        pw.SizedBox(height: 18),
        sectionTitle(
          'SUPPLY HISTORY',
        ),
        pw.SizedBox(height: 6),
        table(
          headers: const [
            'Crop',
            'Expected',
            'Harvest date',
            'Status',
          ],
          rows: supplies
              .take(30)
              .map(
                (item) => [
                  item.cropName,
                  '${_farmerPartnerNumber(item.expectedQuantity ?? 0)} ${item.unit}',
                  _farmerStatementDate(
                    item.expectedHarvestDate,
                  ),
                  item.statusLabel,
                ],
              )
              .toList(),
        ),

        pw.SizedBox(height: 16),
        sectionTitle(
          'COLLECTION HISTORY',
        ),
        pw.SizedBox(height: 6),
        table(
          headers: const [
            'Date',
            'Produce',
            'Collected',
            'Status',
          ],
          rows: collections
              .take(30)
              .map(
                (item) => [
                  _farmerStatementDate(
                    item.collectionDate,
                  ),
                  item.productName,
                  '${_farmerPartnerNumber(item.collectedQuantity)} ${item.unit}',
                  _farmerStatementStatus(
                    item.stopStatus,
                  ),
                ],
              )
              .toList(),
        ),

        pw.SizedBox(height: 16),
        sectionTitle(
          'PAYOUT HISTORY',
        ),
        pw.SizedBox(height: 6),
        table(
          headers: const [
            'Date',
            'Produce',
            'Net amount',
            'Status',
          ],
          rows: payouts
              .take(30)
              .map(
                (item) => [
                  _farmerStatementDate(
                    item.createdAt,
                  ),
                  item.productName
                          .trim()
                          .isEmpty
                      ? 'Farmer payout'
                      : item.productName,
                  formatJmd(
                    item.netAmount,
                  ),
                  _farmerStatementStatus(
                    item.payoutStatus,
                  ),
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
            'It is not a bank statement, credit rating, tax certificate or guarantee of future sales.',
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

class _FarmerActivityStatementScreen
    extends StatefulWidget {
  final FarmerProfile profile;

  const _FarmerActivityStatementScreen({
    required this.profile,
  });

  @override
  State<_FarmerActivityStatementScreen>
      createState() =>
          _FarmerActivityStatementScreenState();
}

class _FarmerActivityStatementScreenState
    extends State<_FarmerActivityStatementScreen> {
  late Future<_FarmerTodaySnapshot> future;
  bool exporting = false;

  @override
  void initState() {
    super.initState();

    future = fetchFarmerTodaySnapshot(
      widget.profile,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      future = fetchFarmerTodaySnapshot(
        widget.profile,
      );
    });

    await future;
  }

  Future<void> _printOrSave(
    _FarmerTodaySnapshot data,
  ) async {
    if (exporting) return;

    setState(() {
      exporting = true;
    });

    try {
      final bytes =
          await _buildFarmerActivityStatementPdf(
        widget.profile,
        data,
      );

      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name:
            'HPJ_Farmer_Activity_Statement.pdf',
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
    _FarmerTodaySnapshot data,
  ) async {
    if (exporting) return;

    setState(() {
      exporting = true;
    });

    try {
      final bytes =
          await _buildFarmerActivityStatementPdf(
        widget.profile,
        data,
      );

      await Printing.sharePdf(
        bytes: bytes,
        filename:
            'HPJ_Farmer_Activity_Statement.pdf',
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
          'Activity Statement',
        ),
      ),
      body: FutureBuilder<_FarmerTodaySnapshot>(
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
                      'Your activity statement could not be loaded.',
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

          final released = data.payouts
              .where(
                (item) =>
                    item.payoutStatus
                        .trim()
                        .toLowerCase() ==
                    'released',
              )
              .fold<double>(
                0,
                (sum, item) =>
                    sum + item.netAmount,
              );

          final completedCollections =
              data.collections
                  .where(
                    (item) =>
                        item.stopStatus
                            .trim()
                            .toLowerCase() ==
                        'completed',
                  )
                  .length;

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
                        widget.profile.farmName
                                .trim()
                                .isEmpty
                            ? widget.profile
                                .farmerName
                            : widget.profile
                                .farmName,
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
                        'Your own HPJ supply, collection and payout record.',
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
                                _FarmerStatementMetric(
                              label:
                                  'Supply reports',
                              value:
                                  '${data.supplies.length}',
                            ),
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          Expanded(
                            child:
                                _FarmerStatementMetric(
                              label:
                                  'Collections',
                              value:
                                  '$completedCollections',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      _FarmerStatementMetric(
                        label:
                            'Released payouts',
                        value:
                            formatJmd(released),
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
                        'Useful for your own records, discussions with HPJ, and keeping a history of your marketplace activity.',
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
                    'This is an HPJ activity record, not a bank statement, credit rating, tax certificate or guarantee of future sales.',
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

class _FarmerStatementMetric
    extends StatelessWidget {
  final String label;
  final String value;

  const _FarmerStatementMetric({
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

class _FarmerProfileEditScreen
    extends StatefulWidget {
  final FarmerProfile profile;

  const _FarmerProfileEditScreen({
    required this.profile,
  });

  @override
  State<_FarmerProfileEditScreen>
      createState() =>
          _FarmerProfileEditScreenState();
}

class _FarmerProfileEditScreenState
    extends State<_FarmerProfileEditScreen> {
  late final TextEditingController farmNameController;
  late final TextEditingController farmerNameController;
  late final TextEditingController phoneController;
  late final TextEditingController parishController;
  late final TextEditingController addressController;
  late final TextEditingController bioController;
  late final TextEditingController payoutMethodController;
  late final TextEditingController payoutDetailsController;

  bool saving = false;

  @override
  void initState() {
    super.initState();

    final profile = widget.profile;

    farmNameController = TextEditingController(
      text: profile.farmName,
    );
    farmerNameController = TextEditingController(
      text: profile.farmerName,
    );
    phoneController = TextEditingController(
      text: profile.phone,
    );
    parishController = TextEditingController(
      text: profile.parish,
    );
    addressController = TextEditingController(
      text: profile.address,
    );
    bioController = TextEditingController(
      text: profile.bio,
    );
    payoutMethodController = TextEditingController(
      text: profile.payoutMethod,
    );
    payoutDetailsController = TextEditingController(
      text: profile.payoutDetails,
    );
  }

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

  Future<void> _save() async {
    if (saving) return;

    if (farmNameController.text.trim().isEmpty ||
        farmerNameController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty ||
        parishController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Farm name, farmer name, phone and parish are required.',
          ),
        ),
      );
      return;
    }

    setState(() {
      saving = true;
    });

    try {
      await saveFarmerProfile(
        farmName: farmNameController.text,
        farmerName: farmerNameController.text,
        phone: phoneController.text,
        parish: parishController.text,
        address: addressController.text,
        bio: bioController.text,
        payoutMethod:
            payoutMethodController.text,
        payoutDetails:
            payoutDetailsController.text,
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
            error.toString().replaceFirst(
                  'Exception: ',
                  '',
                ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: AppBar(
        title: const Text(
          'Edit Farmer Details',
        ),
      ),
      body: FarmPage(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            18,
            16,
            18,
            120,
          ),
          children: [
            const Text(
              'Keep these details current',
              style: TextStyle(
                color: FarmColors.ink,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'HPJ uses this information for contact, collection planning and farmer payments.',
              style: TextStyle(
                color: FarmColors.mutedText,
                fontSize: 10.8,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: farmNameController,
              enabled: !saving,
              decoration: const InputDecoration(
                labelText: 'Farm name',
              ),
            ),
            const SizedBox(height: 11),

            TextField(
              controller:
                  farmerNameController,
              enabled: !saving,
              decoration: const InputDecoration(
                labelText: 'Farmer name',
              ),
            ),
            const SizedBox(height: 11),

            TextField(
              controller: phoneController,
              enabled: !saving,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone',
              ),
            ),
            const SizedBox(height: 11),

            JamaicaParishDropdown(
              controller: parishController,
              label: 'Parish *',
              enabled: !saving,
              prefixIcon: Icons.map_outlined,
            ),
            const SizedBox(height: 11),

            TextField(
              controller: addressController,
              enabled: !saving,
              decoration: const InputDecoration(
                labelText: 'Farm address',
              ),
            ),
            const SizedBox(height: 11),

            TextField(
              controller: bioController,
              enabled: !saving,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Farm notes',
                hintText:
                    'Optional information about your farm',
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'Payment setup',
              style: TextStyle(
                color: FarmColors.ink,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),

            TextField(
              controller:
                  payoutMethodController,
              enabled: !saving,
              decoration: const InputDecoration(
                labelText: 'Payout method',
                hintText:
                    'e.g. Bank transfer',
              ),
            ),
            const SizedBox(height: 11),

            TextField(
              controller:
                  payoutDetailsController,
              enabled: !saving,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Payout details',
                helperText:
                    'Only provide the details HPJ needs to prepare your payment.',
              ),
            ),

            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity,
              child: PrimaryFarmButton(
                label: saving
                    ? 'Saving...'
                    : 'Save Details',
                onPressed:
                    saving ? null : _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FarmerWorkspaceSwitchCard
    extends StatelessWidget {
  const _FarmerWorkspaceSwitchCard();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: FarmColors.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  const OwnerWorkspaceSwitcherScreen(
                currentWorkspace: 'farmer',
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(18),
            border: Border.all(
              color: FarmColors.line,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(
                  0xFF183D30,
                ).withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Row(
            children: [
              Icon(
                Icons.apps_rounded,
                color: FarmColors.primary,
                size: 25,
              ),
              SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Switch workspace',
                      style: TextStyle(
                        color: FarmColors.ink,
                        fontSize: 13,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Move between your approved HPJ workspaces',
                      style: TextStyle(
                        color:
                            FarmColors.mutedText,
                        fontSize: 9.8,
                        fontWeight:
                            FontWeight.w600,
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


class _AdminNavigationIntent {
  final String section;
  final String? subSection;
  final String? filter;
  final String? recordId;

  const _AdminNavigationIntent({
    required this.section,
    this.subSection,
    this.filter,
    this.recordId,
  });
}

final ValueNotifier<_AdminNavigationIntent?> _adminNavigationIntent =
    ValueNotifier<_AdminNavigationIntent?>(null);

class _AdminSegmentSelector extends StatelessWidget {
  final String value;
  final List<(String, String, IconData)> options;
  final ValueChanged<String> onChanged;

  const _AdminSegmentSelector({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: Row(
        children: [
          for (final option in options) ...[
            ChoiceChip(
              selected: value == option.$1,
              avatar: Icon(option.$3, size: 17),
              label: Text(option.$2),
              onSelected: (_) => onChanged(option.$1),
            ),
            const SizedBox(width: 7),
          ],
        ],
      ),
    );
  }
}

class _AdminUnifiedOrdersTab extends StatefulWidget {
  final int refreshKey;
  final VoidCallback onChanged;

  const _AdminUnifiedOrdersTab({
    required this.refreshKey,
    required this.onChanged,
  });

  @override
  State<_AdminUnifiedOrdersTab> createState() =>
      _AdminUnifiedOrdersTabState();
}

class _AdminUnifiedOrdersTabState extends State<_AdminUnifiedOrdersTab> {
  String audience = 'wholesale';
  String customerFilter = 'all';
  String? customerOrderId;
  String? wholesaleFilter;
  String? wholesaleRequestId;

  @override
  void initState() {
    super.initState();
    _adminNavigationIntent.addListener(_handleIntent);
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleIntent());
  }

  @override
  void dispose() {
    _adminNavigationIntent.removeListener(_handleIntent);
    super.dispose();
  }

  void _handleIntent() {
    final intent = _adminNavigationIntent.value;
    if (!mounted || intent == null ||
        intent.section.trim().toLowerCase() != 'orders') {
      return;
    }

    final nextAudience = intent.subSection?.trim().toLowerCase();
    final nextFilter = intent.filter?.trim().toLowerCase();
    final nextRecordId = intent.recordId?.trim();

    setState(() {
      if (nextAudience == 'customer' || nextAudience == 'wholesale') {
        audience = nextAudience!;
      }
      if (audience == 'customer') {
        if (nextFilter != null && nextFilter.isNotEmpty) {
          customerFilter = nextFilter;
        }
        customerOrderId =
            nextRecordId == null || nextRecordId.isEmpty ? null : nextRecordId;
      }
      if (audience == 'wholesale') {
        wholesaleFilter = nextFilter == null || nextFilter.isEmpty
            ? null
            : nextFilter;
        wholesaleRequestId =
            nextRecordId == null || nextRecordId.isEmpty ? null : nextRecordId;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AdminSegmentSelector(
          value: audience,
          options: const [
            ('customer', 'Customer', Icons.person_outline_rounded),
            ('wholesale', 'Wholesale', Icons.storefront_outlined),
          ],
          onChanged: (value) => setState(() => audience = value),
        ),
        Expanded(
          child: IndexedStack(
            index: audience == 'customer' ? 0 : 1,
            children: [
              AdminOrdersTab(
                key: ValueKey(
                  'customer-orders-$customerFilter-${customerOrderId ?? 'all'}-${widget.refreshKey}',
                ),
                refreshKey: widget.refreshKey,
                onChanged: widget.onChanged,
                initialFilter: customerFilter,
                initialOrderId: customerOrderId,
              ),
              AdminWholesaleManagementTab(
                key: ValueKey(
                  'wholesale-orders-${wholesaleFilter ?? 'all'}-${wholesaleRequestId ?? 'all'}-${widget.refreshKey}',
                ),
                refreshKey: widget.refreshKey,
                onChanged: widget.onChanged,
                sections: const ['requests'],
                initialSection: 'requests',
                requestStatusFilter: wholesaleFilter,
                requestIdFilter: wholesaleRequestId,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AdminUnifiedFulfillmentTab extends StatefulWidget {
  final int refreshKey;
  final VoidCallback onChanged;

  const _AdminUnifiedFulfillmentTab({
    required this.refreshKey,
    required this.onChanged,
  });

  @override
  State<_AdminUnifiedFulfillmentTab> createState() =>
      _AdminUnifiedFulfillmentTabState();
}

class _AdminUnifiedFulfillmentTabState
    extends State<_AdminUnifiedFulfillmentTab> {
  String audience = 'wholesale';

  @override
  void initState() {
    super.initState();
    _adminNavigationIntent.addListener(_handleIntent);
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleIntent());
  }

  @override
  void dispose() {
    _adminNavigationIntent.removeListener(_handleIntent);
    super.dispose();
  }

  void _handleIntent() {
    final intent = _adminNavigationIntent.value;
    if (!mounted || intent == null ||
        intent.section.trim().toLowerCase() != 'fulfillment') {
      return;
    }

    final next = intent.subSection?.trim().toLowerCase();
    if (next == 'customer' || next == 'wholesale') {
      setState(() => audience = next!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AdminSegmentSelector(
          value: audience,
          options: const [
            ('customer', 'Customer', Icons.shopping_bag_outlined),
            ('wholesale', 'Wholesale', Icons.inventory_2_outlined),
          ],
          onChanged: (value) => setState(() => audience = value),
        ),
        Expanded(
          child: IndexedStack(
            index: audience == 'customer' ? 0 : 1,
            children: [
              AdminDeliveryTab(
                refreshKey: widget.refreshKey,
                onChanged: widget.onChanged,
              ),
              AdminWholesaleManagementTab(
                key: ValueKey('wholesale-fulfillment-${widget.refreshKey}'),
                refreshKey: widget.refreshKey,
                onChanged: widget.onChanged,
                sections: const ['fulfillment', 'dispatch'],
                initialSection: 'fulfillment',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AdminFarmerSupplyQueue extends StatefulWidget {
  final int refreshKey;
  final VoidCallback onOpenMatching;

  const _AdminFarmerSupplyQueue({
    required this.refreshKey,
    required this.onOpenMatching,
  });

  @override
  State<_AdminFarmerSupplyQueue> createState() =>
      _AdminFarmerSupplyQueueState();
}

class _AdminFarmerSupplyQueueState extends State<_AdminFarmerSupplyQueue> {
  late Future<List<Object>> future;

  @override
  void initState() {
    super.initState();
    future = _load();
  }

  @override
  void didUpdateWidget(covariant _AdminFarmerSupplyQueue oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshKey != widget.refreshKey) {
      future = _load();
    }
  }

  Future<List<Object>> _load() => Future.wait<Object>([
        fetchAdminFarmerSupplyForecasts(),
        fetchFarmerProfiles(),
      ]);

  String _qty(FarmerSupplyForecast supply) {
    final value = supply.harvestedQuantity ??
        supply.expectedQuantity ??
        supply.quantityGrowing ??
        0;
    final number = value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
    return '$number ${supply.unit}';
  }

  String _date(DateTime? value) {
    if (value == null) return 'Harvest date not set';
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${value.day} ${months[value.month - 1]}';
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() => future = next);
    await next;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Object>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text(friendlyAppError(snapshot.error!)));
        }

        final data = snapshot.data ?? const <Object>[];
        final supplies = data.isEmpty
            ? <FarmerSupplyForecast>[]
            : data[0] as List<FarmerSupplyForecast>;
        final farmers = data.length < 2
            ? <FarmerProfile>[]
            : data[1] as List<FarmerProfile>;
        final farmerMap = <String, FarmerProfile>{
          for (final farmer in farmers) farmer.id: farmer,
        };
        final queue = supplies.where((supply) {
          final potential = supply.harvestedQuantity ??
              supply.expectedQuantity ??
              supply.quantityGrowing ??
              0;
          return supply.isActive && !supply.isHpjConfirmed && potential > 0;
        }).toList()
          ..sort((a, b) {
            final ad = a.expectedHarvestDate ?? DateTime(2999);
            final bd = b.expectedHarvestDate ?? DateTime(2999);
            return ad.compareTo(bd);
          });

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 100),
            children: [
              const Header(
                title: 'Farmer Supply',
                subtitle: 'Review reported supply before it can be reserved',
              ),
              const SizedBox(height: 12),
              if (queue.isEmpty)
                const FarmEmptyState(
                  icon: Icons.verified_outlined,
                  title: 'No supply waiting for review',
                  message: 'New farmer crop reports will appear here when HPJ verification is needed.',
                )
              else ...[
                FarmCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: FarmColors.primary),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          '${queue.length} report${queue.length == 1 ? '' : 's'} need review. Verification is completed against an active requirement in Needs Supply.',
                          style: const TextStyle(
                            color: FarmColors.mutedText,
                            fontSize: 10.5,
                            height: 1.35,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                ...queue.map((supply) {
                  final farmer = farmerMap[supply.farmerId];
                  final name = farmer?.farmName.trim().isNotEmpty == true
                      ? farmer!.farmName
                      : farmer?.farmerName ?? 'Farmer';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: FarmCard(
                      padding: const EdgeInsets.all(13),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              HpjProductThumb(
                                productName: supply.cropName,
                                size: 46,
                                radius: 12,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      supply.cropName,
                                      style: const TextStyle(
                                        color: FarmColors.ink,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$name • ${farmer?.parish ?? ''}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: FarmColors.mutedText,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                _qty(supply),
                                style: const TextStyle(
                                  color: FarmColors.primary,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 9),
                          Text(
                            '${supply.statusLabel} • ${_date(supply.expectedHarvestDate)}',
                            style: const TextStyle(
                              color: FarmColors.mutedText,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 9),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: widget.onOpenMatching,
                              icon: const Icon(Icons.account_tree_outlined, size: 17),
                              label: const Text('Review Against Demand'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _AdminProcurementOperationsTab extends StatefulWidget {
  final int refreshKey;
  final VoidCallback onChanged;

  const _AdminProcurementOperationsTab({
    required this.refreshKey,
    required this.onChanged,
  });

  @override
  State<_AdminProcurementOperationsTab> createState() =>
      _AdminProcurementOperationsTabState();
}

class _AdminProcurementOperationsTabState
    extends State<_AdminProcurementOperationsTab> {
  String section = 'needs_supply';
  String? focusFilter;
  String? focusRecordId;

  @override
  void initState() {
    super.initState();
    _adminNavigationIntent.addListener(_handleIntent);
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleIntent());
  }

  @override
  void dispose() {
    _adminNavigationIntent.removeListener(_handleIntent);
    super.dispose();
  }

  void _handleIntent() {
    final intent = _adminNavigationIntent.value;
    if (!mounted || intent == null ||
        intent.section.trim().toLowerCase() != 'procurement') {
      return;
    }
    final next = intent.subSection?.trim().toLowerCase();
    if (const {'needs_supply','farmer_supply','collections','receiving'}
        .contains(next)) {
      setState(() {
        section = next!;
        focusFilter = intent.filter?.trim().toLowerCase();
        focusRecordId = intent.recordId?.trim();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AdminSegmentSelector(
          value: section,
          options: const [
            ('needs_supply', 'Needs Supply', Icons.account_tree_outlined),
            ('farmer_supply', 'Farmer Supply', Icons.agriculture_outlined),
            ('collections', 'Collections', Icons.local_shipping_outlined),
            ('receiving', 'Receiving', Icons.warehouse_outlined),
          ],
          onChanged: (value) => setState(() {
            section = value;
            focusFilter = null;
            focusRecordId = null;
          }),
        ),
        Expanded(
          child: switch (section) {
            'farmer_supply' => _AdminFarmerSupplyQueue(
                refreshKey: widget.refreshKey,
                onOpenMatching: () => setState(() => section = 'needs_supply'),
              ),
            'collections' => AdminWholesaleManagementTab(
                key: ValueKey('procurement-collections-${widget.refreshKey}'),
                refreshKey: widget.refreshKey,
                onChanged: widget.onChanged,
                sections: const ['receiving'],
                initialSection: 'receiving',
                receivingMode: 'collections',
                receivingFilter: focusFilter ?? 'all',
              ),
            'receiving' => AdminWholesaleManagementTab(
                key: ValueKey('procurement-receiving-${widget.refreshKey}'),
                refreshKey: widget.refreshKey,
                onChanged: widget.onChanged,
                sections: const ['receiving'],
                initialSection: 'receiving',
                receivingMode: 'receiving',
                receivingFilter: focusFilter ?? 'all',
              ),
            _ => AdminWholesaleManagementTab(
                key: ValueKey(
                  'procurement-needs-${widget.refreshKey}-${focusRecordId ?? 'all'}',
                ),
                refreshKey: widget.refreshKey,
                onChanged: widget.onChanged,
                sections: const ['procurement'],
                initialSection: 'procurement',
                demandIdFilter: focusRecordId,
              ),
          },
        ),
      ],
    );
  }
}

class _AdminTodayOperationsSnapshot {
  final int customerPendingOrders;
  final int customerReadyOrders;
  final int wholesalePendingOrders;
  final int procurementNeedsSupply;
  final int farmerSupplyNeedsVerification;
  final int collectionsToday;
  final int receivingIssues;
  final int wholesaleReadyForDispatch;

  const _AdminTodayOperationsSnapshot({
    required this.customerPendingOrders,
    required this.customerReadyOrders,
    required this.wholesalePendingOrders,
    required this.procurementNeedsSupply,
    required this.farmerSupplyNeedsVerification,
    required this.collectionsToday,
    required this.receivingIssues,
    required this.wholesaleReadyForDispatch,
  });
}

Future<_AdminTodayOperationsSnapshot> _fetchAdminTodayOperations() async {
  Future<List<T>> safe<T>(Future<List<T>> future) async {
    try {
      return await future;
    } catch (error) {
      farmDebugLog('Admin Today data unavailable: $error');
      return <T>[];
    }
  }

  final results = await Future.wait<dynamic>([
    safe<AdminOrder>(fetchAdminOrders()),
    safe<WholesaleOrderRequest>(fetchAdminWholesaleRequests()),
    safe<WholesaleDemandForecast>(fetchAdminWholesaleDemandForecasts()),
    safe<FarmerSupplyForecast>(fetchAdminFarmerSupplyForecasts()),
    safe<WholesaleReceivingBatch>(fetchWholesaleReceivingBatches()),
    safe<WholesaleFulfillment>(fetchAdminWholesaleFulfillments()),
  ]);

  final customerOrders = results[0] as List<AdminOrder>;
  final wholesaleOrders = results[1] as List<WholesaleOrderRequest>;
  final demands = results[2] as List<WholesaleDemandForecast>;
  final supplies = results[3] as List<FarmerSupplyForecast>;
  final batches = results[4] as List<WholesaleReceivingBatch>;
  final fulfillments = results[5] as List<WholesaleFulfillment>;

  final now = DateTime.now();
  bool isToday(DateTime? value) {
    if (value == null) return false;
    final local = value.toLocal();
    return local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
  }

  int potential(FarmerSupplyForecast supply) {
    final value = supply.harvestedQuantity ??
        supply.expectedQuantity ??
        supply.quantityGrowing ??
        0;
    return value > 0 ? 1 : 0;
  }

  return _AdminTodayOperationsSnapshot(
    customerPendingOrders:
        customerOrders.where((order) => order.status == 'pending').length,
    customerReadyOrders:
        customerOrders.where((order) => order.status == 'ready').length,
    wholesalePendingOrders:
        wholesaleOrders.where((order) => order.status == 'pending').length,
    procurementNeedsSupply: demands.where((demand) {
      return demand.isActive && !demand.isReserved;
    }).length,
    farmerSupplyNeedsVerification: supplies.where((supply) {
      return supply.isActive && !supply.isHpjConfirmed && potential(supply) == 1;
    }).length,
    collectionsToday: batches.where((batch) {
      return isToday(batch.collectionDate) &&
          (batch.isPlanned || batch.isCollectionScheduled || batch.isCollected);
    }).length,
    receivingIssues: batches.where((batch) {
      return (batch.isReceived || batch.isInspected) &&
          (batch.rejectedQuantity > 0 || batch.remainingToReceive > 0.001);
    }).length,
    wholesaleReadyForDispatch:
        fulfillments.where((item) => item.isReadyForDispatch).length,
  );
}

class _AdminTodayActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final int count;
  final Color color;
  final VoidCallback onTap;

  const _AdminTodayActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.count,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: FarmCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color),
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
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: FarmColors.mutedText,
                        fontSize: 10.5,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                constraints: const BoxConstraints(minWidth: 34),
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: count > 0 ? color : FarmColors.cardSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: count > 0 ? Colors.white : FarmColors.mutedText,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 5),
              const Icon(Icons.chevron_right_rounded, color: FarmColors.mutedText),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminOperationsTodayTab extends StatefulWidget {
  final int refreshKey;

  const _AdminOperationsTodayTab({required this.refreshKey});

  @override
  State<_AdminOperationsTodayTab> createState() =>
      _AdminOperationsTodayTabState();
}

class _AdminOperationsTodayTabState extends State<_AdminOperationsTodayTab> {
  late Future<_AdminTodayOperationsSnapshot> future;

  @override
  void initState() {
    super.initState();
    future = _fetchAdminTodayOperations();
  }

  @override
  void didUpdateWidget(covariant _AdminOperationsTodayTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshKey != widget.refreshKey) {
      future = _fetchAdminTodayOperations();
    }
  }

  Future<void> _reload() async {
    final next = _fetchAdminTodayOperations();
    setState(() => future = next);
    await next;
  }

  void _open(String section, {String? subSection, String? filter}) {
    final scope = _AdminNavigationScope.maybeOf(context);
    if (scope == null) return;
    scope.onNavigate(
      _AdminNavigationIntent(
        section: section,
        subSection: subSection,
        filter: filter,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _reload,
      child: FutureBuilder<_AdminTodayOperationsSnapshot>(
        future: future,
        builder: (context, snapshot) {
          final data = snapshot.data ??
              const _AdminTodayOperationsSnapshot(
                customerPendingOrders: 0,
                customerReadyOrders: 0,
                wholesalePendingOrders: 0,
                procurementNeedsSupply: 0,
                farmerSupplyNeedsVerification: 0,
                collectionsToday: 0,
                receivingIssues: 0,
                wholesaleReadyForDispatch: 0,
              );

          final attention = <Widget>[
            if (data.wholesalePendingOrders > 0)
              _AdminTodayActionCard(
                icon: Icons.storefront_outlined,
                title: 'Wholesale orders to review',
                subtitle: 'Open new business orders and approve or update them.',
                count: data.wholesalePendingOrders,
                color: FarmColors.warning,
                onTap: () => _open('Orders', subSection: 'wholesale', filter: 'pending'),
              ),
            if (data.procurementNeedsSupply > 0)
              _AdminTodayActionCard(
                icon: Icons.account_tree_outlined,
                title: 'Procurement needs supply',
                subtitle: 'Review shortages and secure the remaining farmer quantity.',
                count: data.procurementNeedsSupply,
                color: FarmColors.danger,
                onTap: () => _open('Procurement', subSection: 'needs_supply'),
              ),
            if (data.farmerSupplyNeedsVerification > 0)
              _AdminTodayActionCard(
                icon: Icons.verified_outlined,
                title: 'Farmer supply to review',
                subtitle: 'Check reported quantities before HPJ uses them for matching.',
                count: data.farmerSupplyNeedsVerification,
                color: FarmColors.warning,
                onTap: () => _open('Procurement', subSection: 'farmer_supply'),
              ),
            if (data.receivingIssues > 0)
              _AdminTodayActionCard(
                icon: Icons.report_problem_outlined,
                title: 'Receiving issues',
                subtitle: 'Inspect short or rejected quantities at warehouse receiving.',
                count: data.receivingIssues,
                color: FarmColors.danger,
                onTap: () => _open('Procurement', subSection: 'receiving', filter: 'issues'),
              ),
            if (data.customerPendingOrders > 0)
              _AdminTodayActionCard(
                icon: Icons.person_outline_rounded,
                title: 'Customer orders to review',
                subtitle: 'Open pending customer orders.',
                count: data.customerPendingOrders,
                color: FarmColors.warning,
                onTap: () => _open('Orders', subSection: 'customer', filter: 'pending'),
              ),
          ];

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
            children: [
              const Header(
                title: 'Today',
                subtitle: 'Open the work that needs attention now',
                // Unread notifications are attention, not a blocking error.
                notificationBadgeColor: FarmColors.warning,
              ),
              const SizedBox(height: 14),
              Text(
                attention.isEmpty ? 'No urgent actions' : 'Needs attention',
                style: const TextStyle(
                  color: FarmColors.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              if (attention.isEmpty)
                const FarmCard(
                  padding: EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline_rounded, color: FarmColors.success),
                      SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          'No blocking operational items are showing right now.',
                          style: TextStyle(
                            color: FarmColors.mutedText,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...attention,
              const SizedBox(height: 18),
              const Text(
                'Today’s operations',
                style: TextStyle(
                  color: FarmColors.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              AdminSummaryGrid(
                children: [
                  GestureDetector(
                    onTap: () => _open('Procurement', subSection: 'collections', filter: 'today'),
                    child: _AdminTodayMetricCard(
                      label: 'Collections',
                      value: '${data.collectionsToday}',
                      icon: Icons.local_shipping_outlined,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _open('Fulfillment', subSection: 'wholesale'),
                    child: _AdminTodayMetricCard(
                      label: 'Wholesale dispatch',
                      value: '${data.wholesaleReadyForDispatch}',
                      icon: Icons.inventory_2_outlined,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _open('Fulfillment', subSection: 'customer'),
                    child: _AdminTodayMetricCard(
                      label: 'Customer ready',
                      value: '${data.customerReadyOrders}',
                      icon: Icons.shopping_bag_outlined,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _open('Orders', subSection: 'wholesale'),
                    child: _AdminTodayMetricCard(
                      label: 'Wholesale new',
                      value: '${data.wholesalePendingOrders}',
                      icon: Icons.storefront_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'Quick actions',
                style: TextStyle(
                  color: FarmColors.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              FarmCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.add_box_outlined, color: FarmColors.primary),
                      title: const Text('Products'),
                      subtitle: const Text('Add, edit or restock a product'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _open('Products'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.play_circle_outline_rounded, color: FarmColors.primary),
                      title: const Text('Fresh Reels'),
                      subtitle: const Text('Review submissions or publish HPJ content'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _open('Reels'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.agriculture_outlined, color: FarmColors.primary),
                      title: const Text('Farmer partners'),
                      subtitle: const Text('Review farmer profiles and approvals'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _open('Farmers'),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.business_outlined, color: FarmColors.primary),
                      title: const Text('Business setup'),
                      subtitle: const Text('Applications, access, pricing and account controls'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => _open('Business Setup'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AdminTodayMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _AdminTodayMetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return FarmCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: FarmColors.primary, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: FarmColors.ink,
              fontSize: 21,
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
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
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
  _AdminNavigationIntent? initialIntent,
}) {
  final role = normalizeStaffRole(staffRole);
  final ownerAccess = role.isEmpty || role == 'owner';
  final managerAccess = role == 'manager';

  _AdminTabSpec dashboard() => _AdminTabSpec(
        tab: const Tab(
          icon: Icon(Icons.dashboard_customize_outlined),
          text: 'Dashboard',
        ),
        child: _AdminOperationsTodayTab(refreshKey: refreshKey),
      );

  _AdminTabSpec orders() => _AdminTabSpec(
        tab: const Tab(
          icon: Icon(Icons.receipt_long),
          text: 'Orders',
        ),
        child: _AdminUnifiedOrdersTab(
          refreshKey: refreshKey,
          onChanged: onChanged,
        ),
      );

  _AdminTabSpec fulfillment() => _AdminTabSpec(
        tab: const Tab(
          icon: Icon(Icons.local_shipping_outlined),
          text: 'Fulfillment',
        ),
        child: _AdminUnifiedFulfillmentTab(
          refreshKey: refreshKey,
          onChanged: onChanged,
        ),
      );
  _AdminTabSpec drivers() => _AdminTabSpec(
        tab: const Tab(
          icon: Icon(Icons.delivery_dining_outlined),
          text: 'Drivers',
        ),
        child: AdminDriverManagementTab(
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
          initialProductId:
              initialIntent?.section.trim().toLowerCase() == 'products'
                  ? initialIntent?.recordId
                  : null,
        ),
      );
  _AdminTabSpec procurement() => _AdminTabSpec(
        tab: const Tab(
          icon: Icon(Icons.account_tree_outlined),
          text: 'Procurement',
        ),
        child: _AdminProcurementOperationsTab(
          refreshKey: refreshKey,
          onChanged: onChanged,
        ),
      );

  _AdminTabSpec warehouse() => const _AdminTabSpec(
        tab: Tab(
          icon: Icon(Icons.warehouse_outlined),
          text: 'Warehouse',
        ),
        child: WarehouseOperationsPanel(),
      );

  _AdminTabSpec wholesale() => _AdminTabSpec(
        tab: const Tab(
          icon: Icon(Icons.storefront_outlined),
          text: 'Business Setup',
        ),
        child: AdminWholesaleManagementTab(
          refreshKey: refreshKey,
          onChanged: onChanged,
          sections: const [
            'applications',
            'access',
            'pricing',
            'recurring',
            'invoices',
            'finance',
          ],
          initialSection:
              initialIntent?.section.trim().toLowerCase() == 'business setup'
                  ? (initialIntent?.subSection ?? 'applications')
                  : 'applications',
          businessAccountIdFilter:
              initialIntent?.section.trim().toLowerCase() == 'business setup' &&
                      initialIntent?.subSection?.trim().toLowerCase() ==
                          'applications'
                  ? initialIntent?.recordId
                  : null,
          invoiceIdFilter:
              initialIntent?.section.trim().toLowerCase() == 'business setup' &&
                      initialIntent?.subSection?.trim().toLowerCase() ==
                          'invoices'
                  ? initialIntent?.recordId
                  : null,
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

  _AdminTabSpec feedUpdates() => _AdminTabSpec(
        tab: const Tab(
          icon: Icon(Icons.dynamic_feed_outlined),
          text: 'Feed',
        ),
        child: AdminAgricultureFeedTab(
          refreshKey: refreshKey,
          onChanged: onChanged,
        ),
      );

  _AdminTabSpec reels() => _AdminTabSpec(
        tab: const Tab(
          icon: Icon(Icons.play_circle_outline_rounded),
          text: 'Reels',
        ),
        child: AdminFreshReelsTab(
          refreshKey: refreshKey,
          onChanged: onChanged,
        ),
      );

  _AdminTabSpec tutorials() => _AdminTabSpec(
        tab: const Tab(
          icon: Icon(Icons.video_library_outlined),
          text: 'Tutorials',
        ),
        child: AdminHelpTutorialsTab(
          refreshKey: refreshKey,
          onChanged: onChanged,
        ),
      );

  _AdminTabSpec support() => _AdminTabSpec(
        tab: const Tab(
          icon: Icon(Icons.chat_bubble_outline_rounded),
          text: 'Messages',
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
          initialFarmerId:
              initialIntent?.section.trim().toLowerCase() == 'farmers'
                  ? initialIntent?.recordId
                  : null,
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

  _AdminTabSpec impact() => _AdminTabSpec(
        tab: const Tab(
          icon: Icon(Icons.hub_outlined),
          text: 'Impact',
        ),
        child: AdminNetworkImpactTab(
          refreshKey: refreshKey,
        ),
      );

  _AdminTabSpec reviews() => _AdminTabSpec(
        tab: const Tab(
          icon: Icon(Icons.rate_review_outlined),
          text: 'Reviews',
        ),
        child: AdminReviewsTab(
          refreshKey: refreshKey,
          initialProductId:
              initialIntent?.section.trim().toLowerCase() == 'reviews'
                  ? initialIntent?.recordId
                  : null,
        ),
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
      procurement(),
      fulfillment(),
      products(),
      wholesale(),
      warehouse(),
      drivers(),
      farmers(),
      payouts(),
      analytics(),
      impact(),
      reports(),
      hero(),
      feedUpdates(),
      reels(),
      tutorials(),
      support(),
      reviews(),
      coupons(),
      staff(),
    ];
  }

  if (managerAccess) {
    return [
      dashboard(),
      orders(),
      procurement(),
      fulfillment(),
      products(),
      wholesale(),
      warehouse(),
      drivers(),
      farmers(),
      analytics(),
      impact(),
      reports(),
      feedUpdates(),
      reels(),
      tutorials(),
      support(),
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
        drivers(),
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

class _AdminNavigationScope
    extends InheritedWidget {
  final ValueChanged<_AdminNavigationIntent> onNavigate;

  const _AdminNavigationScope({
    required this.onNavigate,
    required super.child,
  });

  static _AdminNavigationScope? maybeOf(
    BuildContext context,
  ) {
    return context.dependOnInheritedWidgetOfExactType<
        _AdminNavigationScope>();
  }

  @override
  bool updateShouldNotify(
    _AdminNavigationScope oldWidget,
  ) {
    return onNavigate != oldWidget.onNavigate;
  }
}

class _AdminFloatingMessagesButton extends StatefulWidget {
  final int refreshKey;
  final VoidCallback onTap;

  const _AdminFloatingMessagesButton({
    required this.refreshKey,
    required this.onTap,
  });

  @override
  State<_AdminFloatingMessagesButton> createState() =>
      _AdminFloatingMessagesButtonState();
}

class _AdminFloatingMessagesButtonState
    extends State<_AdminFloatingMessagesButton> {
  late Future<int> _unreadFuture;

  @override
  void initState() {
    super.initState();
    _unreadFuture = _loadUnread();
    _scheduleUnreadRefresh();
  }

  @override
  void didUpdateWidget(
    covariant _AdminFloatingMessagesButton oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.refreshKey != widget.refreshKey) {
      _reloadUnread();
    }
  }

  Future<int> _loadUnread() async {
    try {
      final tickets = await fetchAdminSupportTickets();

      return tickets
          .where(
            (ticket) => ticket.hasUnreadForStaff,
          )
          .length;
    } catch (error) {
      farmDebugLog(
        'Admin Messages unread count unavailable: $error',
      );
      return 0;
    }
  }

  void _reloadUnread() {
    if (!mounted) return;

    setState(() {
      _unreadFuture = _loadUnread();
    });
  }

  void _scheduleUnreadRefresh() {
    Future<void>.delayed(
      const Duration(seconds: 20),
      () async {
        if (!mounted) return;

        _reloadUnread();
        _scheduleUnreadRefresh();
      },
    );
  }

  String _badgeLabel(int unread) {
    if (unread > 99) return '99+';
    return '$unread';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: _unreadFuture,
      builder: (context, snapshot) {
        final unread = snapshot.data ?? 0;

        // Scaffold's floating-action slot can briefly expose loose
        // constraints during Flutter Web/full-page reloads. Give the custom
        // HPJ Messages pill a hard finite box so no RenderFlex in this widget
        // can ever receive an infinite width or height.
        return SizedBox(
          width: 112,
          height: 42,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(18),
              child: Ink(
                decoration: BoxDecoration(
                  color: FarmColors.green,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                        if (unread > 0)
                          Positioned(
                            right: -9,
                            top: -8,
                            child: Container(
                              constraints:
                                  const BoxConstraints(
                                minWidth: 18,
                                minHeight: 18,
                              ),
                              padding:
                                  const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: FarmColors.warning,
                                borderRadius:
                                    BorderRadius.circular(999),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                _badgeLabel(unread),
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
                    const SizedBox(width: 8),
                    Text(
                      'Messages',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        height: 1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        );
      },
    );
  }
}

class _AdminBottomNavigationShell
    extends StatelessWidget {
  final String staffRole;
  final String roleLabel;
  final List<_AdminTabSpec> tabs;
  final int refreshKey;
  final VoidCallback onRefresh;
  final VoidCallback onExit;
  final _AdminNavigationIntent? initialIntent;

  const _AdminBottomNavigationShell({
    required this.staffRole,
    required this.roleLabel,
    required this.tabs,
    required this.refreshKey,
    required this.onRefresh,
    required this.onExit,
    this.initialIntent,
  });

  String _canonicalAdminSectionLabel(String value) {
    final normalized = value.trim().toLowerCase();

    // Repair 027 renamed the visible Admin destination to Messages, but older
    // notifications/dashboard intents still use the internal name "Inbox".
    if (normalized == 'inbox') return 'messages';

    return normalized;
  }

  int _indexForLabel(String label) {
    final requested =
        _canonicalAdminSectionLabel(label);

    return tabs.indexWhere(
      (spec) =>
          _canonicalAdminSectionLabel(
            spec.tab.text ?? '',
          ) ==
          requested,
    );
  }

  IconData _iconFor(
    String label, {
    required bool selected,
  }) {
    switch (label) {
      case 'Dashboard':
        return selected
            ? Icons.home_rounded
            : Icons.home_outlined;
      case 'Orders':
        return selected
            ? Icons.receipt_long_rounded
            : Icons.receipt_long_outlined;
      case 'Fulfillment':
        return selected
            ? Icons.local_shipping_rounded
            : Icons.local_shipping_outlined;
      case 'Procurement':
        return selected
            ? Icons.account_tree_rounded
            : Icons.account_tree_outlined;
      case 'Products':
        return selected
            ? Icons.inventory_2_rounded
            : Icons.inventory_2_outlined;
      case 'Drivers':
        return selected
            ? Icons.delivery_dining
            : Icons.delivery_dining_outlined;
      case 'Reports':
        return selected
            ? Icons.bar_chart_rounded
            : Icons.bar_chart_outlined;
      case 'Inbox':
      case 'Messages':
        return selected
            ? Icons.chat_bubble_rounded
            : Icons.chat_bubble_outline_rounded;
      default:
        return selected
            ? Icons.grid_view_rounded
            : Icons.grid_view_outlined;
    }
  }

  List<int> _primaryIndices() {
    final role = normalizeStaffRole(staffRole);

    if (role.isEmpty ||
        role == 'owner' ||
        role == 'manager') {
      return <String>[
        'Dashboard',
        'Orders',
        'Procurement',
        'Fulfillment',
      ]
          .map(_indexForLabel)
          .where((index) => index >= 0)
          .toList();
    }

    return List<int>.generate(
      tabs.length > 4 ? 4 : tabs.length,
      (index) => index,
    );
  }

  Future<void> _openMore(
    BuildContext context,
    TabController controller,
    List<int> primary,
  ) async {
    final primarySet = primary.toSet();

    final secondary = <MapEntry<int, _AdminTabSpec>>[
      for (var index = 0;
          index < tabs.length;
          index++)
        if (!primarySet.contains(index))
          MapEntry(index, tabs[index]),
    ];

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _AdminMoreScreen(
          roleLabel: roleLabel,
          sections: secondary,
          onSelect: (index) {
            Navigator.of(context).pop();
            controller.animateTo(index);
          },
        ),
      ),
    );
  }

  void _navigateByIntent(
    BuildContext context,
    TabController controller,
    _AdminNavigationIntent intent,
  ) {
    final index = _indexForLabel(intent.section);

    if (index < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${intent.section} is not available for this staff role.',
          ),
        ),
      );
      return;
    }

    _adminNavigationIntent.value = intent;
    controller.animateTo(index);
  }

  @override
  Widget build(BuildContext context) {
    if (tabs.isEmpty) {
      return const FarmEmptyState(
        icon: Icons.lock_outline,
        title: 'No staff tools available',
        message:
            'Your current staff role has no assigned admin tools.',
      );
    }

    final primary = _primaryIndices();
    final requestedInitialIndex = initialIntent == null
        ? -1
        : _indexForLabel(initialIntent!.section);
    final initialIndex = requestedInitialIndex < 0 ? 0 : requestedInitialIndex;

    return DefaultTabController(
      length: tabs.length,
      initialIndex: initialIndex,
      child: Builder(
        builder: (context) {
          final controller =
              DefaultTabController.of(context);

          return AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              final actualIndex =
                  controller.index
                      .clamp(
                        0,
                        tabs.length - 1,
                      )
                      .toInt();

              final dashboardIndex = _indexForLabel('Dashboard');
              final workspaceRootIndex = dashboardIndex >= 0
                  ? dashboardIndex
                  : (primary.isNotEmpty ? primary.first : 0);

              final primarySelected =
                  primary.indexOf(actualIndex);

              final hasMore =
                  primary.length < tabs.length;

              final destinations =
                  <FarmBottomOption>[
                for (final index in primary)
                  FarmBottomOption(
                    icon: Icon(
                      _iconFor(
                        tabs[index].tab.text ??
                            'Section',
                        selected: false,
                      ),
                      size: 27,
                    ),
                    selectedIcon: Icon(
                      _iconFor(
                        tabs[index].tab.text ??
                            'Section',
                        selected: true,
                      ),
                      size: 27,
                    ),
                    label:
                        (tabs[index].tab.text ??
                                    'Section') ==
                                'Dashboard'
                            ? 'Today'
                            : (tabs[index].tab.text ??
                                'Section'),
                  ),
                if (hasMore)
                  const FarmBottomOption(
                    icon: Icon(
                      Icons.more_horiz_rounded,
                      size: 27,
                    ),
                    selectedIcon: Icon(
                      Icons.more_horiz_rounded,
                      size: 27,
                    ),
                    label: 'More',
                  ),
              ];

              final safeBottomIndex =
                  primarySelected >= 0
                      ? primarySelected
                      : hasMore
                          ? primary.length
                          : 0;

              final rawCurrentTitle =
                  tabs[actualIndex].tab.text ??
                      'Operations';

              final currentTitle =
                  rawCurrentTitle == 'Dashboard'
                      ? 'Today'
                      : rawCurrentTitle;

              final messagesIndex =
                  _indexForLabel('Messages');

              final showMessagesButton =
                  messagesIndex >= 0 &&
                  actualIndex != messagesIndex;

              return _AdminNavigationScope(
                onNavigate: (intent) =>
                    _navigateByIntent(
                  context,
                  controller,
                  intent,
                ),
                child: PopScope(
                  canPop: false,
                  onPopInvokedWithResult: (didPop, result) {
                    if (didPop) return;
                    if (actualIndex != workspaceRootIndex) {
                      controller.animateTo(workspaceRootIndex);
                    }
                    // The staff workspace is a root workspace. Switching to
                    // Customer/Farmer/Wholesale is explicit via Switch Workspace.
                  },
                  child: Scaffold(
                  backgroundColor:
                      FarmColors.background,
                  appBar: AppBar(
                    automaticallyImplyLeading: false,
                    leading: actualIndex == workspaceRootIndex
                        ? null
                        : IconButton(
                            tooltip: 'Back to $roleLabel',
                            onPressed: () => controller.animateTo(
                              workspaceRootIndex,
                            ),
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                            ),
                          ),
                    title: Text(
                      '$roleLabel • $currentTitle',
                    ),
                    actions: [
                      IconButton(
                        tooltip:
                            'Switch Workspace',
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  const OwnerWorkspaceSwitcherScreen(
                                currentWorkspace:
                                    'staff',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.apps_rounded,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Refresh',
                        onPressed: onRefresh,
                        icon: const Icon(
                          Icons.refresh_rounded,
                        ),
                      ),
                    ],
                  ),
                  body: IndexedStack(
                    index: actualIndex,
                    children: [
                      for (final tab in tabs)
                        tab.child,
                    ],
                  ),
                  floatingActionButton:
                      showMessagesButton
                          ? _AdminFloatingMessagesButton(
                              refreshKey: refreshKey,
                              onTap: () {
                                controller.animateTo(
                                  messagesIndex,
                                );
                              },
                            )
                          : null,
                  floatingActionButtonLocation:
                      FloatingActionButtonLocation.endFloat,
                  bottomNavigationBar:
                      FarmBottomOptionsBar(
                    selectedIndex:
                        safeBottomIndex,
                    destinations:
                        destinations,
                    onSelected:
                        (bottomIndex) {
                      if (hasMore &&
                          bottomIndex ==
                              primary.length) {
                        _openMore(
                          context,
                          controller,
                          primary,
                        );
                        return;
                      }

                      if (bottomIndex >= 0 &&
                          bottomIndex <
                              primary.length) {
                        controller.animateTo(
                          primary[bottomIndex],
                        );
                      }
                    },
                  ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _AdminMoreScreen extends StatelessWidget {
  final String roleLabel;
  final List<MapEntry<int, _AdminTabSpec>> sections;
  final ValueChanged<int> onSelect;

  const _AdminMoreScreen({
    required this.roleLabel,
    required this.sections,
    required this.onSelect,
  });

  String _groupFor(String label) {
    switch (label) {
      case 'Products':
      case 'Hero':
      case 'Feed':
      case 'Reels':
      case 'Coupons':
        return 'Marketplace & Content';
      case 'Farmers':
      case 'Business Setup':
      case 'Reviews':
        return 'Partners';
      case 'Warehouse':
      case 'Drivers':
        return 'Logistics';
      case 'Payouts':
      case 'Analytics':
      case 'Impact':
      case 'Reports':
        return 'Finance & Insights';
      case 'Inbox':
      case 'Messages':
      case 'Staff':
        return 'Management';
      default:
        return 'Other Tools';
    }
  }

  IconData _groupIcon(String group) {
    switch (group) {
      case 'Marketplace & Content':
        return Icons.storefront_outlined;
      case 'Partners':
        return Icons.handshake_outlined;
      case 'Logistics':
        return Icons.local_shipping_outlined;
      case 'Finance & Insights':
        return Icons.query_stats_outlined;
      case 'Management':
        return Icons.admin_panel_settings_outlined;
      default:
        return Icons.grid_view_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<MapEntry<int, _AdminTabSpec>>>{};
    for (final section in sections) {
      final label = section.value.tab.text ?? 'Staff tool';
      grouped.putIfAbsent(_groupFor(label), () => []).add(section);
    }

    const groupOrder = [
      'Marketplace & Content',
      'Partners',
      'Logistics',
      'Finance & Insights',
      'Management',
      'Other Tools',
    ];

    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: AppBar(title: const Text('More')),
      body: FarmPage(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 120),
          children: [
            FarmCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(Icons.badge_outlined, color: FarmColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$roleLabel tools',
                          style: const TextStyle(
                            color: FarmColors.ink,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Secondary administration, setup and reporting.',
                          style: TextStyle(
                            color: FarmColors.mutedText,
                            fontSize: 10.5,
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
            if (sections.isEmpty)
              const FarmEmptyState(
                icon: Icons.check_circle_outline,
                title: 'No additional tools',
                message: 'Everything assigned to this role is already in the bottom navigation.',
              )
            else
              for (final group in groupOrder)
                if ((grouped[group] ?? const []).isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(_groupIcon(group), size: 18, color: FarmColors.primary),
                      const SizedBox(width: 7),
                      Text(
                        group,
                        style: const TextStyle(
                          color: FarmColors.ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  FarmCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (var index = 0;
                            index < (grouped[group] ?? const []).length;
                            index++) ...[
                          ListTile(
                            leading: (grouped[group]![index].value.tab.icon) ??
                                const Icon(Icons.grid_view_outlined),
                            title: Text(
                              grouped[group]![index].value.tab.text ?? 'Staff tool',
                              style: const TextStyle(
                                color: FarmColors.ink,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => onSelect(grouped[group]![index].key),
                          ),
                          if (index != grouped[group]!.length - 1)
                            const Divider(height: 1),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
            _AdminWorkspaceSwitchTile(),
          ],
        ),
      ),
    );
  }
}

class _AdminWorkspaceSwitchTile
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FarmCard(
      padding: EdgeInsets.zero,
      child: ListTile(
        leading: const Icon(
          Icons.apps_rounded,
          color: FarmColors.primary,
        ),
        title: const Text(
          'Switch Workspace',
          style: TextStyle(
            color: FarmColors.ink,
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: const Text(
          'Customer, wholesale, farmer or staff',
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  const OwnerWorkspaceSwitcherScreen(
                currentWorkspace: 'staff',
              ),
            ),
          );
        },
      ),
    );
  }
}

class AdminDashboardScreen extends StatefulWidget {
  final VoidCallback? onHomeTap;
  final String initialSection;
  final String? initialSubSection;
  final String? initialFilter;
  final String? initialRecordId;

  const AdminDashboardScreen({
    super.key,
    this.onHomeTap,
    this.initialSection = 'Dashboard',
    this.initialSubSection,
    this.initialFilter,
    this.initialRecordId,
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState
    extends State<AdminDashboardScreen>
    with WidgetsBindingObserver {
  late Future<bool> _adminAllowedFuture;
  late Future<String> _staffRoleFuture;
  StreamSubscription<AuthState>? _authBoundarySubscription;
  String? _authBoundaryUserId;
  int refreshKey = 0;
  bool _initialIntentPublished = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
            builder: (_) => nextUserId == null
                ? const AuthGate()
                : const OwnerWorkspaceSwitcherScreen(
                    showCloseButton: false,
                  ),
          ),
          (route) => false,
        );
      });
    });

    _adminAllowedFuture =
        isCurrentUserAdminFromDatabase();
    _staffRoleFuture =
        fetchCurrentStaffRole();
  }

  /// Refresh data inside the currently open Admin section without replacing
  /// the Admin access/role futures. Replacing those futures tears down the
  /// bottom-navigation shell long enough for DefaultTabController to restart
  /// at Today/Dashboard.
  ///
  /// Child screens (Products, Orders, Farmers, etc.) must use this after a
  /// normal save/update so the user stays in the section they were working in.
  void _refreshCurrentAdminSection() {
    if (!mounted) return;
    setState(() {
      refreshKey++;
    });
  }

  /// Manual Admin refresh keeps the stronger Repair 018 access/role recheck.
  /// This is used only by the top-right Refresh button, not ordinary child
  /// saves such as Edit Product.
  void refresh() {
    setState(() {
      refreshKey++;
      _adminAllowedFuture =
          isCurrentUserAdminFromDatabase();
      _staffRoleFuture =
          fetchCurrentStaffRole();
    });
  }

  Future<void> _revalidateAdminWorkspace() async {
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
      final allowed = await isCurrentUserAdminFromDatabase();

      if (!mounted ||
          !isHpjPrivateOperationBoundaryCurrent(operationBoundary)) {
        return;
      }

      if (!allowed) {
        FarmDataCache.clearAll();
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

      // Keep the existing Admin navigation shell alive when the app
      // resumes from a camera/gallery/browser file-picker handoff.
      // Replacing the access future here can briefly rebuild the whole
      // workspace and reset the bottom navigation to Today.
      final currentRole = await fetchCurrentStaffRole();

      if (!mounted ||
          !isHpjPrivateOperationBoundaryCurrent(operationBoundary)) {
        return;
      }

      setState(() {
        _staffRoleFuture = Future<String>.value(currentRole);
        refreshKey++;
      });
    } catch (error) {
      farmDebugLog(
        'Admin workspace resume validation skipped: $error',
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    unawaited(_revalidateAdminWorkspace());
  }

  @override
  void dispose() {
    _authBoundarySubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _returnToWorkspaces() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => const OwnerWorkspaceSwitcherScreen(
          showCloseButton: false,
        ),
      ),
      (route) => false,
    );
  }

  Future<void> _signOutFromLockedAdmin() async {
    await signOutFromHpjSession();
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => const AuthGate(),
      ),
      (route) => false,
    );
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

    unawaited(
      saveHpjNavigationPreference(
        workspace: 'customer',
        tab: 0,
      ),
    );
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) =>
            const MainNavigation(initialIndex: 0),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _adminAllowedFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor:
                FarmColors.background,
            body: Center(
              child:
                  CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.data != true) {
          final accessCheckFailed = snapshot.hasError;

          return Scaffold(
            backgroundColor: FarmColors.background,
            appBar: AppBar(
              title: const Text('Staff Access'),
            ),
            body: FarmPage(
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  Header(
                    title: accessCheckFailed
                        ? 'Staff access could not be verified'
                        : 'Staff access is locked',
                    subtitle: accessCheckFailed
                        ? 'Connection or access check'
                        : 'Approved staff access required',
                  ),
                  const SizedBox(height: 18),
                  FarmCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          accessCheckFailed
                              ? 'HPJ could not confirm your staff role right now. Try the access check again, or return to Workspaces.'
                              : 'This area is only available to approved owner, manager, or staff users. Return to Workspaces to use another approved area.',
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: refresh,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Try Again'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _returnToWorkspaces,
                            icon: const Icon(Icons.apps_rounded),
                            label: const Text('Back to Workspaces'),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            unawaited(_signOutFromLockedAdmin());
                          },
                          icon: const Icon(Icons.logout_rounded),
                          label: const Text('Sign out'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return FutureBuilder<String>(
          future: _staffRoleFuture,
          builder: (
            context,
            roleSnapshot,
          ) {
            if (roleSnapshot.connectionState ==
                    ConnectionState.waiting &&
                !roleSnapshot.hasData) {
              return const Scaffold(
                backgroundColor:
                    FarmColors.background,
                body: Center(
                  child:
                      CircularProgressIndicator(),
                ),
              );
            }

            final staffRole =
                normalizeStaffRole(
              roleSnapshot.data,
            );

            final roleLabel =
                staffRoleDisplayLabel(
              staffRole,
            );

            final initialIntent = _AdminNavigationIntent(
              section: widget.initialSection,
              subSection: widget.initialSubSection,
              filter: widget.initialFilter,
              recordId: widget.initialRecordId,
            );

            if (!_initialIntentPublished) {
              _initialIntentPublished = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _adminNavigationIntent.value = initialIntent;
              });
            }

            final tabs =
                _adminTabSpecsForRole(
              staffRole: staffRole,
              refreshKey: refreshKey,
              onChanged: _refreshCurrentAdminSection,
              initialIntent: initialIntent,
            );

            return _AdminBottomNavigationShell(
              staffRole: staffRole,
              roleLabel: roleLabel.isEmpty
                  ? 'Staff'
                  : roleLabel,
              tabs: tabs,
              refreshKey: refreshKey,
              onRefresh: refresh,
              onExit: goBackHome,
              initialIntent: initialIntent,
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


class AdminNetworkImpactSnapshot {
  final List<FarmerProfile> farmers;
  final List<FarmerPayout> farmerPayouts;
  final List<BusinessAccount> businessAccounts;
  final List<WholesaleDemandForecast> planningSignals;
  final List<WholesaleOrderRequest> wholesaleRequests;
  final List<WholesaleInvoice> wholesaleInvoices;

  const AdminNetworkImpactSnapshot({
    required this.farmers,
    required this.farmerPayouts,
    required this.businessAccounts,
    required this.planningSignals,
    required this.wholesaleRequests,
    required this.wholesaleInvoices,
  });

  int get approvedFarmers {
    return farmers
        .where((item) => item.isApproved)
        .length;
  }

  int get approvedBusinesses {
    return businessAccounts
        .where(
          (item) =>
              item.status
                  .trim()
                  .toLowerCase() ==
              'approved',
        )
        .length;
  }

  int get approvedParticipants =>
      approvedFarmers + approvedBusinesses;

  int get activePlanningSignals {
    return planningSignals
        .where((item) => item.isActive)
        .length;
  }

  int get plannedProducts {
    return planningSignals
        .where((item) => item.isActive)
        .map(
          (item) =>
              item.productName
                  .trim()
                  .toLowerCase(),
        )
        .where((item) => item.isNotEmpty)
        .toSet()
        .length;
  }

  int get completedWholesaleRequests {
    return wholesaleRequests.where(
      (item) {
        final status =
            item.status.trim().toLowerCase();

        return status == 'completed' ||
            status == 'delivered';
      },
    ).length;
  }

  double get wholesaleCompletionRate {
    if (wholesaleRequests.isEmpty) {
      return 0;
    }

    return completedWholesaleRequests /
        wholesaleRequests.length;
  }

  int get releasedFarmerPayoutCount {
    return farmerPayouts
        .where(
          (item) =>
              item.payoutStatus
                  .trim()
                  .toLowerCase() ==
              'released',
        )
        .length;
  }

  double get releasedFarmerPayoutValue {
    return farmerPayouts
        .where(
          (item) =>
              item.payoutStatus
                  .trim()
                  .toLowerCase() ==
              'released',
        )
        .fold<double>(
          0,
          (sum, item) =>
              sum + item.netAmount,
        );
  }

  double get wholesalePaymentsRecorded {
    return wholesaleInvoices.fold<double>(
      0,
      (sum, item) =>
          sum + item.paidAmount,
    );
  }

  double get wholesaleAmountDue {
    return wholesaleInvoices.fold<double>(
      0,
      (sum, item) =>
          sum + item.amountDue,
    );
  }

  double get wholesaleInvoicedValue {
    return wholesaleInvoices.fold<double>(
      0,
      (sum, item) =>
          sum + item.totalAmount,
    );
  }

  int get upcomingPlanningSignals30Days {
    final now = DateTime.now();
    final start =
        DateTime(now.year, now.month, now.day);
    final end = start.add(
      const Duration(days: 30),
    );

    return planningSignals.where(
      (item) {
        if (!item.isActive) return false;

        final need = DateTime(
          item.needByDate.year,
          item.needByDate.month,
          item.needByDate.day,
        );

        return !need.isBefore(start) &&
            !need.isAfter(end);
      },
    ).length;
  }
}

Future<AdminNetworkImpactSnapshot>
    fetchAdminNetworkImpactSnapshot() async {
  Future<List<FarmerProfile>>
      safeFarmers() async {
    try {
      return await fetchFarmerProfiles();
    } catch (error) {
      farmDebugLog(
        'Impact farmer summary skipped: $error',
      );
      return <FarmerProfile>[];
    }
  }

  Future<List<FarmerPayout>>
      safePayouts() async {
    try {
      return await fetchFarmerPayouts();
    } catch (error) {
      farmDebugLog(
        'Impact farmer payout summary skipped: $error',
      );
      return <FarmerPayout>[];
    }
  }

  Future<List<BusinessAccount>>
      safeBusinesses() async {
    try {
      return await fetchAdminBusinessAccounts();
    } catch (error) {
      farmDebugLog(
        'Impact wholesale account summary skipped: $error',
      );
      return <BusinessAccount>[];
    }
  }

  Future<List<WholesaleDemandForecast>>
      safePlanning() async {
    try {
      return await fetchAdminWholesaleDemandForecasts();
    } catch (error) {
      farmDebugLog(
        'Impact planning summary skipped: $error',
      );
      return <WholesaleDemandForecast>[];
    }
  }

  Future<List<WholesaleOrderRequest>>
      safeRequests() async {
    try {
      return await fetchAdminWholesaleRequests();
    } catch (error) {
      farmDebugLog(
        'Impact wholesale request summary skipped: $error',
      );
      return <WholesaleOrderRequest>[];
    }
  }

  Future<List<WholesaleInvoice>>
      safeInvoices() async {
    try {
      return await fetchAdminWholesaleInvoices();
    } catch (error) {
      farmDebugLog(
        'Impact wholesale invoice summary skipped: $error',
      );
      return <WholesaleInvoice>[];
    }
  }

  final results = await Future.wait<dynamic>(
    [
      safeFarmers(),
      safePayouts(),
      safeBusinesses(),
      safePlanning(),
      safeRequests(),
      safeInvoices(),
    ],
  );

  return AdminNetworkImpactSnapshot(
    farmers:
        results[0] as List<FarmerProfile>,
    farmerPayouts:
        results[1] as List<FarmerPayout>,
    businessAccounts:
        results[2] as List<BusinessAccount>,
    planningSignals:
        results[3]
            as List<WholesaleDemandForecast>,
    wholesaleRequests:
        results[4]
            as List<WholesaleOrderRequest>,
    wholesaleInvoices:
        results[5]
            as List<WholesaleInvoice>,
  );
}

String _impactPercent(double value) {
  final percent = value * 100;

  if (percent <= 0) return '0%';

  return '${percent.toStringAsFixed(percent >= 10 ? 0 : 1)}%';
}

Future<Uint8List> _buildNetworkImpactPdf(
  AdminNetworkImpactSnapshot snapshot,
) async {
  final pdf = pw.Document();

  pw.MemoryImage? logo;

  try {
    final bytes = await rootBundle.load(
      'lib/assets/images/logo.png',
    );

    logo = pw.MemoryImage(
      bytes.buffer.asUint8List(),
    );
  } catch (_) {
    logo = null;
  }

  final green =
      PdfColor.fromInt(0xFF1F6B3A);
  final softGreen =
      PdfColor.fromInt(0xFFEAF3EC);

  pw.Widget metric(
    String label,
    String value,
  ) {
    return pw.Expanded(
      child: pw.Container(
        padding:
            const pw.EdgeInsets.all(9),
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
                fontSize: 7.3,
                color: PdfColors.grey700,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              pdfSafe(value),
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

  pw.Widget section(
    String title,
    List<String> lines,
  ) {
    return pw.Container(
      width: double.infinity,
      padding:
          const pw.EdgeInsets.all(11),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(
          color: PdfColors.grey300,
        ),
        borderRadius:
            pw.BorderRadius.circular(7),
      ),
      child: pw.Column(
        crossAxisAlignment:
            pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              color: green,
              fontSize: 10.5,
              fontWeight:
                  pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 7),
          for (final line in lines)
            pw.Padding(
              padding:
                  const pw.EdgeInsets.only(
                bottom: 4,
              ),
              child: pw.Text(
                pdfSafe(line),
                style:
                    const pw.TextStyle(
                  fontSize: 8.2,
                  color:
                      PdfColors.grey800,
                ),
              ),
            ),
        ],
      ),
    );
  }

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin:
          const pw.EdgeInsets.fromLTRB(
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
                  color:
                      PdfColors.grey600,
                ),
              ),
              pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: const pw.TextStyle(
                  fontSize: 7,
                  color:
                      PdfColors.grey600,
                ),
              ),
            ],
          ),
        ],
      ),
      build: (context) => [
        pw.Row(
          crossAxisAlignment:
              pw.CrossAxisAlignment.center,
          children: [
            if (logo != null)
              pw.Container(
                width: 54,
                height: 54,
                child: pw.Image(
                  logo,
                  fit: pw.BoxFit.contain,
                ),
              ),
            if (logo != null)
              pw.SizedBox(width: 12),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment:
                    pw.CrossAxisAlignment
                        .start,
                children: [
                  pw.Text(
                    'NETWORK ACTIVITY SNAPSHOT',
                    style: pw.TextStyle(
                      color: green,
                      fontSize: 16,
                      fontWeight:
                          pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    'Farmer participation, wholesale adoption, planning and recorded money flow',
                    style:
                        const pw.TextStyle(
                      fontSize: 8.5,
                      color:
                          PdfColors.grey700,
                    ),
                  ),
                  pw.Text(
                    'Generated ${formatCustomerDateTime(DateTime.now())}',
                    style:
                        const pw.TextStyle(
                      fontSize: 7.2,
                      color:
                          PdfColors.grey600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        pw.SizedBox(height: 16),

        pw.Row(
          children: [
            metric(
              'Approved farmers',
              '${snapshot.approvedFarmers}',
            ),
            pw.SizedBox(width: 7),
            metric(
              'Approved wholesale',
              '${snapshot.approvedBusinesses}',
            ),
            pw.SizedBox(width: 7),
            metric(
              'Approved participants',
              '${snapshot.approvedParticipants}',
            ),
          ],
        ),

        pw.SizedBox(height: 7),

        pw.Row(
          children: [
            metric(
              'Active planning signals',
              '${snapshot.activePlanningSignals}',
            ),
            pw.SizedBox(width: 7),
            metric(
              'Products being planned',
              '${snapshot.plannedProducts}',
            ),
            pw.SizedBox(width: 7),
            metric(
              'Needs in next 30 days',
              '${snapshot.upcomingPlanningSignals30Days}',
            ),
          ],
        ),

        pw.SizedBox(height: 16),

        section(
          'PARTICIPATION & PLANNING',
          [
            '${snapshot.approvedFarmers} farmer partner(s) are approved in HPJ.',
            '${snapshot.approvedBusinesses} wholesale business account(s) are approved.',
            '${snapshot.activePlanningSignals} active Planning Ahead signal(s) cover ${snapshot.plannedProducts} distinct product(s).',
            '${snapshot.upcomingPlanningSignals30Days} active planning signal(s) are due within the next 30 days.',
          ],
        ),

        pw.SizedBox(height: 10),

        section(
          'WHOLESALE ACTIVITY',
          [
            '${snapshot.wholesaleRequests.length} wholesale request(s) are recorded.',
            '${snapshot.completedWholesaleRequests} request(s) are completed or delivered.',
            'Recorded completion rate: ${_impactPercent(snapshot.wholesaleCompletionRate)}.',
            'Wholesale invoiced value: ${formatJmd(snapshot.wholesaleInvoicedValue)}.',
            'Wholesale payments recorded: ${formatJmd(snapshot.wholesalePaymentsRecorded)}.',
            'Wholesale amount due: ${formatJmd(snapshot.wholesaleAmountDue)}.',
          ],
        ),

        pw.SizedBox(height: 10),

        section(
          'FARMER MONEY FLOW',
          [
            '${snapshot.releasedFarmerPayoutCount} farmer payout(s) are marked released.',
            'Released farmer payout value recorded in HPJ: ${formatJmd(snapshot.releasedFarmerPayoutValue)}.',
          ],
        ),

        pw.SizedBox(height: 16),

        pw.Container(
          padding:
              const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius:
                pw.BorderRadius.circular(6),
          ),
          child: pw.Text(
            'This is an internal HPJ operational activity snapshot based on records currently held in the platform. '
            'It is not an audited financial statement, official agricultural census, government statistic, or independent impact evaluation.',
            style: const pw.TextStyle(
              fontSize: 7.5,
              color: PdfColors.grey700,
            ),
          ),
        ),
      ],
    ),
  );

  return pdf.save();
}

class AdminNetworkImpactTab
    extends StatefulWidget {
  final int refreshKey;

  const AdminNetworkImpactTab({
    super.key,
    required this.refreshKey,
  });

  @override
  State<AdminNetworkImpactTab>
      createState() =>
          _AdminNetworkImpactTabState();
}

class _AdminNetworkImpactTabState
    extends State<AdminNetworkImpactTab> {
  late Future<AdminNetworkImpactSnapshot>
      future;

  bool exporting = false;

  @override
  void initState() {
    super.initState();

    future =
        fetchAdminNetworkImpactSnapshot();
  }

  @override
  void didUpdateWidget(
    covariant AdminNetworkImpactTab
        oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.refreshKey !=
        widget.refreshKey) {
      _refresh();
    }
  }

  Future<void> _refresh() async {
    final next =
        fetchAdminNetworkImpactSnapshot();

    setState(() {
      future = next;
    });

    await next;
  }

  Future<void> _export(
    AdminNetworkImpactSnapshot snapshot, {
    required bool share,
  }) async {
    if (exporting) return;

    setState(() {
      exporting = true;
    });

    try {
      final bytes =
          await _buildNetworkImpactPdf(
        snapshot,
      );

      if (share) {
        await Printing.sharePdf(
          bytes: bytes,
          filename:
              'HPJ_Network_Activity_Snapshot.pdf',
        );
      } else {
        await Printing.layoutPdf(
          onLayout: (_) async => bytes,
          name:
              'HPJ_Network_Activity_Snapshot.pdf',
        );
      }
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
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
    return RefreshIndicator(
      onRefresh: _refresh,
      child:
          FutureBuilder<AdminNetworkImpactSnapshot>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
                  ConnectionState.waiting &&
              snapshot.data == null) {
            return ListView(
              physics:
                  const AlwaysScrollableScrollPhysics(),
              padding:
                  const EdgeInsets.fromLTRB(
                18,
                30,
                18,
                120,
              ),
              children: const [
                Center(
                  child:
                      CircularProgressIndicator(),
                ),
              ],
            );
          }

          if (snapshot.hasError ||
              snapshot.data == null) {
            return ListView(
              physics:
                  const AlwaysScrollableScrollPhysics(),
              padding:
                  const EdgeInsets.fromLTRB(
                18,
                30,
                18,
                120,
              ),
              children: [
                const FarmEmptyState(
                  icon: Icons.hub_outlined,
                  title:
                      'Impact snapshot unavailable',
                  message:
                      'HPJ could not load the network activity summary. Pull down or use Try Again.',
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: _refresh,
                  child:
                      const Text('Try Again'),
                ),
              ],
            );
          }

          final data = snapshot.data!;

          return ListView(
            physics:
                const AlwaysScrollableScrollPhysics(),
            padding:
                const EdgeInsets.fromLTRB(
              18,
              16,
              18,
              120,
            ),
            children: [
              Container(
                padding:
                    const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(28),
                  color: FarmColors.deepGreen,
                  boxShadow: [
                    BoxShadow(
                      color: FarmColors.shadow
                          .withOpacity(0.12),
                      blurRadius: 22,
                      offset:
                          const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'NETWORK ACTIVITY',
                      style: TextStyle(
                        color:
                            Color(0xFFD7E8DC),
                        fontSize: 9,
                        fontWeight:
                            FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'HPJ impact & adoption',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        height: 1.05,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'A factual view of participation, planning, commerce and recorded money flow across the HPJ network.',
                      style: TextStyle(
                        color:
                            Color(0xFFE2EEE7),
                        fontSize: 10.5,
                        height: 1.4,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child:
                              _ImpactHeroMetric(
                            label:
                                'Participants',
                            value:
                                '${data.approvedParticipants}',
                          ),
                        ),
                        const SizedBox(
                          width: 8,
                        ),
                        Expanded(
                          child:
                              _ImpactHeroMetric(
                            label:
                                'Planning signals',
                            value:
                                '${data.activePlanningSignals}',
                          ),
                        ),
                        const SizedBox(
                          width: 8,
                        ),
                        Expanded(
                          child:
                              _ImpactHeroMetric(
                            label:
                                'Completed W/S',
                            value:
                                '${data.completedWholesaleRequests}',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              _ImpactSection(
                title:
                    'Participation & demand planning',
                subtitle:
                    'Who is using HPJ and how much future purchasing activity is visible.',
                children: [
                  _ImpactMetricRow(
                    label:
                        'Approved farmer partners',
                    value:
                        '${data.approvedFarmers}',
                  ),
                  _ImpactMetricRow(
                    label:
                        'Approved wholesale businesses',
                    value:
                        '${data.approvedBusinesses}',
                  ),
                  _ImpactMetricRow(
                    label:
                        'Active Planning Ahead signals',
                    value:
                        '${data.activePlanningSignals}',
                  ),
                  _ImpactMetricRow(
                    label:
                        'Products being planned',
                    value:
                        '${data.plannedProducts}',
                  ),
                  _ImpactMetricRow(
                    label:
                        'Needs due in next 30 days',
                    value:
                        '${data.upcomingPlanningSignals30Days}',
                    showDivider: false,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              _ImpactSection(
                title:
                    'Wholesale activity',
                subtitle:
                    'Commercial activity recorded through HPJ wholesale workflows.',
                children: [
                  _ImpactMetricRow(
                    label:
                        'Wholesale requests recorded',
                    value:
                        '${data.wholesaleRequests.length}',
                  ),
                  _ImpactMetricRow(
                    label:
                        'Completed / delivered',
                    value:
                        '${data.completedWholesaleRequests}',
                  ),
                  _ImpactMetricRow(
                    label:
                        'Recorded completion rate',
                    value:
                        _impactPercent(
                      data.wholesaleCompletionRate,
                    ),
                  ),
                  _ImpactMetricRow(
                    label:
                        'Wholesale invoiced value',
                    value:
                        formatJmd(
                      data.wholesaleInvoicedValue,
                    ),
                  ),
                  _ImpactMetricRow(
                    label:
                        'Wholesale payments recorded',
                    value:
                        formatJmd(
                      data.wholesalePaymentsRecorded,
                    ),
                  ),
                  _ImpactMetricRow(
                    label:
                        'Wholesale amount due',
                    value:
                        formatJmd(
                      data.wholesaleAmountDue,
                    ),
                    showDivider: false,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              _ImpactSection(
                title:
                    'Farmer money flow',
                subtitle:
                    'Released farmer payout activity currently recorded in HPJ.',
                children: [
                  _ImpactMetricRow(
                    label:
                        'Released payout records',
                    value:
                        '${data.releasedFarmerPayoutCount}',
                  ),
                  _ImpactMetricRow(
                    label:
                        'Released payout value',
                    value:
                        formatJmd(
                      data.releasedFarmerPayoutValue,
                    ),
                    showDivider: false,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              FarmCard(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Export stakeholder snapshot',
                      style: TextStyle(
                        color: FarmColors.ink,
                        fontSize: 13,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Create a concise PDF of the current HPJ network activity for internal review or appropriate stakeholder discussions.',
                      style: TextStyle(
                        color:
                            FarmColors.mutedText,
                        fontSize: 9.7,
                        height: 1.35,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width:
                          double.infinity,
                      child:
                          ElevatedButton.icon(
                        onPressed: exporting
                            ? null
                            : () => _export(
                                  data,
                                  share: false,
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
                    const SizedBox(height: 7),
                    SizedBox(
                      width:
                          double.infinity,
                      child:
                          OutlinedButton.icon(
                        onPressed: exporting
                            ? null
                            : () => _export(
                                  data,
                                  share: true,
                                ),
                        icon: const Icon(
                          Icons.share_outlined,
                        ),
                        label: const Text(
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
                    const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(
                    0xFFF0F4EC,
                  ),
                  borderRadius:
                      BorderRadius.circular(15),
                  border: Border.all(
                    color: const Color(
                      0xFFDCE4D8,
                    ),
                  ),
                ),
                child: const Text(
                  'Use this as an HPJ operational snapshot only. It is not an audited financial statement, official agricultural census, government statistic, or independent impact evaluation.',
                  style: TextStyle(
                    color:
                        FarmColors.mutedText,
                    fontSize: 9.4,
                    height: 1.35,
                    fontWeight:
                        FontWeight.w600,
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

class _ImpactHeroMetric extends StatelessWidget {
  final String label;
  final String value;

  const _ImpactHeroMetric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color:
              Colors.white.withOpacity(0.14),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 2,
            overflow:
                TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFD7E8DC),
              fontSize: 8.3,
              height: 1.2,
              fontWeight:
                  FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImpactSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;

  const _ImpactSection({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return FarmCard(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: FarmColors.ink,
              fontSize: 13.5,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: const TextStyle(
              color:
                  FarmColors.mutedText,
              fontSize: 9.5,
              height: 1.3,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _ImpactMetricRow extends StatelessWidget {
  final String label;
  final String value;
  final bool showDivider;

  const _ImpactMetricRow({
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding:
              const EdgeInsets.symmetric(
            vertical: 7,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style:
                      const TextStyle(
                    color: FarmColors
                        .mutedText,
                    fontSize: 10,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                value,
                textAlign:
                    TextAlign.right,
                style: const TextStyle(
                  color: FarmColors.ink,
                  fontSize: 10.8,
                  fontWeight:
                      FontWeight.w900,
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

  void _openSection(String label) {
    final scope = _AdminNavigationScope.maybeOf(context);

    if (scope != null) {
      scope.onNavigate(_AdminNavigationIntent(section: label));
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$label is not available from this screen.',
        ),
      ),
    );
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
                onOrdersTap: () => _openSection('Orders'),
                onFulfillmentTap: () => _openSection('Fulfillment'),
                onProductsTap: () => _openSection('Products'),
                onSupportTap: () => _openSection('Inbox'),
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
                    onTap: () => _openSection('Orders'),
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
                    onTap: () => _openSection('Fulfillment'),
                  ),
                  AdminActionTile(
                    icon: Icons.payments_outlined,
                    title: 'Payment verification',
                    description: 'Check unpaid and pending payment orders.',
                    badge: overview.unpaidPayments > 0
                        ? '${overview.unpaidPayments} unpaid'
                        : null,
                    color: FarmColors.warning,
                    onTap: () => _openSection('Orders'),
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
                    onTap: () => _openSection('Products'),
                  ),
                  AdminActionTile(
                    icon: Icons.add_box_outlined,
                    title: 'Add product',
                    description: 'Create a new product and upload an image.',
                    color: FarmColors.gold,
                    onTap: () => _openSection('Products'),
                  ),
                  AdminActionTile(
                    icon: Icons.local_offer_outlined,
                    title: 'Deals, discounts & coupons',
                    description:
                        'Review deals, product discounts, and coupon tools.',
                    color: const Color(0xFF7D5A21),
                    onTap: () => _openSection('Coupons'),
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
                    onTap: () => _openSection('Inbox'),
                  ),
                  AdminActionTile(
                    icon: Icons.rate_review_outlined,
                    title: 'Reviews & feedback',
                    description: 'Read product reviews and customer comments.',
                    color: FarmColors.green,
                    onTap: () => _openSection('Reviews'),
                  ),
                  AdminActionTile(
                    icon: Icons.agriculture_outlined,
                    title: 'Farmer partners',
                    description:
                        'Review farmer profiles, status, and approvals.',
                    color: const Color(0xFF6E7D4F),
                    onTap: () => _openSection('Farmers'),
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
                    onTap: () => _openSection('Analytics'),
                  ),
                  AdminActionTile(
                    icon: Icons.hub_outlined,
                    title: 'Impact & adoption',
                    description:
                        'See farmer, wholesale, planning, payout, and network activity.',
                    color: const Color(0xFF315D50),
                    onTap: () => _openSection('Impact'),
                  ),
                  AdminActionTile(
                    icon: Icons.table_chart_outlined,
                    title: 'Reports & CSV',
                    description:
                        'Review sales summaries and export order data.',
                    color: const Color(0xFF227C88),
                    onTap: () => _openSection('Reports'),
                  ),
                  AdminActionTile(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Payouts',
                    description: 'Review farmer payout records and status.',
                    color: FarmColors.gold,
                    onTap: () => _openSection('Payouts'),
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
                    onTap: () => _openSection('Hero'),
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
                label: 'Messages',
                count: openSupportMessages,
                icon: Icons.chat_bubble_outline_rounded,
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


class AdminHelpTutorialsTab extends StatefulWidget {
  final int refreshKey;
  final VoidCallback onChanged;

  const AdminHelpTutorialsTab({
    super.key,
    required this.refreshKey,
    required this.onChanged,
  });

  @override
  State<AdminHelpTutorialsTab> createState() =>
      _AdminHelpTutorialsTabState();
}

class _AdminHelpTutorialsTabState
    extends State<AdminHelpTutorialsTab> {
  late Future<List<HpjHelpTutorial>> _future;
  int _localRefreshKey = 0;
  final Set<String> _busyIds = <String>{};

  @override
  void initState() {
    super.initState();
    _future = fetchAdminHelpTutorials();
  }

  @override
  void didUpdateWidget(
    covariant AdminHelpTutorialsTab oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.refreshKey != widget.refreshKey) {
      _future = fetchAdminHelpTutorials();
    }
  }

  Future<void> _refresh({bool notifyParent = false}) async {
    final next = fetchAdminHelpTutorials();

    if (mounted) {
      setState(() {
        _localRefreshKey++;
        _future = next;
      });
    }

    await next;

    if (notifyParent) {
      widget.onChanged();
    }
  }

  Future<void> _openTutorial(
    HpjHelpTutorial tutorial,
  ) async {
    await openHpjHelpTutorial(
      context,
      tutorial,
    );
  }

  Future<void> _togglePublished(
    HpjHelpTutorial tutorial,
    bool nextValue,
  ) async {
    final id = tutorial.id.trim();
    if (id.isEmpty || _busyIds.contains(id)) return;

    setState(() => _busyIds.add(id));

    try {
      await setAdminHelpTutorialPublished(
        tutorial: tutorial,
        isPublished: nextValue,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nextValue
                ? '${tutorial.title} published.'
                : '${tutorial.title} hidden.',
          ),
        ),
      );

      await _refresh(notifyParent: true);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlyAppError(error)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _busyIds.remove(id));
      }
    }
  }

  Future<void> _deleteTutorial(
    HpjHelpTutorial tutorial,
  ) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Delete tutorial?'),
              content: Text(
                'Delete "${tutorial.title}"? This removes it from HPJ immediately.',
              ),
              actions: [
                TextButton(
                  onPressed: () =>
                      Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () =>
                      Navigator.pop(dialogContext, true),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        ) ==
        true;

    if (!confirmed || !mounted) return;

    final id = tutorial.id.trim();
    if (id.isNotEmpty) {
      setState(() => _busyIds.add(id));
    }

    try {
      await deleteAdminHelpTutorial(tutorial);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tutorial deleted.'),
        ),
      );

      await _refresh(notifyParent: true);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlyAppError(error)),
        ),
      );
    } finally {
      if (mounted && id.isNotEmpty) {
        setState(() => _busyIds.remove(id));
      }
    }
  }

  Future<void> _showTutorialEditor([
    HpjHelpTutorial? tutorial,
  ]) async {
    final titleController = TextEditingController(
      text: tutorial?.title ?? '',
    );
    final buttonController = TextEditingController(
      text: tutorial?.buttonLabel ?? 'Watch quick guide',
    );
    final descriptionController = TextEditingController(
      text: tutorial?.description ?? '',
    );
    final videoController = TextEditingController(
      text: tutorial?.videoUrl ?? '',
    );
    final thumbnailController = TextEditingController(
      text: tutorial?.thumbnailUrl ?? '',
    );
    final sortController = TextEditingController(
      text: '${tutorial?.sortOrder ?? 100}',
    );

    var placement = tutorial?.placement ?? 'signup';
    var audience = tutorial?.audience ?? 'all';
    var published = tutorial?.isPublished ?? false;
    var saving = false;

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: !saving,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> save() async {
              if (saving) return;

              setDialogState(() => saving = true);

              try {
                final sortOrder =
                    int.tryParse(sortController.text.trim()) ?? 100;

                await saveAdminHelpTutorial(
                  id: tutorial?.id,
                  title: titleController.text,
                  buttonLabel: buttonController.text,
                  description: descriptionController.text,
                  videoUrl: videoController.text,
                  thumbnailUrl: thumbnailController.text,
                  placement: placement,
                  audience: audience,
                  isPublished: published,
                  sortOrder: sortOrder,
                );

                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext, true);
              } catch (error) {
                if (!dialogContext.mounted) return;

                setDialogState(() => saving = false);

                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(
                    content: Text(friendlyAppError(error)),
                  ),
                );
              }
            }

            return AlertDialog(
              title: Text(
                tutorial == null
                    ? 'Add Help Tutorial'
                    : 'Edit Help Tutorial',
              ),
              content: SizedBox(
                width: 560,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleController,
                        textCapitalization:
                            TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Tutorial title *',
                          hintText: 'Create Your HPJ Account',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: buttonController,
                        textCapitalization:
                            TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Button label *',
                          hintText: 'Watch quick guide',
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: placement,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Placement',
                        ),
                        items: hpjHelpTutorialPlacementLabels.entries
                            .map(
                              (entry) => DropdownMenuItem<String>(
                                value: entry.key,
                                child: Text(entry.value),
                              ),
                            )
                            .toList(),
                        onChanged: saving
                            ? null
                            : (value) {
                                if (value == null) return;
                                setDialogState(() => placement = value);
                              },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: audience,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Audience',
                        ),
                        items: hpjHelpTutorialAudienceLabels.entries
                            .map(
                              (entry) => DropdownMenuItem<String>(
                                value: entry.key,
                                child: Text(entry.value),
                              ),
                            )
                            .toList(),
                        onChanged: saving
                            ? null
                            : (value) {
                                if (value == null) return;
                                setDialogState(() => audience = value);
                              },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: videoController,
                        keyboardType: TextInputType.url,
                        autocorrect: false,
                        decoration: const InputDecoration(
                          labelText: 'Video URL *',
                          hintText:
                              'https://youtube.com/... or https://vimeo.com/...',
                          prefixIcon:
                              Icon(Icons.play_circle_outline_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: thumbnailController,
                        keyboardType: TextInputType.url,
                        autocorrect: false,
                        decoration: const InputDecoration(
                          labelText: 'Thumbnail URL (optional)',
                          prefixIcon: Icon(Icons.image_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: descriptionController,
                        minLines: 2,
                        maxLines: 4,
                        textCapitalization:
                            TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Short description',
                          hintText:
                              'A quick guide to creating and entering your HPJ account.',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: sortController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Sort order',
                          helperText:
                              'Lower numbers appear first when a section has multiple tutorials.',
                        ),
                      ),
                      const SizedBox(height: 6),
                      SwitchListTile.adaptive(
                        value: published,
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Published',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        subtitle: Text(
                          published
                              ? 'Users can see this tutorial now.'
                              : 'Saved as a draft. Users cannot see it.',
                        ),
                        onChanged: saving
                            ? null
                            : (value) {
                                setDialogState(
                                  () => published = value,
                                );
                              },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () => Navigator.pop(
                            dialogContext,
                            false,
                          ),
                  child: const Text('Cancel'),
                ),
                FilledButton.icon(
                  onPressed: saving ? null : save,
                  icon: saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    saving ? 'Saving...' : 'Save Tutorial',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    titleController.dispose();
    buttonController.dispose();
    descriptionController.dispose();
    videoController.dispose();
    thumbnailController.dispose();
    sortController.dispose();

    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tutorial == null
                ? 'Tutorial added.'
                : 'Tutorial updated.',
          ),
        ),
      );

      await _refresh(notifyParent: true);
    }
  }

  Widget _tutorialCard(
    HpjHelpTutorial tutorial,
  ) {
    final busy = _busyIds.contains(tutorial.id);
    final thumbnail = tutorial.thumbnailUrl?.trim() ?? '';

    return FarmCard(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (thumbnail.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 92,
                    height: 62,
                    child: Image.network(
                      thumbnail,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) {
                        return const ColoredBox(
                          color: FarmColors.primarySoft,
                          child: Icon(
                            Icons.video_library_outlined,
                            color: FarmColors.primary,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tutorial.title,
                      style: const TextStyle(
                        color: FarmColors.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        Chip(
                          visualDensity: VisualDensity.compact,
                          label: Text(tutorial.placementLabel),
                        ),
                        Chip(
                          visualDensity: VisualDensity.compact,
                          label: Text(tutorial.audienceLabel),
                        ),
                        Chip(
                          visualDensity: VisualDensity.compact,
                          avatar: Icon(
                            tutorial.isPublished
                                ? Icons.public_rounded
                                : Icons.edit_note_rounded,
                            size: 16,
                          ),
                          label: Text(
                            tutorial.isPublished
                                ? 'Published'
                                : 'Draft',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: tutorial.isPublished,
                onChanged: busy
                    ? null
                    : (value) => unawaited(
                          _togglePublished(
                            tutorial,
                            value,
                          ),
                        ),
              ),
            ],
          ),
          if (tutorial.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              tutorial.description,
              style: const TextStyle(
                color: FarmColors.mutedText,
                fontSize: 12.5,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.play_circle_outline_rounded,
                size: 18,
                color: FarmColors.primary,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  tutorial.videoUrl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: FarmColors.mutedText,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Order ${tutorial.sortOrder}',
                style: const TextStyle(
                  color: FarmColors.mutedText,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: busy
                    ? null
                    : () => unawaited(
                          _openTutorial(tutorial),
                        ),
                icon: const Icon(
                  Icons.open_in_new_rounded,
                  size: 18,
                ),
                label: const Text('Test Video'),
              ),
              OutlinedButton.icon(
                onPressed: busy
                    ? null
                    : () => unawaited(
                          _showTutorialEditor(tutorial),
                        ),
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 18,
                ),
                label: const Text('Edit'),
              ),
              TextButton.icon(
                onPressed: busy
                    ? null
                    : () => unawaited(
                          _deleteTutorial(tutorial),
                        ),
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                ),
                label: const Text('Delete'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<HpjHelpTutorial>>(
      key: ValueKey(
        '${widget.refreshKey}-$_localRefreshKey',
      ),
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
                ConnectionState.waiting &&
            !snapshot.hasData) {
          return const SkeletonList();
        }

        if (snapshot.hasError) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
            children: [
              FarmCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Help & Tutorials needs setup',
                      style: TextStyle(
                        color: FarmColors.ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      friendlyAppError(snapshot.error!),
                      style: const TextStyle(
                        color: FarmColors.mutedText,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () =>
                          unawaited(_refresh()),
                      icon: const Icon(
                        Icons.refresh_rounded,
                      ),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        final tutorials =
            snapshot.data ?? const <HpjHelpTutorial>[];

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics:
                const AlwaysScrollableScrollPhysics(),
            padding:
                const EdgeInsets.fromLTRB(18, 18, 18, 120),
            children: [
              FarmCard(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Help & Tutorials',
                                style: TextStyle(
                                  color: FarmColors.ink,
                                  fontSize: 20,
                                  fontWeight:
                                      FontWeight.w900,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                'Add tutorial videos without updating the app. Publish only when the video is ready.',
                                style: TextStyle(
                                  color:
                                      FarmColors.mutedText,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        FilledButton.icon(
                          onPressed: () => unawaited(
                            _showTutorialEditor(),
                          ),
                          icon: const Icon(
                            Icons.add_rounded,
                          ),
                          label:
                              const Text('Add Tutorial'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: FarmColors.primarySoft,
                        borderRadius:
                            BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'Signup button behaviour: if no published "Sign Up" tutorial exists, the button stays hidden. Publish one here and it appears automatically.',
                        style: TextStyle(
                          color: FarmColors.ink,
                          fontSize: 12,
                          height: 1.4,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (tutorials.isEmpty)
                const FarmEmptyState(
                  icon: Icons.video_library_outlined,
                  title: 'No tutorials yet',
                  message:
                      'Add your first tutorial now. Keep it as Draft until the video is ready.',
                )
              else
                ...tutorials.map(
                  (tutorial) => Padding(
                    padding:
                        const EdgeInsets.only(bottom: 12),
                    child: _tutorialCard(tutorial),
                  ),
                ),
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
                  slide.position == 1
                      ? 'Home hero slide 1 • Fresh Box'
                      : slide.position == 2
                          ? 'Home hero slide 2 • What’s Cooking'
                          : slide.position == 3
                              ? 'Home hero slide 3 • Fresh Deals'
                              : 'Home hero slide 4 • Local Farms',
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
  final String initialFilter;
  final String? initialOrderId;

  const AdminOrdersTab({
    super.key,
    required this.refreshKey,
    required this.onChanged,
    this.initialFilter = 'all',
    this.initialOrderId,
  });

  @override
  State<AdminOrdersTab> createState() => _AdminOrdersTabState();
}

String pdfSafe(String value) {
  return value
      .replaceAll('•', '-')
      .replaceAll('–', '-')
      .replaceAll('—', '-')
      .replaceAll('\u00A0', ' ')
      .trim();
}

class _AdminOrdersTabState extends State<AdminOrdersTab> {
  final TextEditingController orderSearchController = TextEditingController();
  bool _staleInitialOrderCleared = false;

  @override
  void initState() {
    super.initState();
    selectedFilter = widget.initialFilter.trim().isEmpty
        ? 'all'
        : widget.initialFilter.trim().toLowerCase();
    orderSearchQuery = widget.initialOrderId?.trim() ?? '';
    orderSearchController.text = orderSearchQuery;
  }

  @override
  void didUpdateWidget(covariant AdminOrdersTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.initialFilter.trim().isEmpty
        ? 'all'
        : widget.initialFilter.trim().toLowerCase();
    final nextOrderId = widget.initialOrderId?.trim() ?? '';
    final filterChanged = oldWidget.initialFilter != widget.initialFilter &&
        selectedFilter != next;
    final orderChanged = oldWidget.initialOrderId != widget.initialOrderId &&
        orderSearchQuery != nextOrderId;

    if (filterChanged || orderChanged) {
      setState(() {
        if (filterChanged) selectedFilter = next;
        if (orderChanged) {
          _staleInitialOrderCleared = false;
          orderSearchQuery = nextOrderId;
          orderSearchController.text = nextOrderId;
        }
      });
    }
  }

  @override
  void dispose() {
    orderSearchController.dispose();
    super.dispose();
  }

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
        : order.customerAddress.trim();

    final itemLines = order.items.map((item) {
      return '${item.productName} x${item.quantity}';
    }).toList();

    pw.MemoryImage? logoImage;

    try {
      final logoBytes = await rootBundle.load('lib/assets/images/logo.png');
      logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (_) {
      logoImage = null;
    }

    pw.Widget sectionTitle(String title) {
      return pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.symmetric(
          vertical: 4,
          horizontal: 6,
        ),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey200,
          borderRadius: pw.BorderRadius.circular(4),
        ),
        child: pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      );
    }

    pw.Widget infoRow(String label, String value) {
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 2),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(
              width: 54,
              child: pw.Text(
                label,
                style: pw.TextStyle(
                  fontSize: 7,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Expanded(
              child: pw.Text(
                value,
                style: const pw.TextStyle(fontSize: 7.5),
              ),
            ),
          ],
        ),
      );
    }

    pw.Widget statusBox(String label, String value) {
      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(
          vertical: 6,
          horizontal: 7,
        ),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(
            color: PdfColors.grey600,
            width: 0.7,
          ),
          borderRadius: pw.BorderRadius.circular(5),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label.toUpperCase(),
              style: const pw.TextStyle(
                fontSize: 6,
                color: PdfColors.grey600,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              value,
              maxLines: 1,
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    pw.Widget itemBox(String text) {
      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(
          vertical: 1.6,
          horizontal: 3,
        ),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(
            color: PdfColors.grey300,
            width: 0.5,
          ),
          borderRadius: pw.BorderRadius.circular(2),
        ),
        child: pw.Text(
          '- $text',
          maxLines: 1,
          style: pw.TextStyle(
            fontSize: 6.2,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      );
    }

    final brandGreen = PdfColor.fromInt(0xFF1F5C34);
    final deepGreen = PdfColor.fromInt(0xFF183D25);

    pw.Widget smallLeafMark() {
      return pw.Container(
        width: 16,
        height: 14,
        alignment: pw.Alignment.center,
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          children: [
            pw.Container(
              width: 5,
              height: 9,
              decoration: pw.BoxDecoration(
                color: brandGreen,
                borderRadius: pw.BorderRadius.circular(5),
              ),
            ),
            pw.SizedBox(width: 2),
            pw.Container(
              width: 5,
              height: 9,
              decoration: pw.BoxDecoration(
                color: brandGreen,
                borderRadius: pw.BorderRadius.circular(5),
              ),
            ),
          ],
        ),
      );
    }

    pw.Widget leafIcon() {
      return pw.SizedBox(
        width: 18,
        height: 10,
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Transform.rotate(
              angle: -0.55,
              child: pw.Container(
                width: 7,
                height: 8,
                decoration: pw.BoxDecoration(
                  color: brandGreen,
                  borderRadius: pw.BorderRadius.only(
                    topLeft: pw.Radius.circular(8),
                    bottomRight: pw.Radius.circular(8),
                    topRight: pw.Radius.circular(1),
                    bottomLeft: pw.Radius.circular(1),
                  ),
                ),
              ),
            ),
            pw.SizedBox(width: 1),
            pw.Transform.rotate(
              angle: 0.55,
              child: pw.Container(
                width: 7,
                height: 8,
                decoration: pw.BoxDecoration(
                  color: brandGreen,
                  borderRadius: pw.BorderRadius.only(
                    topRight: pw.Radius.circular(8),
                    bottomLeft: pw.Radius.circular(8),
                    topLeft: pw.Radius.circular(1),
                    bottomRight: pw.Radius.circular(1),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    pw.Widget leafDivider() {
      return pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Expanded(
            child: pw.Container(
              height: 1.1,
              color: brandGreen,
            ),
          ),
          pw.SizedBox(width: 7),
          leafIcon(),
          pw.SizedBox(width: 7),
          pw.Expanded(
            child: pw.Container(
              height: 1.1,
              color: brandGreen,
            ),
          ),
        ],
      );
    }

    pdf.addPage(
      pw.Page(
        pageFormat: labelFormat,
        build: (context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 1.2),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    if (logoImage != null)
                      pw.Image(
                        logoImage,
                        width: 28,
                        height: 28,
                        fit: pw.BoxFit.contain,
                      )
                    else
                      pw.SizedBox(width: 28, height: 28),
                    pw.SizedBox(width: 7),
                    pw.Container(
                      width: 1,
                      height: 28,
                      color: brandGreen,
                    ),
                    pw.SizedBox(width: 7),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'THE HARVEST PLACE JA',
                            maxLines: 1,
                            style: pw.TextStyle(
                              fontSize: 12.5,
                              fontWeight: pw.FontWeight.bold,
                              color: deepGreen,
                            ),
                          ),
                          pw.SizedBox(height: 1),
                          pw.Text(
                            'Mountainside, St. Elizabeth, Jamaica | Tel: 876-339-1395',
                            style: const pw.TextStyle(
                              fontSize: 7,
                              color: PdfColors.grey700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 6),
                leafDivider(),
                pw.SizedBox(height: 6),
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
                            pdfSafe(orderDateLabel(order)),
                            style: const pw.TextStyle(
                              fontSize: 7.5,
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
                        border: pw.Border.all(
                          color: PdfColors.black,
                          width: 1,
                        ),
                        borderRadius: pw.BorderRadius.circular(5),
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
                pw.SizedBox(height: 8),
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: statusBox('Fulfillment', order.formattedType),
                    ),
                    pw.SizedBox(width: 7),
                    pw.Expanded(
                      child: statusBox('Total', money(order.total)),
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
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
                infoRow('Scheduled', pdfSafe(scheduledLabel(order))),
                pw.SizedBox(height: 7),
                sectionTitle('ITEMS TO PACK'),
                pw.SizedBox(height: 3),
                if (itemLines.isEmpty)
                  pw.Text(
                    'No item details found.',
                    style: const pw.TextStyle(fontSize: 7),
                  )
                else
                  ...List.generate(
                    (itemLines.length / 2).ceil(),
                    (index) {
                      final leftIndex = index * 2;
                      final rightIndex = leftIndex + 1;

                      final leftItem = itemLines[leftIndex];
                      final rightItem = rightIndex < itemLines.length
                          ? itemLines[rightIndex]
                          : null;

                      return pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 2),
                        child: pw.Row(
                          children: [
                            pw.Expanded(child: itemBox(leftItem)),
                            pw.SizedBox(width: 4),
                            pw.Expanded(
                              child: rightItem == null
                                  ? pw.SizedBox()
                                  : itemBox(rightItem),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                pw.Spacer(),
                pw.Container(height: 1, color: PdfColors.black),
                pw.SizedBox(height: 4),
                pw.Center(
                  child: pw.Text(
                    'Fresh - Local - Jamaican',
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(
                      fontSize: 6,
                      color: PdfColors.grey700,
                    ),
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(vertical: 3),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFF1F5C34),
                    borderRadius: pw.BorderRadius.circular(3),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'Thank you for shopping with The Harvest Place Ja',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        fontSize: 6.8,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
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
    final rawDate = order.scheduledDate?.trim() ?? '';
    final rawTime = order.scheduledTime?.trim() ?? '';

    if (rawDate.isEmpty && rawTime.isEmpty) {
      return 'Not scheduled';
    }

    String displayDate = rawDate;
    final parsedDate = DateTime.tryParse(rawDate);
    if (parsedDate != null) {
      const months = <String>[
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      displayDate =
          '${months[parsedDate.month - 1]} ${parsedDate.day}, ${parsedDate.year}';
    }

    String displayTime = rawTime;
    final timeParts = rawTime.split(':');
    if (timeParts.length >= 2) {
      final hour24 = int.tryParse(timeParts[0]);
      final minute = int.tryParse(timeParts[1]);
      if (hour24 != null &&
          minute != null &&
          hour24 >= 0 &&
          hour24 <= 23 &&
          minute >= 0 &&
          minute <= 59) {
        final period = hour24 >= 12 ? 'PM' : 'AM';
        final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
        displayTime =
            '$hour12:${minute.toString().padLeft(2, '0')} $period';
      }
    }

    final parts = <String>[
      if (displayDate.isNotEmpty) displayDate,
      if (displayTime.isNotEmpty) displayTime,
    ];

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
    HpjImageSource source = HpjImageSource.gallery;

    // Installed Android/iOS:
    // let staff choose Camera or Gallery.
    //
    // FlutLab/Web:
    // skip ImagePicker camera completely and use the browser-safe
    // file chooser through product_image_picker_web.dart.
    if (!kIsWeb) {
      final selected = await showModalBottomSheet<HpjImageSource>(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take box photo'),
                subtitle: const Text('Use the device camera'),
                onTap: () => Navigator.pop(
                  sheetContext,
                  HpjImageSource.camera,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose box photo'),
                subtitle: const Text('Select an existing image'),
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
      final picked = await pickProductImageFromDevice(
        source: source,
      );

      if (picked == null) return;

      final bytes = picked.bytes;

      if (bytes.isEmpty) {
        throw Exception(
          'The selected box photo could not be read.',
        );
      }

      const maxBytes = 6 * 1024 * 1024;

      if (bytes.length > maxBytes) {
        throw Exception(
          'Use a box photo smaller than 6 MB.',
        );
      }

      final mime = picked.mimeType.trim().toLowerCase();
      final lowerName = picked.fileName.toLowerCase();

      final extension =
          mime == 'image/png' || lowerName.endsWith('.png')
              ? 'png'
              : mime == 'image/webp' || lowerName.endsWith('.webp')
                  ? 'webp'
                  : 'jpg';

      final contentType = extension == 'png'
          ? 'image/png'
          : extension == 'webp'
              ? 'image/webp'
              : 'image/jpeg';

      final cleanOrderId = order.id.replaceAll(
        RegExp(r'[^A-Za-z0-9_-]'),
        '',
      );

      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}.$extension';

      final path = '$cleanOrderId/$fileName';

      await supabase.storage
          .from('order-box-photos')
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              contentType: contentType,
              upsert: true,
            ),
          );

      final publicUrl = supabase.storage
          .from('order-box-photos')
          .getPublicUrl(path);

      final updatedOrder = await supabase
          .from('orders')
          .update({
            'box_photo_url': publicUrl,
            'box_photo_uploaded_at':
                DateTime.now().toIso8601String(),
            'box_photo_uploaded_by':
                supabase.auth.currentUser?.id,
          })
          .eq('id', order.id)
          .select('id, box_photo_url')
          .maybeSingle();

      if (!context.mounted) return;

      final savedUrl =
          updatedOrder?['box_photo_url']?.toString();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            savedUrl == null || savedUrl.isEmpty
                ? 'Photo uploaded, but the order record was not updated.'
                : 'Box photo saved.',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Box photo failed: ${friendlyAppError(error)}',
          ),
        ),
      );
    }
  }

  Widget orderCard(AdminOrder order) {
    final isDelivery = order.fulfillmentType == 'delivery';
    final deliveryAddress = (order.deliveryAddress ?? '').trim().isNotEmpty
        ? (order.deliveryAddress ?? '').trim()
        : order.customerAddress.trim();

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
                icon: const Icon(Icons.add_a_photo_outlined),
                label: const Text('Add Box Photo'),
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
        final requestedOrderId =
            widget.initialOrderId?.trim() ?? '';

        final exactOrderTargetFound =
            requestedOrderId.isEmpty ||
            orders.any(
              (order) =>
                  order.id.trim() == requestedOrderId ||
                  order.shortId.trim().toLowerCase() ==
                      requestedOrderId.toLowerCase(),
            );

        if (requestedOrderId.isNotEmpty &&
            !exactOrderTargetFound &&
            !_staleInitialOrderCleared) {
          _staleInitialOrderCleared = true;

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;

            orderSearchController.clear();
            setState(() {
              orderSearchQuery = '';
              selectedFilter = 'all';
            });
          });
        }

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
            if (requestedOrderId.isNotEmpty) ...[
              const SizedBox(height: 12),
              _AdminRecordFocusNotice(
                found: exactOrderTargetFound,
                foundMessage:
                    'Opened from your notification. Showing the related customer order.',
                missingMessage:
                    'That customer order is no longer available. Showing current customer orders instead.',
              ),
            ],
            const SizedBox(height: 14),
            TextField(
              controller: orderSearchController,
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
  final String? initialProductId;

  const AdminProductsTab({
    super.key,
    required this.refreshKey,
    required this.onChanged,
    this.initialProductId,
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
  String? _lastFocusedProductId;
  String? _productFocusNoticeId;
  bool? _productFocusFound;

  @override
  void initState() {
    super.initState();
    _adminNavigationIntent.addListener(_handleNavigationIntent);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final initialId = widget.initialProductId?.trim() ?? '';
      if (initialId.isNotEmpty) {
        unawaited(_focusProduct(initialId));
      } else {
        _handleNavigationIntent();
      }
    });
  }

  void _handleNavigationIntent() {
    final intent = _adminNavigationIntent.value;
    if (!mounted ||
        intent == null ||
        intent.section.trim().toLowerCase() != 'products') {
      return;
    }

    final productId = intent.recordId?.trim() ?? '';
    if (productId.isNotEmpty) {
      unawaited(_focusProduct(productId));
    }
  }

  Future<void> _focusProduct(String productId) async {
    final cleanId = productId.trim();
    if (cleanId.isEmpty || cleanId == _lastFocusedProductId) return;

    _lastFocusedProductId = cleanId;

    try {
      final product = await fetchProductById(cleanId);
      if (!mounted) return;

      if (product == null) {
        inventorySearchController.clear();
        setState(() {
          _productFocusNoticeId = cleanId;
          _productFocusFound = false;
          inventoryQuery = '';
          inventoryFilter = 'all';
        });
        return;
      }

      inventorySearchController.text = product.name;
      setState(() {
        _productFocusNoticeId = cleanId;
        _productFocusFound = true;
        inventoryQuery = product.name;
        inventoryFilter = 'all';
      });
    } catch (error) {
      if (!mounted) return;

      inventorySearchController.clear();
      setState(() {
        _productFocusNoticeId = cleanId;
        _productFocusFound = false;
        inventoryQuery = '';
        inventoryFilter = 'all';
      });

      farmDebugLog('Admin product deep-link focus skipped: $error');
    }
  }

  @override
  void dispose() {
    _adminNavigationIntent.removeListener(_handleNavigationIntent);
    inventorySearchController.dispose();
    super.dispose();
  }

  void refreshProducts() {
    if (!mounted) return;

    // Product mutations already invalidate the product cache. Refresh only
    // this Products tab. Calling the parent Admin onChanged here rebuilds the
    // Admin tab specification and can reset DefaultTabController to Today,
    // especially when an image upload refresh happens while the editor dialog
    // is still open.
    FarmDataCache.clearProducts();

    setState(() {
      localRefreshKey++;
    });
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

                if (product != null && product.id.trim().isNotEmpty) {
                  await supabase.from('products').update({
                    'image_url': imageUrl,
                    'updated_at': DateTime.now().toIso8601String(),
                  }).eq('id', product.id);

                  FarmDataCache.clearProducts();

                  if (mounted) {
                    refreshProducts();
                  }
                }

                if (dialogContext.mounted) {
                  setDialogState(() => uploadingImage = false);
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text(
                        product == null
                            ? 'Product image uploaded. Tap Save to finish.'
                            : 'Product image uploaded and saved.',
                      ),
                    ),
                  );
                }
              } catch (error) {
                if (dialogContext.mounted) {
                  setDialogState(() => uploadingImage = false);
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text('Image upload failed: $error'),
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
                          label: unit.isEmpty
                              ? product.category
                              : '${product.category} • $unit',
                          icon: Icons.category_outlined,
                          color: FarmColors.mutedText,
                        ),
                      ],
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
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FarmColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => openProductEditor(context, product: product),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                tooltip: 'More product actions',
                icon: const Icon(Icons.more_horiz_rounded),
                onSelected: (action) async {
                  switch (action) {
                    case 'restock':
                      await openRestockDialog(context, product);
                      break;
                    case 'visibility':
                      await toggleAvailability(product);
                      break;
                    case 'harvested':
                      await openReuseThisWeekDialog(context, product);
                      break;
                    case 'approve':
                      await updateProductApproval(product.id, 'approved');
                      refreshProducts();
                      break;
                    case 'reject':
                      await updateProductApproval(product.id, 'rejected');
                      refreshProducts();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'restock',
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.inventory_2_outlined),
                      title: Text('Restock'),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'visibility',
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        product.isAvailable
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      title: Text(product.isAvailable ? 'Hide' : 'Show'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'harvested',
                    child: ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.event_repeat_outlined),
                      title: Text('Mark Harvested'),
                    ),
                  ),
                  if (product.approvalStatus != 'approved')
                    const PopupMenuItem(
                      value: 'approve',
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.check_circle_outline),
                        title: Text('Approve'),
                      ),
                    ),
                  if (product.approvalStatus != 'rejected')
                    const PopupMenuItem(
                      value: 'reject',
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.cancel_outlined),
                        title: Text('Reject'),
                      ),
                    ),
                ],
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
              if ((_productFocusNoticeId ?? '').isNotEmpty &&
                  _productFocusFound != null) ...[
                const SizedBox(height: 12),
                _AdminRecordFocusNotice(
                  found: _productFocusFound!,
                  foundMessage:
                      'Opened from your notification. Showing the related product.',
                  missingMessage:
                      'That product could not be opened from this notification. Showing current products instead.',
                ),
              ],
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
  final String? initialProductId;

  const AdminReviewsTab({
    super.key,
    required this.refreshKey,
    this.initialProductId,
  });

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
        final requestedProductId = initialProductId?.trim() ?? '';

        final focusedReviews = requestedProductId.isEmpty
            ? const <ProductReview>[]
            : reviews
                .where(
                  (review) =>
                      review.productId.trim() == requestedProductId,
                )
                .toList();

        final exactReviewTargetFound = focusedReviews.isNotEmpty;
        final visibleReviews =
            exactReviewTargetFound ? focusedReviews : reviews;

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
            if (requestedProductId.isNotEmpty) ...[
              _AdminRecordFocusNotice(
                found: exactReviewTargetFound,
                foundMessage:
                    'Opened from your notification. Showing reviews for the related product.',
                missingMessage:
                    'That product review is no longer available in this list. Showing current reviews instead.',
              ),
              const SizedBox(height: 12),
            ],
            if (reviews.isEmpty)
              const FarmEmptyState(
                icon: Icons.reviews_outlined,
                title: 'No customer reviews yet',
                message:
                    'Reviews will appear here after shoppers leave product feedback.',
              )
            else
              ...visibleReviews
                  .take(50)
                  .map((review) => ReviewCard(review: review)),
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

  const AdminSupportTab({
    super.key,
    required this.refreshKey,
    required this.onChanged,
  });

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

        final tickets = snapshot.data ?? const <SupportTicket>[];
        if (tickets.isEmpty) {
          return ListView(
            padding: const EdgeInsets.all(18),
            children: const [
              FarmEmptyState(
                icon: Icons.lock_outline_rounded,
                title: 'Messages are clear',
                message:
                    'Private HPJ conversations you can access will appear here.',
                compact: true,
              ),
            ],
          );
        }

        final unread = tickets.where((ticket) => ticket.hasUnreadForStaff).length;

        return RefreshIndicator(
          onRefresh: () async => onChanged(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: FarmColors.primarySoft,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: FarmColors.green.withOpacity(0.14)),
                ),
                child: Row(
                  children: [
                    Container(
                      height: 46,
                      width: 46,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.support_agent_rounded,
                        color: FarmColors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'HPJ Messages',
                            style: TextStyle(
                              color: FarmColors.ink,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            unread > 0
                                ? '$unread conversation${unread == 1 ? '' : 's'} waiting for a reply.'
                                : 'All visible conversations are up to date.',
                            style: const TextStyle(
                              color: FarmColors.mutedText,
                              height: 1.3,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.lock_rounded,
                      color: FarmColors.green,
                      size: 20,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ...tickets.map(
                (ticket) => _AdminSupportInboxCard(
                  ticket: ticket,
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AdminSupportConversationScreen(
                          ticket: ticket,
                        ),
                      ),
                    );
                    onChanged();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AdminSupportInboxCard extends StatelessWidget {
  final SupportTicket ticket;
  final VoidCallback onTap;

  const _AdminSupportInboxCard({
    required this.ticket,
    required this.onTap,
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
    final assignedToMe = ticket.assignedStaffId?.trim() ==
        supabase.auth.currentUser?.id.trim();

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
                color: ticket.hasUnreadForStaff
                    ? FarmColors.green.withOpacity(0.48)
                    : FarmColors.line,
                width: ticket.hasUnreadForStaff ? 1.5 : 1,
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
                        Icons.person_outline_rounded,
                        color: FarmColors.green,
                      ),
                    ),
                    if (ticket.hasUnreadForStaff)
                      Positioned(
                        right: -1,
                        top: -1,
                        child: Container(
                          height: 12,
                          width: 12,
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
                                fontWeight: ticket.hasUnreadForStaff
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
                      const SizedBox(height: 4),
                      Text(
                        ticket.email.trim().isEmpty
                            ? 'Signed-in HPJ user'
                            : ticket.email.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: FarmColors.mutedText,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        ticket.preview,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ticket.hasUnreadForStaff
                              ? FarmColors.ink
                              : FarmColors.mutedText,
                          height: 1.28,
                          fontWeight: ticket.hasUnreadForStaff
                              ? FontWeight.w700
                              : FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock_rounded,
                                  size: 13, color: FarmColors.green),
                              SizedBox(width: 4),
                              Text(
                                'Private',
                                style: TextStyle(
                                  color: FarmColors.green,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                          if (assignedToMe)
                            const Text(
                              'Assigned to you',
                              style: TextStyle(
                                color: FarmColors.mutedText,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          if (time != null)
                            Text(
                              formatCustomerDateTime(time),
                              style: const TextStyle(
                                color: FarmColors.mutedText,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 5),
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

class AdminSupportConversationScreen extends StatefulWidget {
  final SupportTicket ticket;

  const AdminSupportConversationScreen({
    super.key,
    required this.ticket,
  });

  @override
  State<AdminSupportConversationScreen> createState() =>
      _AdminSupportConversationScreenState();
}

class _AdminSupportConversationScreenState
    extends State<AdminSupportConversationScreen> {
  final messageController = TextEditingController();
  bool sending = false;
  bool changingStatus = false;
  String? lastReadMessageId;

  @override
  void initState() {
    super.initState();
    unawaited(_prepareConversation());
  }

  Future<void> _prepareConversation() async {
    await claimSupportConversation(widget.ticket.id);
    await markSupportConversationRead(widget.ticket.id);
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  Future<void> sendMessage(SupportTicket ticket) async {
    final message = messageController.text.trim();
    if (message.isEmpty || sending) return;

    setState(() => sending = true);
    try {
      await sendSupportMessage(
        ticketId: ticket.id,
        message: message,
      );
      messageController.clear();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not send private reply: ${friendlyAppError(error)}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Future<void> setStatus(SupportTicket ticket, String status) async {
    if (changingStatus) return;
    setState(() => changingStatus = true);
    try {
      await updateSupportTicket(
        ticketId: ticket.id,
        status: status,
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not update status: ${friendlyAppError(error)}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => changingStatus = false);
    }
  }

  void markReadIfNeeded(List<SupportMessage> messages) {
    if (messages.isEmpty) return;
    SupportMessage? latestUser;
    for (final message in messages.reversed) {
      if (message.isFromUser) {
        latestUser = message;
        break;
      }
    }
    if (latestUser == null || latestUser.id == lastReadMessageId) return;
    lastReadMessageId = latestUser.id;
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
                const Text(
                  'Private Customer Care',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  '${ticket.subject} • #${ticket.shortId}',
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
                  margin: const EdgeInsets.fromLTRB(14, 6, 14, 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: FarmColors.line),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.lock_rounded,
                              size: 17, color: FarmColors.green),
                          const SizedBox(width: 7),
                          const Expanded(
                            child: Text(
                              'Visible only to this user and authorised Customer Care staff.',
                              style: TextStyle(
                                color: FarmColors.deepGreen,
                                fontSize: 11.5,
                                height: 1.25,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (ticket.email.trim().isNotEmpty)
                            Tooltip(
                              message: ticket.email.trim(),
                              child: const Icon(
                                Icons.person_outline_rounded,
                                color: FarmColors.mutedText,
                                size: 18,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _AdminSupportStatusChip(
                              label: 'Open',
                              selected: ticket.status.toLowerCase() == 'open',
                              enabled: !changingStatus,
                              onTap: () => setStatus(ticket, 'open'),
                            ),
                            const SizedBox(width: 7),
                            _AdminSupportStatusChip(
                              label: 'In progress',
                              selected:
                                  ticket.status.toLowerCase() == 'in_progress',
                              enabled: !changingStatus,
                              onTap: () => setStatus(ticket, 'in_progress'),
                            ),
                            const SizedBox(width: 7),
                            _AdminSupportStatusChip(
                              label: 'Resolved',
                              selected: <String>{'resolved', 'closed'}
                                  .contains(ticket.status.toLowerCase()),
                              enabled: !changingStatus,
                              onTap: () => setStatus(ticket, 'closed'),
                            ),
                          ],
                        ),
                      ),
                    ],
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
                        return const Center(child: CircularProgressIndicator());
                      }

                      final reversed = messages.reversed.toList();
                      return ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 18),
                        itemCount: reversed.length,
                        itemBuilder: (context, index) {
                          return _AdminSupportBubble(
                            message: reversed[index],
                            ticket: ticket,
                          );
                        },
                      );
                    },
                  ),
                ),
                _AdminSupportComposer(
                  controller: messageController,
                  sending: sending,
                  onSend: () => sendMessage(ticket),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AdminSupportStatusChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _AdminSupportStatusChip({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: enabled ? (_) => onTap() : null,
      selectedColor: FarmColors.primarySoft,
      backgroundColor: FarmColors.background,
      side: BorderSide(
        color: selected ? FarmColors.green : FarmColors.line,
      ),
      labelStyle: TextStyle(
        color: selected ? FarmColors.green : FarmColors.mutedText,
        fontWeight: FontWeight.w900,
        fontSize: 11.5,
      ),
    );
  }
}

class _AdminSupportBubble extends StatelessWidget {
  final SupportMessage message;
  final SupportTicket ticket;

  const _AdminSupportBubble({
    required this.message,
    required this.ticket,
  });

  @override
  Widget build(BuildContext context) {
    final fromStaff = message.isFromStaff;
    final createdAt = message.createdAt;
    final seenByCustomer = fromStaff &&
        createdAt != null &&
        ticket.customerLastReadAt != null &&
        !createdAt.isAfter(ticket.customerLastReadAt!);

    return Align(
      alignment: fromStaff ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        margin: const EdgeInsets.only(bottom: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!fromStaff) ...[
              Container(
                height: 30,
                width: 30,
                decoration: const BoxDecoration(
                  color: FarmColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
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
                  color: fromStaff ? FarmColors.green : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(fromStaff ? 20 : 5),
                    bottomRight: Radius.circular(fromStaff ? 5 : 20),
                  ),
                  border:
                      fromStaff ? null : Border.all(color: FarmColors.line),
                ),
                child: Column(
                  crossAxisAlignment: fromStaff
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    if (!fromStaff)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 4),
                        child: Text(
                          'HPJ user',
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
                        color: fromStaff ? Colors.white : FarmColors.ink,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      createdAt == null
                          ? (fromStaff ? 'Sent securely' : 'User')
                          : fromStaff
                              ? '${formatCustomerDateTime(createdAt)} • ${seenByCustomer ? 'Seen' : 'Sent'}'
                              : formatCustomerDateTime(createdAt),
                      style: TextStyle(
                        color: fromStaff
                            ? Colors.white.withOpacity(0.78)
                            : FarmColors.mutedText,
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

class _AdminSupportComposer extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  const _AdminSupportComposer({
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
        border: Border(top: BorderSide(color: FarmColors.line)),
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
                hintText: 'Reply privately...',
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
                  borderSide:
                      const BorderSide(color: FarmColors.green, width: 1.4),
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
                height: 48,
                width: 48,
                child: Center(
                  child: sending
                      ? const SizedBox(
                          height: 20,
                          width: 20,
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


class _AdminRecordFocusNotice extends StatelessWidget {
  final bool found;
  final String foundMessage;
  final String missingMessage;

  const _AdminRecordFocusNotice({
    required this.found,
    required this.foundMessage,
    required this.missingMessage,
  });

  @override
  Widget build(BuildContext context) {
    final accent = found
        ? FarmColors.primary
        : FarmColors.warning;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: found
            ? FarmColors.primarySoft
            : const Color(0xFFFFF7E8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: accent.withOpacity(0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            found
                ? Icons.notifications_active_outlined
                : Icons.info_outline_rounded,
            size: 18,
            color: accent,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              found ? foundMessage : missingMessage,
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
    );
  }
}

class AdminFarmerManagementTab extends StatelessWidget {
  final int refreshKey;
  final VoidCallback onChanged;
  final String? initialFarmerId;

  const AdminFarmerManagementTab({
    super.key,
    required this.refreshKey,
    required this.onChanged,
    this.initialFarmerId,
  });

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
        final farmers = snapshot.data ?? const <FarmerProfile>[];
        final requestedFarmerId = initialFarmerId?.trim() ?? '';

        final focusedFarmers = requestedFarmerId.isEmpty
            ? const <FarmerProfile>[]
            : farmers
                .where(
                  (farmer) => farmer.id.trim() == requestedFarmerId,
                )
                .toList();

        final exactFarmerFound = focusedFarmers.isNotEmpty;
        final visibleFarmers =
            exactFarmerFound ? focusedFarmers : farmers;

        final approved = farmers.where((f) => f.isApproved).length;
        final pending = farmers
            .where(
                (f) => f.verificationStatus.trim().toLowerCase() == 'pending')
            .length;
        final rejected = farmers
            .where(
                (f) => f.verificationStatus.trim().toLowerCase() == 'rejected')
            .length;

        final ordered = [...visibleFarmers]..sort((a, b) {
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
              if (requestedFarmerId.isNotEmpty) ...[
                _AdminRecordFocusNotice(
                  found: exactFarmerFound,
                  foundMessage:
                      'Opened from your notification. Showing the related farmer application.',
                  missingMessage:
                      'That farmer application is no longer available. Showing the current farmer list instead.',
                ),
                const SizedBox(height: 12),
              ],
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
// =====================================================
// RELEASE FARMER PAYOUT
// Requires a real payment reference.
// =====================================================

  Future<void> _releaseFarmerPayout(
    BuildContext context,
    FarmerPayout payout,
  ) async {
    if (payout.payoutStatus.trim().toLowerCase() == 'released') {
      return;
    }

    final referenceController = TextEditingController(
      text: payout.payoutReference,
    );

    bool saving = false;

    final released = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            Future<void> submit() async {
              if (saving) return;

              final reference = referenceController.text.trim();

              if (reference.isEmpty) {
                ScaffoldMessenger.of(
                  dialogContext,
                ).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Enter the payment transaction or transfer reference.',
                    ),
                  ),
                );

                return;
              }

              setDialogState(() {
                saving = true;
              });

              try {
                await updateFarmerPayoutStatus(
                  payoutId: payout.id,
                  status: 'released',
                  reference: reference,
                );

                if (!dialogContext.mounted) {
                  return;
                }

                Navigator.pop(
                  dialogContext,
                  true,
                );
              } catch (error) {
                if (!dialogContext.mounted) {
                  return;
                }

                setDialogState(() {
                  saving = false;
                });

                ScaffoldMessenger.of(
                  dialogContext,
                ).showSnackBar(
                  SnackBar(
                    content: Text(
                      friendlyAppError(
                        error,
                      ),
                    ),
                  ),
                );
              }
            }

            return AlertDialog(
              title: const Text(
                'Release Farmer Payout',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payout.isWholesaleReceiving
                          ? payout.productName
                          : 'Retail marketplace payout',
                      style: const TextStyle(
                        color: FarmColors.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    if (payout.isWholesaleReceiving &&
                        payout.quantityLabel.isNotEmpty)
                      Text(
                        '${payout.quantityLabel} accepted',
                        style: const TextStyle(
                          color: FarmColors.mutedText,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    const SizedBox(
                      height: 14,
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(
                        13,
                      ),
                      decoration: BoxDecoration(
                        color: FarmColors.primarySoft,
                        borderRadius: BorderRadius.circular(
                          14,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Amount to release',
                              style: TextStyle(
                                color: FarmColors.ink,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Text(
                            formatJmd(
                              payout.netAmount,
                            ),
                            style: const TextStyle(
                              color: FarmColors.green,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 14,
                    ),
                    Text(
                      payout.payoutMethod.trim().isEmpty
                          ? 'Payment method not provided'
                          : 'Payment method: ${payout.payoutMethod}',
                      style: const TextStyle(
                        color: FarmColors.mutedText,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    TextField(
                      controller: referenceController,
                      enabled: !saving,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Payment reference',
                        hintText:
                            'Bank transfer, transaction or receipt number',
                        prefixIcon: Icon(
                          Icons.tag_outlined,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    const Text(
                      'Only mark this payout released after the payment has actually been made.',
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
                  onPressed: saving
                      ? null
                      : () => Navigator.pop(
                            dialogContext,
                            false,
                          ),
                  child: const Text(
                    'Back',
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: saving ? null : submit,
                  icon: saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.verified_outlined,
                          size: 17,
                        ),
                  label: Text(
                    saving ? 'Releasing...' : 'Confirm Payment',
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    referenceController.dispose();

    if (released == true) {
      onChanged();

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${formatJmd(payout.netAmount)} farmer payout released.',
          ),
        ),
      );
    }
  }

  Widget _elitePayoutCard(BuildContext context, FarmerPayout payout) {
    final status = payout.payoutStatus.trim().toLowerCase();
    final statusColor = _statusColor(status);
    final isWholesale = payout.isWholesaleReceiving;

    final payoutTitle = isWholesale
        ? payout.productName.trim().isEmpty
            ? 'Wholesale Produce'
            : payout.productName
        : payout.orderId.trim().isEmpty
            ? 'Retail Payout'
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
                      payoutTitle,
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
                      isWholesale
                          ? '${payout.quantityLabel} • Wholesale farm supply'
                          : 'Created ${formatCustomerDateTime(payout.createdAt)}',
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
                      : () => _releaseFarmerPayout(
                            context,
                            payout,
                          ),
                  icon: const Icon(
                    Icons.verified_outlined,
                    size: 18,
                  ),
                  label: const Text(
                    'Release',
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: status == 'disputed' || status == 'released'
                      ? null
                      : () async {
                          await updateFarmerPayoutStatus(
                            payoutId: payout.id,
                            status: 'held',
                          );

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


// =====================================================
// ADMIN — AGRICULTURE INTELLIGENCE FEED
// =====================================================
class AdminAgricultureFeedTab extends StatefulWidget {
  final int refreshKey;
  final VoidCallback onChanged;

  const AdminAgricultureFeedTab({
    super.key,
    required this.refreshKey,
    required this.onChanged,
  });

  @override
  State<AdminAgricultureFeedTab> createState() =>
      _AdminAgricultureFeedTabState();
}

class _AdminAgricultureFeedTabState
    extends State<AdminAgricultureFeedTab> {
  int localRefreshKey = 0;

  void _refresh() {
    if (mounted) setState(() => localRefreshKey++);
    widget.onChanged();
  }

  String _categoryLabel(String value) {
    switch (value) {
      case 'official_notice':
        return 'Official Notice';
      case 'market_intelligence':
        return 'Market Intelligence';
      case 'hpj_update':
        return 'HPJ Update';
      case 'opportunity':
        return 'Opportunity';
      case 'education':
        return 'Farm Knowledge';
      case 'weather_alert':
        return 'Weather & Crop Alert';
      default:
        return 'Agriculture News';
    }
  }

  String _actionLabel(String value) {
    switch (value) {
      case 'external':
        return 'External link';
      case 'customer_shop':
        return 'Customer Shop';
      case 'customer_care':
        return 'Customer Care';
      case 'farmer_demand':
        return 'Farmer Demand';
      case 'farmer_supply':
        return 'Farmer Supply';
      case 'wholesale_shop':
        return 'Wholesale Shop';
      case 'wholesale_plan':
        return 'Planning Ahead';
      default:
        return 'No app action';
    }
  }

  Future<void> _openEditor([AgricultureFeedUpdate? existing]) async {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final summaryController =
        TextEditingController(text: existing?.summary ?? '');
    final sourceNameController =
        TextEditingController(text: existing?.sourceName ?? '');
    final sourceUrlController =
        TextEditingController(text: existing?.sourceUrl ?? '');
    final actionLabelController =
        TextEditingController(text: existing?.actionLabel ?? '');
    final actionIdController =
        TextEditingController(text: existing?.actionId ?? '');

    String? imageUrl = existing?.imageUrl;
    String category = existing?.category ?? 'agriculture_news';
    String priority = existing?.priority ?? 'normal';
    String actionType = existing?.actionType ?? 'none';
    final audiences = <String>{
      ...(existing?.audiences ?? const <String>[
        'customer',
        'farmer',
        'wholesale',
      ]),
    };
    bool isActive = existing?.isActive ?? true;
    bool saving = false;
    bool uploading = false;
    DateTime publishAt = existing?.publishAt ?? DateTime.now();
    DateTime? expiresAt = existing?.expiresAt;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> choosePublishDate() async {
              final picked = await showDatePicker(
                context: context,
                initialDate: publishAt.isBefore(DateTime.now())
                    ? DateTime.now()
                    : publishAt,
                firstDate: DateTime.now().subtract(const Duration(days: 1)),
                lastDate: DateTime.now().add(const Duration(days: 730)),
              );
              if (picked == null) return;
              setSheetState(() {
                publishAt = DateTime(
                  picked.year,
                  picked.month,
                  picked.day,
                  publishAt.hour,
                  publishAt.minute,
                );
              });
            }

            Future<void> chooseExpiryDate() async {
              final initial = expiresAt ?? publishAt.add(const Duration(days: 30));
              final picked = await showDatePicker(
                context: context,
                initialDate: initial,
                firstDate: publishAt.add(const Duration(days: 1)),
                lastDate: publishAt.add(const Duration(days: 730)),
              );
              if (picked == null) return;
              setSheetState(() {
                expiresAt = DateTime(
                  picked.year,
                  picked.month,
                  picked.day,
                  23,
                  59,
                );
              });
            }

            Future<void> uploadImage() async {
              try {
                final picked = await pickProductImageFromDevice();
                if (picked == null) return;
                setSheetState(() => uploading = true);
                final url = await uploadAgricultureFeedImageToStorage(picked);
                if (!context.mounted) return;
                setSheetState(() {
                  imageUrl = url;
                  uploading = false;
                });
              } catch (error) {
                if (context.mounted) {
                  setSheetState(() => uploading = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(friendlyAppError(error))),
                  );
                }
              }
            }

            Future<void> submit() async {
              if (saving || uploading) return;
              if (audiences.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Choose at least one audience.'),
                  ),
                );
                return;
              }

              setSheetState(() => saving = true);
              try {
                await saveAgricultureFeedUpdate(
                  id: existing?.id,
                  title: titleController.text,
                  summary: summaryController.text,
                  imageUrl: imageUrl,
                  category: category,
                  audiences: audiences.toList(),
                  priority: priority,
                  sourceName: sourceNameController.text,
                  sourceUrl: sourceUrlController.text,
                  actionLabel: actionLabelController.text,
                  actionType: actionType,
                  actionId: actionIdController.text,
                  isActive: isActive,
                  publishAt: publishAt,
                  expiresAt: expiresAt,
                );
                if (!context.mounted) return;
                Navigator.of(context).pop(true);
              } catch (error) {
                if (!context.mounted) return;
                setSheetState(() => saving = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(friendlyAppError(error))),
                );
              }
            }

            final media = MediaQuery.of(context);
            final bottom = media.viewInsets.bottom;
            final cleanImage = cleanHostedImageUrl(imageUrl);

            return Padding(
              padding: EdgeInsets.only(bottom: bottom),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: media.size.height * 0.94,
                ),
                decoration: const BoxDecoration(
                  color: FarmColors.background,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 14, 10, 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  existing == null
                                      ? 'Publish Feed Update'
                                      : 'Edit Feed Update',
                                  style: const TextStyle(
                                    color: FarmColors.ink,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                const Text(
                                  'Short, useful and verified agriculture information.',
                                  style: TextStyle(
                                    color: FarmColors.mutedText,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: saving
                                ? null
                                : () => Navigator.of(context).pop(false),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: titleController,
                              enabled: !saving,
                              maxLength: 120,
                              decoration: const InputDecoration(
                                labelText: 'Headline',
                                hintText: 'What should people know?',
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: summaryController,
                              enabled: !saving,
                              minLines: 3,
                              maxLines: 6,
                              maxLength: 800,
                              decoration: const InputDecoration(
                                labelText: 'Useful summary',
                                hintText:
                                    'Explain what changed and why it matters.',
                              ),
                            ),
                            const SizedBox(height: 10),
                            DropdownButtonFormField<String>(
                              value: category,
                              decoration:
                                  const InputDecoration(labelText: 'Category'),
                              items: const [
                                DropdownMenuItem(
                                  value: 'agriculture_news',
                                  child: Text('Agriculture News'),
                                ),
                                DropdownMenuItem(
                                  value: 'official_notice',
                                  child: Text('Official Notice'),
                                ),
                                DropdownMenuItem(
                                  value: 'market_intelligence',
                                  child: Text('Market Intelligence'),
                                ),
                                DropdownMenuItem(
                                  value: 'opportunity',
                                  child: Text('Opportunity'),
                                ),
                                DropdownMenuItem(
                                  value: 'weather_alert',
                                  child: Text('Weather & Crop Alert'),
                                ),
                                DropdownMenuItem(
                                  value: 'education',
                                  child: Text('Farm Knowledge'),
                                ),
                                DropdownMenuItem(
                                  value: 'hpj_update',
                                  child: Text('HPJ Update'),
                                ),
                              ],
                              onChanged: saving
                                  ? null
                                  : (value) {
                                      if (value != null) {
                                        setSheetState(() => category = value);
                                      }
                                    },
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Who should see this?',
                              style: TextStyle(
                                color: FarmColors.ink,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: const <MapEntry<String, String>>[
                                MapEntry('customer', 'Customers'),
                                MapEntry('farmer', 'Farmers'),
                                MapEntry('wholesale', 'Businesses'),
                              ].map((entry) {
                                return FilterChip(
                                  label: Text(entry.value),
                                  selected: audiences.contains(entry.key),
                                  onSelected: saving
                                      ? null
                                      : (selected) {
                                          setSheetState(() {
                                            if (selected) {
                                              audiences.add(entry.key);
                                            } else {
                                              audiences.remove(entry.key);
                                            }
                                          });
                                        },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Priority',
                              style: TextStyle(
                                color: FarmColors.ink,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Wrap(
                              spacing: 8,
                              children: const <MapEntry<String, String>>[
                                MapEntry('normal', 'Normal'),
                                MapEntry('important', 'Important'),
                                MapEntry('urgent', 'Urgent'),
                              ].map((entry) {
                                return ChoiceChip(
                                  label: Text(entry.value),
                                  selected: priority == entry.key,
                                  onSelected: saving
                                      ? null
                                      : (_) => setSheetState(
                                            () => priority = entry.key,
                                          ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16),
                            if (cleanImage != null) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: AspectRatio(
                                  aspectRatio: 16 / 8,
                                  child: Image.network(
                                    cleanImage,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      color: FarmColors.primarySoft,
                                      child: const Icon(
                                        Icons.broken_image_outlined,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: saving || uploading
                                        ? null
                                        : uploadImage,
                                    icon: uploading
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(Icons.add_photo_alternate),
                                    label: Text(
                                      uploading
                                          ? 'Uploading...'
                                          : cleanImage == null
                                              ? 'Add image'
                                              : 'Replace image',
                                    ),
                                  ),
                                ),
                                if (cleanImage != null) ...[
                                  const SizedBox(width: 8),
                                  IconButton(
                                    tooltip: 'Remove image',
                                    onPressed: saving
                                        ? null
                                        : () => setSheetState(
                                              () => imageUrl = null,
                                            ),
                                    icon: const Icon(Icons.delete_outline),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: sourceNameController,
                              enabled: !saving,
                              decoration: const InputDecoration(
                                labelText: 'Source name (recommended)',
                                hintText: 'e.g. Ministry of Agriculture',
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: sourceUrlController,
                              enabled: !saving,
                              keyboardType: TextInputType.url,
                              decoration: const InputDecoration(
                                labelText: 'Source link (optional)',
                                hintText: 'https://...',
                              ),
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: actionType,
                              decoration: const InputDecoration(
                                labelText: 'Optional HPJ action',
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'none',
                                  child: Text('No app action'),
                                ),
                                DropdownMenuItem(
                                  value: 'external',
                                  child: Text('Open source link'),
                                ),
                                DropdownMenuItem(
                                  value: 'customer_shop',
                                  child: Text('Customer Shop'),
                                ),
                                DropdownMenuItem(
                                  value: 'customer_care',
                                  child: Text('Customer Care'),
                                ),
                                DropdownMenuItem(
                                  value: 'farmer_demand',
                                  child: Text('Farmer Demand'),
                                ),
                                DropdownMenuItem(
                                  value: 'farmer_supply',
                                  child: Text('Farmer Supply'),
                                ),
                                DropdownMenuItem(
                                  value: 'wholesale_shop',
                                  child: Text('Wholesale Shop'),
                                ),
                                DropdownMenuItem(
                                  value: 'wholesale_plan',
                                  child: Text('Planning Ahead'),
                                ),
                              ],
                              onChanged: saving
                                  ? null
                                  : (value) {
                                      if (value != null) {
                                        setSheetState(() => actionType = value);
                                      }
                                    },
                            ),
                            if (actionType != 'none') ...[
                              const SizedBox(height: 10),
                              TextField(
                                controller: actionLabelController,
                                enabled: !saving,
                                decoration: InputDecoration(
                                  labelText: 'Button label',
                                  hintText: actionType == 'external'
                                      ? 'Learn more'
                                      : 'Open in HPJ',
                                ),
                              ),
                            ],
                            if (actionType != 'none' &&
                                actionType != 'external') ...[
                              const SizedBox(height: 10),
                              TextField(
                                controller: actionIdController,
                                enabled: !saving,
                                decoration: const InputDecoration(
                                  labelText: 'Optional item ID',
                                  hintText:
                                      'Leave blank to open the main destination.',
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.schedule_outlined),
                              title: const Text('Publish date'),
                              subtitle: Text(formatCustomerDateTime(publishAt)),
                              trailing: const Icon(Icons.edit_calendar_outlined),
                              onTap: saving ? null : choosePublishDate,
                            ),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.event_busy_outlined),
                              title: const Text('Expiry'),
                              subtitle: Text(
                                expiresAt == null
                                    ? 'No automatic expiry'
                                    : formatCustomerDateTime(expiresAt),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (expiresAt != null)
                                    IconButton(
                                      tooltip: 'Remove expiry',
                                      onPressed: saving
                                          ? null
                                          : () => setSheetState(
                                                () => expiresAt = null,
                                              ),
                                      icon: const Icon(Icons.clear_rounded),
                                    ),
                                  const Icon(Icons.edit_calendar_outlined),
                                ],
                              ),
                              onTap: saving ? null : chooseExpiryDate,
                            ),
                            SwitchListTile.adaptive(
                              value: isActive,
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Visible when published'),
                              subtitle: const Text(
                                'Turn off to keep this update hidden.',
                              ),
                              onChanged: saving
                                  ? null
                                  : (value) =>
                                      setSheetState(() => isActive = value),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: saving || uploading ? null : submit,
                            icon: saving
                                ? const SizedBox(
                                    width: 17,
                                    height: 17,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.publish_rounded),
                            label: Text(
                              saving
                                  ? 'Saving...'
                                  : existing == null
                                      ? 'Publish Update'
                                      : 'Save Changes',
                            ),
                          ),
                        ),
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

    titleController.dispose();
    summaryController.dispose();
    sourceNameController.dispose();
    sourceUrlController.dispose();
    actionLabelController.dispose();
    actionIdController.dispose();

    if (saved == true && mounted) _refresh();
  }

  Future<void> _toggle(AgricultureFeedUpdate update) async {
    try {
      await setAgricultureFeedUpdateActive(
        id: update.id,
        isActive: !update.isActive,
      );
      if (mounted) _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyAppError(error))),
      );
    }
  }

  Future<void> _delete(AgricultureFeedUpdate update) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this feed update?'),
        content: Text(
          '“${update.title}” will be permanently removed from HPJ.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await deleteAgricultureFeedUpdate(update.id);
      if (mounted) _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyAppError(error))),
      );
    }
  }

  String _status(AgricultureFeedUpdate update) {
    final now = DateTime.now();
    if (!update.isActive) return 'Hidden';
    if (update.publishAt.isAfter(now)) return 'Scheduled';
    if (update.expiresAt != null && !update.expiresAt!.isAfter(now)) {
      return 'Expired';
    }
    return 'Live';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AgricultureFeedUpdate>>(
      key: ValueKey('${widget.refreshKey}-$localRefreshKey'),
      future: fetchAdminAgricultureFeedUpdates(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const SkeletonList(count: 4);
        }
        if (snapshot.hasError && !snapshot.hasData) {
          return Center(child: Text(friendlyAppError(snapshot.error!)));
        }

        final updates = snapshot.data ?? const <AgricultureFeedUpdate>[];
        return RefreshIndicator(
          onRefresh: () async => _refresh(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 120),
            children: [
              HpjJamaicaMarketPulseSection(
                audience: 'admin',
                refreshKey: widget.refreshKey + localRefreshKey,
                limit: 12,
                adminMode: true,
              ),
              const SizedBox(height: 14),
              FarmCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: FarmColors.primarySoft,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.public_rounded,
                            color: FarmColors.primary,
                          ),
                        ),
                        const SizedBox(width: 11),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Agriculture Intelligence Feed',
                                style: TextStyle(
                                  color: FarmColors.ink,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Publish verified news, market intelligence, opportunities and HPJ updates to the right audience.',
                                style: TextStyle(
                                  color: FarmColors.mutedText,
                                  fontSize: 10.6,
                                  height: 1.35,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 13),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _openEditor(),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Publish Feed Update'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (updates.isEmpty)
                const FarmEmptyState(
                  icon: Icons.dynamic_feed_outlined,
                  title: 'No feed updates yet',
                  message:
                      'Publish the first useful agriculture update for HPJ users.',
                )
              else
                ...updates.map((update) {
                  final status = _status(update);
                  final cleanImage = cleanHostedImageUrl(update.imageUrl);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: FarmCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (cleanImage != null) ...[
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    cleanImage,
                                    width: 74,
                                    height: 74,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 74,
                                      height: 74,
                                      color: FarmColors.primarySoft,
                                      child: const Icon(Icons.image_outlined),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 11),
                              ],
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: [
                                        Chip(label: Text(status)),
                                        Chip(
                                          label: Text(
                                            _categoryLabel(update.category),
                                          ),
                                        ),
                                        if (update.priority != 'normal')
                                          Chip(
                                            label: Text(
                                              update.priority.toUpperCase(),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      update.title,
                                      style: const TextStyle(
                                        color: FarmColors.ink,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      update.summary,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: FarmColors.mutedText,
                                        fontSize: 10.5,
                                        height: 1.35,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 9),
                          Text(
                            'Audience: ${update.audiences.map((item) => item == 'customer' ? 'Customers' : item == 'farmer' ? 'Farmers' : 'Businesses').join(' • ')}',
                            style: const TextStyle(
                              color: FarmColors.mutedText,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Publish: ${formatCustomerDateTime(update.publishAt)} • Action: ${_actionLabel(update.actionType)}',
                            style: const TextStyle(
                              color: FarmColors.mutedText,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _openEditor(update),
                                  icon: const Icon(Icons.edit_outlined, size: 17),
                                  label: const Text('Edit'),
                                ),
                              ),
                              const SizedBox(width: 7),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _toggle(update),
                                  icon: Icon(
                                    update.isActive
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    size: 17,
                                  ),
                                  label: Text(
                                    update.isActive ? 'Hide' : 'Show',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 7),
                              IconButton(
                                tooltip: 'Delete update',
                                onPressed: () => _delete(update),
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: FarmColors.danger,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}
