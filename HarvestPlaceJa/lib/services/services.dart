part of harvest_place_app;

String _safeProductImageFileName(String fileName) {
  final clean = fileName.trim().toLowerCase();
  final sanitized = clean
      .replaceAll(RegExp(r'[^a-z0-9._-]+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^[-.]+|[-.]+$'), '');

  if (sanitized.isEmpty) return 'product-image.jpg';
  return sanitized.length > 90
      ? sanitized.substring(sanitized.length - 90)
      : sanitized;
}

Future<String> uploadProductImageToStorage(PickedProductImage image) async {
  await requireAdminAccess();

  if (image.bytes.isEmpty) {
    throw Exception('Choose a valid image file.');
  }

  const maxBytes = 6 * 1024 * 1024;
  if (image.bytes.length > maxBytes) {
    throw Exception('Image is too large. Please upload an image under 6 MB.');
  }

  final userId = supabase.auth.currentUser?.id ?? 'admin';
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final safeName = _safeProductImageFileName(image.fileName);
  final path = 'products/$userId/$timestamp-$safeName';
  final contentType = _contentTypeForImage(image);

  try {
    await supabase.storage.from(productImageStorageBucket).uploadBinary(
          path,
          image.bytes,
          fileOptions: FileOptions(
            contentType: contentType,
            upsert: true,
          ),
        );

    return supabase.storage.from(productImageStorageBucket).getPublicUrl(path);
  } catch (error) {
    final message = error.toString().toLowerCase();
    if (message.contains('bucket') || message.contains('not found')) {
      throw Exception(
        'Image storage is not ready. Please finish the image upload setup.',
      );
    }
    if (message.contains('permission') ||
        message.contains('policy') ||
        message.contains('403') ||
        message.contains('401')) {
      throw Exception(
        'Image upload permission is not ready. Please review the admin upload setup.',
      );
    }
    throw Exception('Could not upload image: ${friendlyAppError(error)}');
  }
}

Future<List<HomeHeroSlide>> fetchHomeHeroSlides() async {
  try {
    final response = await supabase
        .from('home_hero_slides')
        .select(
            'id, position, image_url, title, subtitle, is_active, updated_at')
        .eq('is_active', true)
        .order('position', ascending: true)
        .limit(3);

    final slides = (response as List)
        .map(
            (row) => HomeHeroSlide.fromSupabase(Map<String, dynamic>.from(row)))
        .toList();

    return _cleanHomeHeroSlides(slides);
  } catch (error) {
    debugPrintOnce('home-hero-slides-fallback',
        'Home hero slides table unavailable, using default images: $error');
    return defaultHomeHeroSlides();
  }
}

Future<String> uploadHomeHeroImageToStorage({
  required int position,
  required PickedProductImage image,
}) async {
  await requireAdminAccess();

  if (image.bytes.isEmpty) {
    throw Exception('Choose a valid image file.');
  }

  const maxBytes = 6 * 1024 * 1024;
  if (image.bytes.length > maxBytes) {
    throw Exception('Image is too large. Please upload an image under 6 MB.');
  }

  final userId = supabase.auth.currentUser?.id ?? 'admin';
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final safeName = _safeProductImageFileName(image.fileName);
  final path = 'home-hero/slide-$position/$userId/$timestamp-$safeName';
  final contentType = _contentTypeForImage(image);

  try {
    await supabase.storage.from(productImageStorageBucket).uploadBinary(
          path,
          image.bytes,
          fileOptions: FileOptions(
            contentType: contentType,
            upsert: true,
          ),
        );

    return supabase.storage.from(productImageStorageBucket).getPublicUrl(path);
  } catch (error) {
    final message = error.toString().toLowerCase();
    if (message.contains('bucket') || message.contains('not found')) {
      throw Exception(
        'Image storage is not ready. Please finish the image upload setup.',
      );
    }
    if (message.contains('permission') ||
        message.contains('policy') ||
        message.contains('403') ||
        message.contains('401')) {
      throw Exception(
        'Hero image upload permission is not ready. Please review the admin upload setup.',
      );
    }
    throw Exception('Could not upload hero image: ${friendlyAppError(error)}');
  }
}

Future<void> saveHomeHeroSlideImage({
  required int position,
  required String imageUrl,
}) async {
  await requireAdminAccess();

  final cleanUrl = cleanHostedImageUrl(imageUrl);
  if (cleanUrl == null) {
    throw Exception('Upload or paste a valid image URL.');
  }

  final payload = {
    'position': position,
    'image_url': cleanUrl,
    'is_active': true,
    'updated_at': DateTime.now().toIso8601String(),
  };

  try {
    await supabase.from('home_hero_slides').upsert(
          payload,
          onConflict: 'position',
        );
  } catch (error) {
    throw Exception(
      'Hero slideshow is not ready. Please complete the hero image setup before saving.',
    );
  }
}

Widget productImagePreviewFromUrl({
  required String? imageUrl,
  double height = 130,
}) {
  final cleanUrl = cleanHostedImageUrl(imageUrl);

  Widget fallbackPreview() {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: FarmColors.cardSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: FarmColors.line),
      ),
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          size: 44,
          color: FarmColors.mutedText,
        ),
      ),
    );
  }

  if (cleanUrl == null) return fallbackPreview();

  return ClipRRect(
    borderRadius: BorderRadius.circular(18),
    child: Container(
      height: height,
      width: double.infinity,
      color: FarmColors.cardSoft,
      alignment: Alignment.center,
      child: Image.network(
        cleanUrl,
        height: height,
        width: double.infinity,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
        cacheWidth: 700,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            height: height,
            width: double.infinity,
            color: FarmColors.cardSoft,
            child: const Center(child: CircularProgressIndicator()),
          );
        },
        errorBuilder: (_, __, ___) => fallbackPreview(),
      ),
    ),
  );
}

Future<bool> requestBrowserNotifications() async {
  final granted = await browser_notifications.requestBrowserNotifications();

  if (granted) {
    farmDebugLog('Browser notifications granted');
    await saveNotificationPreference(enabled: true);
  } else {
    farmDebugLog('Browser notifications denied');
  }

  return granted;
}

void showBrowserNotification({
  required String title,
  required String body,
  String? orderId,
  String? type,
}) {
  final cleanTitle = title.trim();
  final cleanBody = body.trim();

  if (cleanTitle.isEmpty && cleanBody.isEmpty) {
    farmDebugLog('Browser notification skipped');
    return;
  }

  final tag = browserNotificationTag(
    title: cleanTitle,
    body: cleanBody,
    orderId: orderId,
    type: type,
  );

  if (!_shownBrowserNotificationTags.add(tag)) {
    farmDebugLog('Browser notification skipped');
    return;
  }

  browser_notifications.showBrowserNotification(
    title: cleanTitle.isEmpty ? AppConfig.appName : cleanTitle,
    body: cleanBody,
    tag: tag,
  );
}

bool notificationTargetsCurrentUser({
  String? userId,
  String? userEmail,
}) {
  if (!isLoggedIn) return false;

  final currentUser = supabase.auth.currentUser;
  final currentUserId = currentUser?.id.trim();
  final currentEmail = currentUser?.email?.trim().toLowerCase();

  final cleanUserId = userId?.trim();
  final cleanEmail = userEmail?.trim().toLowerCase();

  if (cleanUserId != null &&
      cleanUserId.isNotEmpty &&
      currentUserId != null &&
      cleanUserId == currentUserId) {
    return true;
  }

  if (cleanEmail != null &&
      cleanEmail.isNotEmpty &&
      currentEmail != null &&
      currentEmail.isNotEmpty &&
      cleanEmail == currentEmail) {
    return true;
  }

  return false;
}

void showBrowserNotificationForTarget({
  required String title,
  required String message,
  required String type,
  String? userId,
  String? userEmail,
  String? orderId,
}) {
  if (!notificationTargetsCurrentUser(
    userId: userId,
    userEmail: userEmail,
  )) {
    farmDebugLog('Browser notification skipped');
    return;
  }

  if (!isImportantBrowserNotification(
    title: title,
    message: message,
    type: type,
  )) {
    farmDebugLog('Browser notification skipped');
    return;
  }

  showBrowserNotification(
    title: title,
    body: message,
    orderId: orderId,
    type: type,
  );
}

bool notificationRowTargetsCurrentUser(Map<String, dynamic> row) {
  return notificationTargetsCurrentUser(
    userId: row['user_id']?.toString(),
    userEmail: row['user_email']?.toString(),
  );
}

Future<bool> farmNotificationAlreadyExists({
  required String title,
  required String type,
  String? userId,
  String? userEmail,
  String? orderId,
}) async {
  final cleanOrderId = orderId?.trim();
  if (cleanOrderId == null || cleanOrderId.isEmpty) return false;

  final cleanUserId = userId?.trim();
  final cleanEmail = userEmail?.trim().toLowerCase();

  try {
    var query = supabase
        .from('notifications')
        .select('id')
        .eq('order_id', cleanOrderId)
        .eq('type', type)
        .eq('title', title);

    if (cleanUserId != null && cleanUserId.isNotEmpty) {
      query = query.eq('user_id', cleanUserId);
    } else if (cleanEmail != null && cleanEmail.isNotEmpty) {
      query = query.eq('user_email', cleanEmail);
    }

    final existing = await query.limit(1);
    return (existing as List).isNotEmpty;
  } catch (error) {
    // Older notification tables may not have order_id/user_id. In that case,
    // keep the existing compatibility path and let the insert/fallback run.
    debugPrintOnce(
      'notification_duplicate_lookup_unavailable',
      'Notification duplicate lookup skipped. Continuing with normal insert.',
    );
    return false;
  }
}

Future<void> saveNotificationPreference({required bool enabled}) async {
  if (!isLoggedIn) return;

  final user = supabase.auth.currentUser;
  if (user == null) return;

  try {
    await supabase.from('notification_preferences').upsert({
      'user_id': user.id,
      'email': user.email,
      'browser_notifications_enabled': enabled,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id');
  } catch (error) {
    farmDebugLog('Notification preference save skipped: $error');
  }
}

Future<SecureCartQuote> fetchSecureCartQuote(List<CartLine> lines) async {
  final validLines = lines
      .where((line) => line.product.id.trim().isNotEmpty && line.quantity > 0)
      .toList();

  if (validLines.isEmpty) {
    throw Exception('Your farm box is empty.');
  }

  final ids = validLines.map((line) => line.product.id).toSet().toList();

  final response = await supabase
      .from('products')
      .select(
          'id, name, price, stock_quantity, is_available, approval_status, original_price, discount_price, discount_percent, discount_label, discount_starts_at, discount_ends_at, is_discount_active, product_status, ready_soon, estimated_ready_date, expected_stock_quantity, is_deal_of_day, deal_rank, subscribe_save_enabled, subscribe_save_discount_percent')
      .inFilter('id', ids);

  final rowsById = <String, Map<String, dynamic>>{};
  for (final row in response as List) {
    final data = Map<String, dynamic>.from(row as Map);
    rowsById[(data['id'] ?? '').toString()] = data;
  }

  final quoteLines = <SecureCartLineQuote>[];

  for (final line in validLines) {
    final row = rowsById[line.product.id];
    if (row == null) {
      throw Exception('${line.product.name} is no longer available.');
    }

    final serverProduct = Product.fromSupabase(row);
    final stock = serverProduct.stockQuantity;
    final serverPrice = serverProduct.effectivePrice;

    if (serverProduct.approvalStatus.trim().toLowerCase() != 'approved') {
      throw Exception(
          '${line.product.name} is not available for checkout yet.');
    }

    if (serverProduct.isHidden) {
      throw Exception(
          '${line.product.name} is no longer available in the shop.');
    }

    if (serverProduct.isReadySoon) {
      throw Exception(
          '${line.product.name} is harvesting soon and cannot be checked out yet.');
    }

    if (!serverProduct.isAvailable || stock <= 0) {
      throw Exception(
          '${line.product.name} is out of stock. Please remove it from your box before checkout.');
    }

    final isAvailable = serverProduct.canAddToCart;

    if (line.quantity > stock) {
      throw Exception(
        'Only $stock ${line.product.name} available. Please reduce the quantity before checkout.',
      );
    }

    quoteLines.add(
      SecureCartLineQuote(
        product: serverProduct,
        quantity: line.quantity,
        unitPrice: serverPrice,
        availableStock: stock,
        isAvailable: isAvailable,
      ),
    );
  }

  return SecureCartQuote(lines: quoteLines);
}

String loyaltyTierForPoints(int lifetimePoints) {
  if (lifetimePoints >= 1000) return 'Platinum';
  if (lifetimePoints >= 500) return 'Gold';
  return 'Green';
}

Future<LoyaltySummary> fetchLoyaltySummary() async {
  if (!isLoggedIn) {
    return const LoyaltySummary(points: 0, lifetimePoints: 0, tier: 'Green');
  }

  final user = supabase.auth.currentUser;
  if (user == null) {
    return const LoyaltySummary(points: 0, lifetimePoints: 0, tier: 'Green');
  }

  try {
    final response = await supabase
        .from('customer_loyalty_points')
        .select('points, lifetime_points, tier')
        .eq('user_id', user.id)
        .maybeSingle();

    if (response != null) {
      final points = Product._toInt(response['points']);
      final lifetime = Product._toInt(response['lifetime_points']);
      final tier =
          (response['tier'] ?? loyaltyTierForPoints(lifetime)).toString();

      return LoyaltySummary(
        points: points,
        lifetimePoints: lifetime,
        tier: tier,
      );
    }
  } catch (error) {
    farmDebugLog('Loyalty table unavailable, using paid order estimate: $error');
  }

  try {
    final orders = await fetchOrders();
    final paidTotal = orders
        .where((order) => order.paymentStatus == 'paid')
        .fold<double>(0, (sum, order) => sum + order.total);
    final points = (paidTotal / 100).floor();
    return LoyaltySummary(
      points: points,
      lifetimePoints: points,
      tier: loyaltyTierForPoints(points),
    );
  } catch (_) {
    return const LoyaltySummary(points: 0, lifetimePoints: 0, tier: 'Green');
  }
}

Future<void> awardLoyaltyPointsForOrder({
  required String orderId,
  required double total,
}) async {
  if (!isLoggedIn) return;

  final user = supabase.auth.currentUser;
  if (user == null || orderId.isEmpty || total <= 0) return;

  final points = (total / 100).floor();
  if (points <= 0) return;

  try {
    await supabase.rpc('award_loyalty_points', params: {
      'p_user_id': user.id,
      'p_order_id': orderId,
      'p_points': points,
      'p_reason': 'order',
    });
  } catch (rpcError) {
    farmDebugLog(
        'Loyalty RPC unavailable, using safe client fallback: $rpcError');

    // Loyalty points should not block checkout. Stock is already reduced
    // inside the secure_checkout RPC before this runs.
    try {
      await supabase.from('loyalty_transactions').insert({
        'user_id': user.id,
        'order_id': orderId,
        'points': points,
        'reason': 'order',
      });
    } catch (error) {
      farmDebugLog('Loyalty award skipped: $error');
    }
  }
}

Future<ProductTraceRecord?> fetchTraceRecordByCode(String code) async {
  final cleanCode = code.trim().toUpperCase();
  if (cleanCode.isEmpty) return null;

  try {
    final response = await supabase
        .from('product_trace_records')
        .select(
            'id, trace_code, product_name, farm_location, harvest_date, harvest_time, farmer_name, farming_method, batch_notes, qr_scan_count')
        .eq('trace_code', cleanCode)
        .maybeSingle();

    if (response == null) return null;

    final record = ProductTraceRecord.fromSupabase(
      Map<String, dynamic>.from(response),
    );

    await supabase
        .from('product_trace_records')
        .update({'qr_scan_count': record.qrScanCount + 1}).eq('id', record.id);

    return record;
  } catch (error) {
    farmDebugLog('Trace lookup failed: $error');
    return null;
  }
}

Future<List<ProductTraceRecord>> fetchTraceRecordsForProductName(
    String productName) async {
  final cleanName = productName.trim();
  if (cleanName.isEmpty) return [];

  try {
    final response = await supabase
        .from('product_trace_records')
        .select(
            'id, trace_code, product_name, farm_location, harvest_date, harvest_time, farmer_name, farming_method, batch_notes, qr_scan_count')
        .ilike('product_name', '%$cleanName%')
        .order('harvest_date', ascending: false)
        .limit(5);

    return (response as List)
        .map((item) =>
            ProductTraceRecord.fromSupabase(Map<String, dynamic>.from(item)))
        .toList();
  } catch (error) {
    farmDebugLog('Product trace lookup failed: $error');
    return [];
  }
}

Future<List<ProductTraceRecord>> traceRecordsForProduct(Product product) async {
  // Only return real trace records from Supabase. Generated profiles must not look verified.
  return fetchTraceRecordsForProductName(product.name);
}

Future<List<ProductTraceRecord>> fetchAllProductTraceRecords() async {
  try {
    final response = await supabase
        .from('product_trace_records')
        .select(
            'id, trace_code, product_name, farm_location, harvest_date, harvest_time, farmer_name, farming_method, batch_notes, qr_scan_count')
        .order('harvest_date', ascending: false)
        .limit(500);

    return (response as List)
        .map((item) =>
            ProductTraceRecord.fromSupabase(Map<String, dynamic>.from(item)))
        .toList();
  } catch (error) {
    farmDebugLog('All product trace lookup failed: $error');
    return [];
  }
}

Future<List<ProductTraceOverviewItem>>
    fetchTraceOverviewForAllProducts() async {
  final products = await fetchProducts();
  final traceRecords = await fetchAllProductTraceRecords();

  final visibleProducts = products;

  return visibleProducts.map((product) {
    final productName = product.name.trim().toLowerCase();

    final matches = traceRecords
        .where((record) {
          final recordName = record.productName.trim().toLowerCase();
          if (productName.isEmpty || recordName.isEmpty) return false;
          return recordName.contains(productName) ||
              productName.contains(recordName);
        })
        .take(5)
        .toList();

    return ProductTraceOverviewItem(
      product: product,
      records: matches,
    );
  }).toList();
}

String buildSalesCsv(List<AdminOrder> orders) {
  final rows = <String>[
    'Order ID,Customer,Phone,Fulfillment,Payment Method,Payment Status,Order Status,Total,Date',
  ];

  for (final order in orders) {
    rows.add([
      order.shortId,
      order.customerName.replaceAll(',', ' '),
      order.customerPhone.replaceAll(',', ' '),
      order.formattedType,
      order.formattedPaymentMethod,
      order.formattedPaymentStatus,
      _friendlyStatus(order.status),
      order.total.toStringAsFixed(2),
      order.createdAt?.toIso8601String() ?? '',
    ].join(','));
  }

  return rows.join('\n');
}

String buildSalesReportText(List<AdminOrder> orders) {
  final paidOrders =
      orders.where((order) => order.paymentStatus == 'paid').toList();
  final unpaidOrders =
      orders.where((order) => order.paymentStatus != 'paid').toList();
  final paidTotal =
      paidOrders.fold<double>(0, (sum, order) => sum + order.total);
  final allTotal = orders.fold<double>(0, (sum, order) => sum + order.total);

  return '''
The Harvest Place Ja Sales Report

Total Orders: ${orders.length}
Paid Orders: ${paidOrders.length}
Unpaid Orders: ${unpaidOrders.length}
Gross Total: J\$${allTotal.toStringAsFixed(2)}
Paid Total: J\$${paidTotal.toStringAsFixed(2)}

CSV Export:
${buildSalesCsv(orders)}
''';
}

String productUnitOriginLabel(Product product) {
  final unit = (product.unit ?? '').trim();
  final origin = product.originLabel;
  if (unit.isEmpty) return origin;
  return '$unit • $origin';
}

Color productOriginColor(Product product) {
  return product.isLocal ? FarmColors.green : FarmColors.warning;
}

Color productOriginBackground(Product product) {
  return product.isLocal ? FarmColors.lightGreen : FarmColors.warningSoft;
}

IconData productOriginIcon(Product product) {
  return product.isLocal ? Icons.eco_outlined : Icons.public_outlined;
}

int compareCustomerProductAvailabilityThenName(Product a, Product b) {
  if (a.canAddToCart != b.canAddToCart) {
    return a.canAddToCart ? -1 : 1;
  }

  return a.name.toLowerCase().compareTo(b.name.toLowerCase());
}

List<Product> uniqueVisibleProducts(
  Iterable<Product> products, {
  int limit = 10,
  Set<String>? excludeIds,
}) {
  final excluded = excludeIds ?? <String>{};
  final seen = <String>{};
  final output = <Product>[];

  for (final product in products) {
    final id = product.id.trim();
    if (id.isEmpty) continue;
    if (excluded.contains(id)) continue;
    if (!isVisibleCustomerProduct(product)) continue;
    if (!seen.add(id)) continue;
    output.add(product);
    if (output.length >= limit) break;
  }

  return output;
}

List<Product> refreshProductSnapshotsFromLatestProducts({
  required List<Product> savedProducts,
  required List<Product> latestProducts,
  int limit = 10,
}) {
  if (savedProducts.isEmpty) return const <Product>[];

  final latestById = <String, Product>{
    for (final product in latestProducts)
      if (product.id.trim().isNotEmpty) product.id.trim(): product,
  };

  final refreshed = savedProducts.map((product) {
    final id = product.id.trim();
    return latestById[id] ?? product;
  }).toList();

  return uniqueVisibleProducts(refreshed, limit: limit);
}

bool areSameProductLists(List<Product> a, List<Product> b) {
  final cleanA = cleanRecentlyViewedProducts(a);
  final cleanB = cleanRecentlyViewedProducts(b);

  if (cleanA.isEmpty || cleanB.isEmpty) return false;
  if (cleanA.length != cleanB.length) return false;

  for (var i = 0; i < cleanA.length; i++) {
    if (cleanA[i].id != cleanB[i].id) return false;
  }

  return true;
}

Future<void> clearPrivateSessionStateForGuestBrowsing() async {
  FarmDataCache.clearAll();

  if (hasSupabaseSession) {
    try {
      await supabase.auth.signOut();
    } catch (error) {
      farmDebugLog('Supabase sign out skipped while entering guest mode: $error');
    }
  }

  _clearSupabaseAuthStorageForGuestBrowsing();
}

// Backward-compatible helper name for guest browsing.
// Keep this wrapper so older call sites can still clear the private session
// before showing the public market.
Future<void> clearStoredSupabaseSessionForGuest() {
  return clearPrivateSessionStateForGuestBrowsing();
}

Future<List<Product>> fetchProducts({bool forceRefresh = false}) async {
  if (!forceRefresh) {
    final cached = FarmDataCache.products;
    if (cached != null) return cached;
  }
  final products = await _fetchProductsUncached();
  FarmDataCache.products = products;
  return products;
}

Future<List<Product>> fetchProductsForCustomerUi({
  bool forceRefresh = false,
  Duration timeout = const Duration(seconds: 12),
}) async {
  final cached = FarmDataCache.products;

  try {
    final products = await fetchProducts(forceRefresh: forceRefresh).timeout(
      timeout,
      onTimeout: () => cached ?? const <Product>[],
    );

    if (products.isEmpty && cached != null && cached.isNotEmpty) {
      return cached;
    }

    return products;
  } catch (error) {
    farmDebugLog('Product load fallback used: $error');
    return cached ?? const <Product>[];
  }
}

Future<List<Product>> _fetchProductsUncached() async {
  final extendedSelect =
      'id, name, description, price, unit, image_url, is_available, stock_quantity, created_at, category, is_organic, is_local, harvest_date, farmer_id, farmer_name, farm_name, parish, approval_status, platform_commission_percent, original_price, discount_price, discount_percent, discount_label, discount_starts_at, discount_ends_at, is_discount_active, product_status, ready_soon, estimated_ready_date, expected_stock_quantity, is_deal_of_day, deal_rank, subscribe_save_enabled, subscribe_save_discount_percent';
  final compatibleSelect =
      'id, name, description, price, unit, image_url, is_available, stock_quantity, created_at';

  Future<List<Product>> runQuery(String selectFields) async {
    final response = await supabase
        .from('products')
        .select(selectFields)
        .order('created_at', ascending: false)
        .limit(120);

    return (response as List)
        .map((item) => Product.fromSupabase(Map<String, dynamic>.from(item)))
        .where(isVisibleCustomerProduct)
        .toList();
  }

  try {
    final products = await runQuery(extendedSelect);
    return products;
  } catch (error) {
    farmDebugLog(
        'Extended product fetch unavailable, using compatible fetch: $error');
    try {
      final products = await runQuery(compatibleSelect);
      return products;
    } catch (compatibleError) {
      farmDebugLog('Failed to fetch products: $compatibleError');
      return const <Product>[];
    }
  }
}

Future<List<Product>> fetchReadySoonProducts(
    {bool forceRefresh = false}) async {
  if (!forceRefresh) {
    final cached = FarmDataCache.readySoonProducts;
    if (cached != null) return cached;
  }
  final products = await _fetchReadySoonProductsUncached();
  FarmDataCache.readySoonProducts = products;
  return products;
}

Future<List<Product>> fetchReadySoonProductsForCustomerUi({
  bool forceRefresh = false,
  Duration timeout = const Duration(seconds: 7),
}) async {
  final cached = FarmDataCache.readySoonProducts;

  try {
    final products = await fetchReadySoonProducts(forceRefresh: forceRefresh)
        .timeout(timeout, onTimeout: () => cached ?? const <Product>[]);
    return products;
  } catch (error) {
    farmDebugLog('Ready soon load fallback used: $error');
    return cached ?? const <Product>[];
  }
}

Future<List<Product>> _fetchReadySoonProductsUncached() async {
  const selectFields =
      'id, name, description, price, unit, image_url, is_available, stock_quantity, created_at, category, is_organic, is_local, harvest_date, farmer_id, farmer_name, farm_name, parish, approval_status, platform_commission_percent, original_price, discount_price, discount_percent, discount_label, discount_starts_at, discount_ends_at, is_discount_active, product_status, ready_soon, estimated_ready_date, expected_stock_quantity, is_deal_of_day, deal_rank, subscribe_save_enabled, subscribe_save_discount_percent';

  try {
    // Customer-facing Ready Soon list. Only products explicitly marked
    // ready-soon should appear here. Out-of-stock or unavailable products stay
    // out of this rail unless the admin also marks them as Ready Soon.
    final response = await supabase
        .from('products')
        .select(selectFields)
        .or('ready_soon.eq.true,product_status.eq.ready_soon')
        .order('estimated_ready_date', ascending: true);

    return (response as List)
        .map((item) => Product.fromSupabase(Map<String, dynamic>.from(item)))
        .where((product) =>
            product.approvalStatus == 'approved' &&
            !product.isHidden &&
            product.isReadySoon)
        .toList();
  } catch (error) {
    farmDebugLog(
        'Ready soon product lookup unavailable, retrying without local origin: $error');
    try {
      final response = await supabase
          .from('products')
          .select(selectFields.replaceAll(', is_local', ''))
          .or('ready_soon.eq.true,product_status.eq.ready_soon')
          .order('estimated_ready_date', ascending: true);

      return (response as List)
          .map((item) => Product.fromSupabase(Map<String, dynamic>.from(item)))
          .where((product) =>
              product.approvalStatus == 'approved' &&
              !product.isHidden &&
              product.isReadySoon)
          .toList();
    } catch (fallbackError) {
      farmDebugLog('Ready soon fallback lookup failed: $fallbackError');
      return [];
    }
  }
}

Future<Product?> fetchProductById(String productId) async {
  if (productId.trim().isEmpty) return null;
  const selectFields =
      'id, name, description, price, unit, image_url, is_available, stock_quantity, created_at, category, is_organic, is_local, harvest_date, farmer_id, farmer_name, farm_name, parish, approval_status, platform_commission_percent, original_price, discount_price, discount_percent, discount_label, discount_starts_at, discount_ends_at, is_discount_active, product_status, ready_soon, estimated_ready_date, expected_stock_quantity, is_deal_of_day, deal_rank, subscribe_save_enabled, subscribe_save_discount_percent';

  try {
    final response = await supabase
        .from('products')
        .select(selectFields)
        .eq('id', productId)
        .maybeSingle();
    if (response == null) return null;
    return Product.fromSupabase(Map<String, dynamic>.from(response));
  } catch (error) {
    farmDebugLog(
        'Product lookup by id unavailable, retrying without local origin: $error');
    try {
      final response = await supabase
          .from('products')
          .select(selectFields.replaceAll(', is_local', ''))
          .eq('id', productId)
          .maybeSingle();
      if (response == null) return null;
      return Product.fromSupabase(Map<String, dynamic>.from(response));
    } catch (fallbackError) {
      farmDebugLog('Product lookup by id fallback failed: $fallbackError');
      return null;
    }
  }
}

Future<List<Product>> fetchDealOfTheDayProducts(
    {bool forceRefresh = false}) async {
  if (!forceRefresh) {
    final cached = FarmDataCache.deals;
    if (cached != null) return cached;
  }
  final products = await _fetchDealOfTheDayProductsUncached();
  FarmDataCache.deals = products;
  return products;
}

Future<List<Product>> _fetchDealOfTheDayProductsUncached() async {
  const selectFields =
      'id, name, description, price, unit, image_url, is_available, stock_quantity, created_at, category, is_organic, is_local, harvest_date, farmer_id, farmer_name, farm_name, parish, approval_status, platform_commission_percent, original_price, discount_price, discount_percent, discount_label, discount_starts_at, discount_ends_at, is_discount_active, product_status, ready_soon, estimated_ready_date, expected_stock_quantity, is_deal_of_day, deal_rank, subscribe_save_enabled, subscribe_save_discount_percent';

  try {
    final response = await supabase
        .from('products')
        .select(selectFields)
        .or('is_deal_of_day.eq.true,is_discount_active.eq.true')
        .order('deal_rank', ascending: true)
        .limit(12);

    final products = (response as List)
        .map((item) => Product.fromSupabase(Map<String, dynamic>.from(item)))
        .where((product) =>
            isVisibleCustomerProduct(product) &&
            (product.showAsDealOfDay || product.hasActiveDiscount))
        .toList();

    products.sort((a, b) {
      if (a.canAddToCart != b.canAddToCart) return a.canAddToCart ? -1 : 1;
      final rank = a.dealRank.compareTo(b.dealRank);
      if (rank != 0) return rank;
      return b.discountPercentDisplay.compareTo(a.discountPercentDisplay);
    });
    return products;
  } catch (error) {
    farmDebugLog('Deal of the day lookup unavailable: $error');
    try {
      final products = await fetchProducts();
      final deals = products
          .where(
              (product) => product.hasActiveDiscount || product.showAsDealOfDay)
          .toList();
      deals.sort((a, b) {
        if (a.canAddToCart != b.canAddToCart) return a.canAddToCart ? -1 : 1;
        return b.discountPercentDisplay.compareTo(a.discountPercentDisplay);
      });
      return deals.take(8).toList();
    } catch (_) {
      return [];
    }
  }
}

Future<List<Product>> fetchFrequentlyBoughtTogetherProducts(
    Product product) async {
  final products = await fetchProducts();
  return buildFrequentlyBoughtTogetherProducts(
      product: product, products: products);
}

List<Product> buildFrequentlyBoughtTogetherProducts({
  required Product product,
  required List<Product> products,
}) {
  final targetCategory = product.category.trim().toLowerCase();
  final targetName = product.name.trim().toLowerCase();
  final seen = <String>{product.id};
  final output = <Product>[];

  void add(Product item) {
    if (item.id.trim().isEmpty || seen.contains(item.id)) return;
    if (!item.canAddToCart) return;
    seen.add(item.id);
    output.add(item);
  }

  final companionKeywords = <String, List<String>>{
    'vegetables': ['herb', 'pepper', 'tomato', 'onion', 'okra'],
    'fruits': ['honey', 'juice', 'drink'],
    'eggs': ['honey', 'bread', 'dairy'],
    'honey': ['fruit', 'tea', 'egg'],
    'herbs': ['vegetable', 'pepper', 'tomato'],
    'ground provisions': ['vegetable', 'herb', 'pepper'],
  };

  final keywords = companionKeywords.entries
      .where((entry) =>
          targetCategory.contains(entry.key) || targetName.contains(entry.key))
      .expand((entry) => entry.value)
      .toList();

  for (final item in products) {
    final text = '${item.name} ${item.category}'.toLowerCase();
    if (keywords.any(text.contains)) add(item);
    if (output.length >= 3) return output;
  }

  for (final item in products) {
    if (item.category.trim().toLowerCase() == targetCategory) add(item);
    if (output.length >= 3) return output;
  }

  for (final item in products) {
    add(item);
    if (output.length >= 3) return output;
  }

  return output;
}

Future<List<FarmOrder>> fetchOrders({bool forceRefresh = false}) async {
  if (!forceRefresh) {
    final cached = FarmDataCache.orders;
    if (cached != null) return cached;
  }
  final orders = await _fetchOrdersUncached();
  FarmDataCache.orders = orders;
  return orders;
}

Future<List<Product>> fetchBuyAgainProducts({bool forceRefresh = false}) async {
  if (!forceRefresh) {
    final cached = FarmDataCache.buyAgain;
    if (cached != null) return cached;
  }
  final products = await _fetchBuyAgainProductsUncached();
  FarmDataCache.buyAgain = products;
  return products;
}

Future<List<Product>> fetchBuyAgainProductsForCustomerUi({
  bool forceRefresh = false,
  Duration timeout = const Duration(seconds: 7),
}) async {
  final cached = FarmDataCache.buyAgain;

  try {
    final products = await fetchBuyAgainProducts(forceRefresh: forceRefresh)
        .timeout(timeout, onTimeout: () => cached ?? const <Product>[]);
    return products;
  } catch (error) {
    farmDebugLog('Buy again load fallback used: $error');
    return cached ?? const <Product>[];
  }
}

Future<List<Product>> _fetchBuyAgainProductsUncached() async {
  final user = supabase.auth.currentUser;
  if (user == null) return const [];

  final orders = await fetchOrders();
  final orderIds = orders
      .map((order) => order.id.trim())
      .where((id) => id.isNotEmpty)
      .toList();

  if (orderIds.isEmpty) return const [];

  List<Map<String, dynamic>> itemRows = [];

  try {
    final response = await supabase
        .from('order_items')
        .select('order_id, product_id, product_name, created_at')
        .inFilter('order_id', orderIds);

    itemRows = (response as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  } catch (error) {
    farmDebugLog('Buy Again product_id lookup unavailable: $error');
    try {
      final response = await supabase
          .from('order_items')
          .select('order_id, product_name, created_at')
          .inFilter('order_id', orderIds);

      itemRows = (response as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } catch (fallbackError) {
      farmDebugLog('Buy Again order item lookup failed: $fallbackError');
      return const [];
    }
  }

  if (itemRows.isEmpty) return const [];

  final orderRank = <String, int>{};
  for (var i = 0; i < orderIds.length; i++) {
    orderRank[orderIds[i]] = i;
  }

  itemRows.sort((a, b) {
    final aOrder = (a['order_id'] ?? '').toString();
    final bOrder = (b['order_id'] ?? '').toString();
    final byOrder =
        (orderRank[aOrder] ?? 999999).compareTo(orderRank[bOrder] ?? 999999);
    if (byOrder != 0) return byOrder;
    return (b['created_at'] ?? '').toString().compareTo(
          (a['created_at'] ?? '').toString(),
        );
  });

  final orderedProductIds = <String>[];
  final orderedNames = <String>[];

  for (final row in itemRows) {
    final productId = (row['product_id'] ?? '').toString().trim();
    final productName = (row['product_name'] ?? '').toString().trim();

    if (productId.isNotEmpty && !orderedProductIds.contains(productId)) {
      orderedProductIds.add(productId);
    }

    if (productName.isNotEmpty &&
        !orderedNames.any(
            (name) => name.trim().toLowerCase() == productName.toLowerCase())) {
      orderedNames.add(productName);
    }
  }

  const selectFields =
      'id, name, description, price, unit, image_url, is_available, stock_quantity, created_at, category, is_organic, is_local, harvest_date, farmer_id, farmer_name, farm_name, parish, approval_status, platform_commission_percent, original_price, discount_price, discount_percent, discount_label, discount_starts_at, discount_ends_at, is_discount_active, product_status, ready_soon, estimated_ready_date, expected_stock_quantity, is_deal_of_day, deal_rank, subscribe_save_enabled, subscribe_save_discount_percent';

  final productsById = <String, Product>{};

  if (orderedProductIds.isNotEmpty) {
    try {
      final response = await supabase
          .from('products')
          .select(selectFields)
          .inFilter('id', orderedProductIds);

      for (final item in response as List) {
        final product = Product.fromSupabase(Map<String, dynamic>.from(item));
        if (isVisibleCustomerProduct(product)) {
          productsById[product.id] = product;
        }
      }
    } catch (error) {
      farmDebugLog('Buy Again product lookup by id failed: $error');
    }
  }

  final productsByName = <String, Product>{};

  if (orderedNames.isNotEmpty) {
    try {
      final response =
          await supabase.from('products').select(selectFields).limit(250);

      for (final item in response as List) {
        final product = Product.fromSupabase(Map<String, dynamic>.from(item));
        if (isVisibleCustomerProduct(product)) {
          productsByName[product.name.trim().toLowerCase()] = product;
        }
      }
    } catch (error) {
      farmDebugLog('Buy Again product lookup by name failed: $error');
    }
  }

  final result = <Product>[];
  final seen = <String>{};

  for (final row in itemRows) {
    final productId = (row['product_id'] ?? '').toString().trim();
    final productName = (row['product_name'] ?? '').toString().trim();
    final product =
        productsById[productId] ?? productsByName[productName.toLowerCase()];

    if (product == null) continue;
    if (!isVisibleCustomerProduct(product)) continue;
    if (!seen.add(product.id)) continue;

    result.add(product);
    if (result.length >= 10) break;
  }

  return result;
}

String? notificationOrderShortId(FarmNotification notification) {
  final text = '${notification.title} ${notification.message}';
  final match = RegExp(r'#([A-Za-z0-9]+)').firstMatch(text);
  return match?.group(1)?.trim().toUpperCase();
}

Future<void> createFarmNotification({
  required String title,
  required String message,
  String type = 'order',
  String? userEmail,
  String? userId,
  String? orderId,
}) async {
  final explicitUserEmail = userEmail != null && userEmail.trim().isNotEmpty;
  final targetUserId =
      (userId ?? (explicitUserEmail ? null : supabase.auth.currentUser?.id))
          ?.trim();
  final targetEmail =
      (userEmail ?? supabase.auth.currentUser?.email)?.trim().toLowerCase();
  final cleanOrderId = orderId?.trim();

  // Never create anonymous/global private notifications from the client.
  // Use an admin Edge Function for broadcast notifications.
  if ((targetUserId == null || targetUserId.isEmpty) &&
      (targetEmail == null || targetEmail.isEmpty)) {
    debugPrintOnce(
      'notification_missing_target',
      'Notification skipped because no target user was supplied.',
    );
    return;
  }

  final notificationPayload = <String, dynamic>{
    'user_id': targetUserId,
    'user_email': targetEmail,
    'title': title,
    'message': message,
    'type': type,
    'is_read': false,
    if (cleanOrderId != null && cleanOrderId.isNotEmpty)
      'order_id': cleanOrderId,
  };

  if (await farmNotificationAlreadyExists(
    title: title,
    type: type,
    userId: targetUserId,
    userEmail: targetEmail,
    orderId: cleanOrderId,
  )) {
    showBrowserNotificationForTarget(
      title: title,
      message: message,
      type: type,
      userId: targetUserId,
      userEmail: targetEmail,
      orderId: cleanOrderId,
    );
    return;
  }

  try {
    await supabase.from('notifications').insert(notificationPayload);
    showBrowserNotificationForTarget(
      title: title,
      message: message,
      type: type,
      userId: targetUserId,
      userEmail: targetEmail,
      orderId: cleanOrderId,
    );
  } catch (error) {
    if (isNotificationsPermissionError(error)) {
      debugPrintOnce(
        'notification_insert_permission_denied',
        'Notification save skipped: notifications permissions/RLS need to be enabled in Supabase.',
      );
      return;
    }

    // Compatibility fallback for older notifications tables that do not yet
    // have user_id or order_id columns. Do not retry if this is a permissions
    // error, because that would only repeat the same console message.
    try {
      if (targetEmail == null || targetEmail.isEmpty) return;
      final legacyPayload = Map<String, dynamic>.from(notificationPayload)
        ..remove('user_id')
        ..remove('order_id');
      await supabase.from('notifications').insert(legacyPayload);
      showBrowserNotificationForTarget(
        title: title,
        message: message,
        type: type,
        userId: null,
        userEmail: targetEmail,
        orderId: cleanOrderId,
      );
    } catch (legacyError) {
      debugPrintOnce(
        "notification_insert_failed_${type}_${cleanOrderId ?? 'general'}",
        'Notification save skipped. The app will continue running.',
      );
    }
  }
}

String orderStatusCustomerTitle(String status) {
  switch (status.trim().toLowerCase()) {
    case 'preparing':
      return 'Order accepted';
    case 'ready':
      return 'Order ready';
    case 'out_for_delivery':
      return 'Order out for delivery';
    case 'delivered':
      return 'Order delivered';
    case 'on_hold':
    case 'hold':
      return 'Order on hold';
    case 'cancelled':
      return 'Order cancelled';
    case 'rejected':
      return 'Order could not be completed';
    default:
      return 'Order update';
  }
}

String orderStatusCustomerMessage({
  required String orderId,
  required String status,
}) {
  final shortId = shortIdLabel(orderId);
  switch (status.trim().toLowerCase()) {
    case 'preparing':
      return 'Order #$shortId has been accepted and is being prepared.';
    case 'ready':
      return 'Order #$shortId is ready. Please check your pickup or delivery details.';
    case 'out_for_delivery':
      return 'Order #$shortId is out for delivery.';
    case 'delivered':
      return 'Order #$shortId has been delivered. Thank you for shopping with The Harvest Place Ja.';
    case 'on_hold':
    case 'hold':
      return 'Order #$shortId has been placed on hold. Please check your notifications or contact support.';
    case 'cancelled':
      return 'Order #$shortId was cancelled. Please contact support if you need help.';
    case 'rejected':
      return 'Order #$shortId could not be completed. Please contact support if you need help.';
    default:
      return 'Order #$shortId is now ${_friendlyStatus(status)}.';
  }
}

String paymentStatusCustomerTitle(String status) {
  switch (status.trim().toLowerCase()) {
    case 'paid':
      return 'Payment verified';
    case 'refunded':
      return 'Payment refunded';
    default:
      return 'Payment update';
  }
}

String paymentStatusCustomerMessage({
  required String orderId,
  required String status,
}) {
  final shortId = shortIdLabel(orderId);
  switch (status.trim().toLowerCase()) {
    case 'paid':
      return 'Payment for order #$shortId has been verified.';
    case 'refunded':
      return 'Payment for order #$shortId has been marked refunded.';
    case 'unpaid':
    case 'pending':
      return 'Payment for order #$shortId is awaiting bank transfer verification.';
    default:
      return 'Payment for order #$shortId is now ${formatPaymentStatus(status)}.';
  }
}

Future<NotificationTarget> fetchOrderNotificationTarget(String orderId) async {
  final cleanOrderId = orderId.trim();
  if (cleanOrderId.isEmpty) return const NotificationTarget();

  String? clean(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  NotificationTarget parseTarget(Map<String, dynamic> data) {
    final directUserId = clean(data['user_id']);
    final directEmail = clean(data['user_email']);
    final customerData = data['customers'];
    final customer = customerData is Map<String, dynamic>
        ? customerData
        : customerData is Map
            ? Map<String, dynamic>.from(customerData)
            : <String, dynamic>{};

    return NotificationTarget(
      userId: directUserId ?? clean(customer['user_id']),
      userEmail: directEmail ?? clean(customer['email']),
    );
  }

  try {
    final response = await supabase
        .from('orders')
        .select('user_id, customers(user_id, email)')
        .eq('id', cleanOrderId)
        .maybeSingle();

    if (response != null) {
      final target = parseTarget(Map<String, dynamic>.from(response));
      if (target.hasTarget) return target;
    }
  } catch (error) {
    debugPrintOnce(
      'order_notification_joined_lookup_unavailable',
      'Order notification target joined lookup unavailable. Using safe fallback lookup.',
    );
  }

  try {
    final order = await supabase
        .from('orders')
        .select('user_id, customer_id')
        .eq('id', cleanOrderId)
        .maybeSingle();

    if (order == null) return const NotificationTarget();
    final orderData = Map<String, dynamic>.from(order);
    final directUserId = clean(orderData['user_id']);
    final customerId = clean(orderData['customer_id']);

    if (customerId == null) {
      return NotificationTarget(userId: directUserId);
    }

    try {
      final customer = await supabase
          .from('customers')
          .select('user_id, email')
          .eq('id', customerId)
          .maybeSingle();

      if (customer != null) {
        final customerData = Map<String, dynamic>.from(customer);
        return NotificationTarget(
          userId: directUserId ?? clean(customerData['user_id']),
          userEmail: clean(customerData['email']),
        );
      }
    } catch (customerError) {
      debugPrintOnce(
        'customer_notification_target_lookup_unavailable',
        'Customer notification target lookup unavailable. Customer notification was skipped safely.',
      );
    }

    return NotificationTarget(userId: directUserId);
  } catch (error) {
    debugPrintOnce(
      'order_notification_target_lookup_unavailable',
      'Order notification target lookup unavailable. Customer notification was skipped safely.',
    );
    return const NotificationTarget();
  }
}

Future<void> createOrderCustomerNotification({
  required String orderId,
  required String title,
  required String message,
  String type = 'order',
}) async {
  try {
    final target = await fetchOrderNotificationTarget(orderId);
    if (!target.hasTarget) {
      debugPrintOnce(
        'order_customer_notification_no_target',
        'Order customer notification skipped because no customer target was found.',
      );
      return;
    }

    await createFarmNotification(
      title: title,
      message: message,
      type: type,
      userId: target.userId,
      userEmail: target.userEmail,
      orderId: orderId,
    );
  } catch (error) {
    debugPrintOnce(
      'order_customer_notification_failed',
      'Order customer notification skipped safely. The order workflow will continue.',
    );
  }
}

Future<void> createOrderConfirmationSupport({
  required String orderId,
  required String customerName,
  required String customerPhone,
  required String? customerEmail,
  required double total,
}) async {
  final payload = {
    'order_id': orderId,
    'customer_name': customerName,
    'customer_phone': customerPhone,
    'customer_email': customerEmail,
    'total': total,
    'email_status':
        customerEmail == null || customerEmail.isEmpty ? 'no_email' : 'pending',
    'sms_status': customerPhone.isEmpty ? 'no_phone' : 'pending',
    'message':
        'Thank you for your order from The Harvest Place Ja. Your order has been received.',
  };

  try {
    await supabase.from('order_confirmations').insert({
      ...payload,
      'user_id': supabase.auth.currentUser?.id,
    });
  } catch (userIdError) {
    try {
      await supabase.from('order_confirmations').insert(payload);
    } catch (legacyError) {
      farmDebugLog(
          'Order confirmation support skipped: $userIdError / $legacyError');
    }
  }
}

Future<List<FarmNotification>> fetchFarmNotifications(
    {bool forceRefresh = false}) async {
  if (!forceRefresh) {
    final cached = FarmDataCache.notifications;
    if (cached != null) return cached;
  }
  final notifications = await _fetchFarmNotificationsUncached();
  FarmDataCache.notifications = notifications;
  return notifications;
}

Future<int> fetchUnreadNotificationCount() async {
  final notifications = await fetchFarmNotifications();
  return notifications.where((notice) => !notice.isRead).length;
}

Future<void> markNotificationsRead() async {
  final user = supabase.auth.currentUser;
  if (user == null) return;

  try {
    await supabase
        .from('notifications')
        .update({'is_read': true}).eq('user_id', user.id);
  } catch (userIdError) {
    try {
      final userEmail = (user.email ?? '').trim().toLowerCase();
      if (userEmail.isEmpty) return;
      await supabase
          .from('notifications')
          .update({'is_read': true}).eq('user_email', userEmail);
    } catch (emailError) {
      debugPrintOnce(
        'mark_notifications_read_skipped',
        'Mark notifications read skipped safely.',
      );
    }
  }
}

Future<bool> subscribeToProductReadyAlert(Product product) async {
  final user = supabase.auth.currentUser;
  if (user == null) {
    throw Exception(
        'Please sign in so we can notify you when this item is ready.');
  }

  final email = (user.email ?? '').trim().toLowerCase();
  try {
    final existing = await supabase
        .from('product_ready_subscriptions')
        .select('id')
        .eq('product_id', product.id)
        .eq('user_id', user.id)
        .eq('is_notified', false)
        .maybeSingle();

    if (existing != null) return false;

    await supabase.from('product_ready_subscriptions').insert({
      'user_id': user.id,
      'user_email': email,
      'product_id': product.id,
      'product_name': product.name,
      'is_notified': false,
    });
    return true;
  } catch (error) {
    farmDebugLog('Product ready subscription skipped: $error');
    throw Exception(
        'Ready alerts are not set up yet. Please run the Supabase SQL migration first.');
  }
}

Future<void> notifySubscribedCustomersProductReady(Product product) async {
  if (product.id.trim().isEmpty || !product.canAddToCart) return;

  try {
    final response = await supabase
        .from('product_ready_subscriptions')
        .select('id, user_id, user_email')
        .eq('product_id', product.id)
        .eq('is_notified', false);

    final currentUser = supabase.auth.currentUser;
    final currentUserId = currentUser?.id.trim();
    final currentUserEmail = currentUser?.email?.trim().toLowerCase();
    var shouldShowLocalBrowserNotification = false;

    for (final item in response as List) {
      final row = Map<String, dynamic>.from(item as Map);
      final subId = (row['id'] ?? '').toString();
      final userId = row['user_id']?.toString();
      final email = row['user_email']?.toString();
      final hasSubscriptionTarget =
          (userId != null && userId.trim().isNotEmpty) ||
              (email != null && email.trim().isNotEmpty);

      if (!hasSubscriptionTarget) {
        farmDebugLog(
            'Skipped product-ready notification with no customer target for ${product.id}.');
        continue;
      }

      await createFarmNotification(
        title: '${product.name} is ready',
        message:
            'Good news! ${product.name} is now available at The Harvest Place Ja.',
        type: 'product_ready',
        userId: userId,
        userEmail: email,
      );

      final normalizedEmail = email?.trim().toLowerCase();
      if ((currentUserId != null &&
              currentUserId.isNotEmpty &&
              currentUserId == userId?.trim()) ||
          (currentUserEmail != null &&
              currentUserEmail.isNotEmpty &&
              currentUserEmail == normalizedEmail)) {
        shouldShowLocalBrowserNotification = true;
      }

      if (subId.isNotEmpty) {
        await supabase.from('product_ready_subscriptions').update({
          'is_notified': true,
          'notified_at': DateTime.now().toIso8601String(),
        }).eq('id', subId);
      }
    }

    if (shouldShowLocalBrowserNotification) {
      showBrowserNotification(
        title: '${product.name} is ready',
        body: 'Good news! ${product.name} is now available.',
        type: 'product_ready',
      );
    }
  } catch (error) {
    farmDebugLog('Product ready notifications skipped: $error');
  }
}

Future<void> maybeNotifyProductReady(String productId) async {
  final product = await fetchProductById(productId);
  if (product == null || !product.canAddToCart) return;
  await notifySubscribedCustomersProductReady(product);
}

Future<bool> subscribeToSaveProduct(
  Product product, {
  int intervalDays = 7,
}) async {
  final user = supabase.auth.currentUser;
  if (user == null) {
    throw Exception('Please sign in to start a Fresh Box Plan.');
  }

  if (!product.hasSubscribeSave) {
    throw Exception('Fresh Box Plan is not available for this item yet.');
  }

  final safeInterval = intervalDays <= 0 ? 7 : intervalDays;
  final nextOrderDate = DateTime.now().add(Duration(days: safeInterval));
  final email = (user.email ?? '').trim().toLowerCase();

  try {
    final existing = await supabase
        .from('customer_product_subscriptions')
        .select('id')
        .eq('product_id', product.id)
        .eq('user_id', user.id)
        .eq('status', 'active')
        .maybeSingle();

    if (existing != null) return false;

    await supabase.from('customer_product_subscriptions').insert({
      'user_id': user.id,
      'user_email': email,
      'product_id': product.id,
      'product_name': product.name,
      'interval_days': safeInterval,
      'discount_percent': product.subscribeSavePercentValue,
      'next_order_date': todayIsoDateFrom(nextOrderDate),
      'status': 'active',
    });
    return true;
  } catch (error) {
    farmDebugLog('Fresh Box Plan setup skipped: $error');
    throw Exception(
        'Fresh Box Plan is not set up yet. Please run the Supabase SQL migration first.');
  }
}

Future<CustomerProductSubscription?> fetchActiveSubscriptionForProduct(
  Product product,
) async {
  final user = supabase.auth.currentUser;
  if (user == null) return null;

  try {
    final response = await supabase
        .from('customer_product_subscriptions')
        .select(
            'id, user_id, user_email, product_id, product_name, interval_days, discount_percent, next_order_date, status, created_at')
        .eq('product_id', product.id)
        .eq('user_id', user.id)
        .inFilter('status', ['active', 'paused'])
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;
    return CustomerProductSubscription.fromSupabase(
      Map<String, dynamic>.from(response),
    );
  } catch (error) {
    debugPrintOnce(
      'customer-subscription-lookup-unavailable',
      'Fresh Box Plan lookup skipped: $error',
    );
    return null;
  }
}

Future<List<CustomerProductSubscription>> fetchCustomerProductSubscriptions({
  bool includeCancelled = false,
}) async {
  final user = supabase.auth.currentUser;
  if (user == null) return [];

  try {
    var query = supabase
        .from('customer_product_subscriptions')
        .select(
            'id, user_id, user_email, product_id, product_name, interval_days, discount_percent, next_order_date, status, created_at')
        .eq('user_id', user.id);

    if (!includeCancelled) {
      query = query.neq('status', 'cancelled');
    }

    final response = await query.order('next_order_date', ascending: true);

    return (response as List)
        .map((row) => CustomerProductSubscription.fromSupabase(
              Map<String, dynamic>.from(row),
            ))
        .toList();
  } catch (error) {
    debugPrintOnce(
      'customer-subscriptions-table-unavailable',
      'Weekly Box plans are unavailable: $error',
    );
    return [];
  }
}

Future<void> updateCustomerSubscriptionStatus({
  required CustomerProductSubscription subscription,
  required String status,
}) async {
  final user = supabase.auth.currentUser;
  if (user == null) throw Exception('Please sign in first.');

  await supabase
      .from('customer_product_subscriptions')
      .update({'status': status})
      .eq('id', subscription.id)
      .eq('user_id', user.id);
}

Future<void> updateCustomerSubscriptionSchedule({
  required CustomerProductSubscription subscription,
  required int intervalDays,
}) async {
  final user = supabase.auth.currentUser;
  if (user == null) throw Exception('Please sign in first.');

  final safeInterval = intervalDays <= 0 ? 7 : intervalDays;
  final nextOrderDate = DateTime.now().add(Duration(days: safeInterval));

  await supabase
      .from('customer_product_subscriptions')
      .update({
        'interval_days': safeInterval,
        'next_order_date': todayIsoDateFrom(nextOrderDate),
        'status': 'active',
      })
      .eq('id', subscription.id)
      .eq('user_id', user.id);
}

double weeklyBoxDiscountForProduct(Product product) {
  if (!product.subscribeSaveEnabled) return 0;
  return product.subscribeSavePercentValue;
}

Future<int> saveWeeklyBoxPlanProducts({
  required List<Product> products,
  int intervalDays = 7,
}) async {
  final user = supabase.auth.currentUser;
  if (user == null) {
    throw Exception('Please sign in to build your Weekly Box.');
  }

  final selectedProducts = products
      .where((product) => product.id.trim().isNotEmpty)
      .where(canAddToWeeklyBox)
      .toList();

  if (selectedProducts.isEmpty) {
    throw Exception('Choose at least one available item for your Weekly Box.');
  }

  final safeInterval = intervalDays <= 0 ? 7 : intervalDays;
  final nextOrderDate = DateTime.now().add(Duration(days: safeInterval));
  final email = (user.email ?? '').trim().toLowerCase();
  var savedCount = 0;

  try {
    for (final product in selectedProducts) {
      final discountPercent = weeklyBoxDiscountForProduct(product);
      final existing = await supabase
          .from('customer_product_subscriptions')
          .select('id')
          .eq('product_id', product.id)
          .eq('user_id', user.id)
          .neq('status', 'cancelled')
          .limit(1)
          .maybeSingle();

      final payload = {
        'user_id': user.id,
        'user_email': email,
        'product_id': product.id,
        'product_name': product.name,
        'interval_days': safeInterval,
        'discount_percent': discountPercent,
        'next_order_date': todayIsoDateFrom(nextOrderDate),
        'status': 'active',
      };

      if (existing != null) {
        await supabase
            .from('customer_product_subscriptions')
            .update(payload)
            .eq('id', (existing['id'] ?? '').toString())
            .eq('user_id', user.id);
      } else {
        await supabase.from('customer_product_subscriptions').insert(payload);
      }

      savedCount++;
    }
  } catch (error) {
    farmDebugLog('Weekly Box save skipped: $error');
    throw Exception(
      'Weekly Box is not set up yet. Please check the Fresh Box Plan table and policies.',
    );
  }

  return savedCount;
}

Future<OrderDetails?> fetchOrderDetails(String orderId) async {
  final user = supabase.auth.currentUser;
  if (user == null) return null;

  const fields =
      'id, order_status, fulfillment_type, subtotal, delivery_fee, discount_amount, total, payment_status, payment_method, delivery_address, delivery_zone, scheduled_date, scheduled_time, notes, created_at, order_items(product_name, quantity, unit_price, line_total)';

  try {
    final isAdmin = await isCurrentUserAdminFromDatabase();
    if (isAdmin) {
      final response = await supabase
          .from('orders')
          .select(fields)
          .eq('id', orderId)
          .maybeSingle();
      return response == null
          ? null
          : OrderDetails.fromSupabase(Map<String, dynamic>.from(response));
    }

    try {
      final response = await supabase
          .from('orders')
          .select(fields)
          .eq('id', orderId)
          .eq('user_id', user.id)
          .maybeSingle();
      if (response != null) {
        return OrderDetails.fromSupabase(Map<String, dynamic>.from(response));
      }
    } catch (userIdError) {
      farmDebugLog('Order detail lookup by user_id unavailable: $userIdError');
    }

    final profile = await fetchCurrentCustomerProfile();
    if (profile?.id == null || profile!.id!.isEmpty) return null;

    final response = await supabase
        .from('orders')
        .select(fields)
        .eq('id', orderId)
        .eq('customer_id', profile.id!)
        .maybeSingle();

    return response == null
        ? null
        : OrderDetails.fromSupabase(Map<String, dynamic>.from(response));
  } catch (error) {
    farmDebugLog('Failed to fetch private order details: $error');
    return null;
  }
}

Future<void> updateOrderStatus(String orderId, String status) async {
  await requireAdminAccess();
  await supabase
      .from('orders')
      .update({'order_status': status}).eq('id', orderId);

  await createOrderCustomerNotification(
    orderId: orderId,
    title: orderStatusCustomerTitle(status),
    message: orderStatusCustomerMessage(orderId: orderId, status: status),
    type: status == 'out_for_delivery' ? 'delivery' : 'order',
  );

  if (status == 'cancelled' || status == 'rejected') {
    await createAdminNotification(
      title: 'Order ${_friendlyStatus(status)}',
      message:
          'Order #${shortIdLabel(orderId)} was marked ${_friendlyStatus(status)}.',
      type: 'admin',
      orderId: orderId,
    );
  }
}

Future<void> updatePaymentStatus(String orderId, String status) async {
  await requireAdminAccess();
  await supabase
      .from('orders')
      .update({'payment_status': status}).eq('id', orderId);

  await createOrderCustomerNotification(
    orderId: orderId,
    title: paymentStatusCustomerTitle(status),
    message: paymentStatusCustomerMessage(orderId: orderId, status: status),
    type: 'payment',
  );
}

Future<void> quickUpdateOrderStatus(String orderId, String status) async {
  await updateOrderStatus(orderId, status);
}

Future<void> markOrderPaid(String orderId) async {
  await requireAdminAccess();
  final adminEmail = supabase.auth.currentUser?.email ?? 'admin';

  await supabase.from('orders').update({
    'payment_status': 'paid',
    'payment_verified_at': DateTime.now().toIso8601String(),
    'payment_verified_by': adminEmail,
  }).eq('id', orderId);

  await createOrderCustomerNotification(
    orderId: orderId,
    title: 'Payment verified',
    message: paymentStatusCustomerMessage(orderId: orderId, status: 'paid'),
    type: 'payment',
  );
}

Future<void> updateDeliveryStatus(String orderId, String deliveryStatus) async {
  await requireAdminAccess();
  final orderStatus = deliveryStatus == 'delivered'
      ? 'delivered'
      : deliveryStatus == 'out_for_delivery'
          ? 'out_for_delivery'
          : deliveryStatus == 'ready_for_pickup'
              ? 'ready'
              : 'preparing';

  await supabase.from('orders').update({
    'delivery_status': deliveryStatus,
    'order_status': orderStatus,
  }).eq('id', orderId);

  await createOrderCustomerNotification(
    orderId: orderId,
    title: 'Delivery update',
    message:
        'Order #${orderId.length <= 6 ? orderId : orderId.substring(0, 6).toUpperCase()} is ${_friendlyStatus(deliveryStatus)}.',
    type: 'delivery',
  );
}

Future<List<Product>> fetchAllProducts() async {
  final extendedSelect =
      'id, name, description, price, unit, image_url, is_available, stock_quantity, created_at, category, is_organic, is_local, harvest_date, farmer_id, farmer_name, farm_name, parish, approval_status, platform_commission_percent, original_price, discount_price, discount_percent, discount_label, discount_starts_at, discount_ends_at, is_discount_active, product_status, ready_soon, estimated_ready_date, expected_stock_quantity, is_deal_of_day, deal_rank, subscribe_save_enabled, subscribe_save_discount_percent';
  final compatibleSelect =
      'id, name, description, price, unit, image_url, is_available, stock_quantity, created_at';
  Future<List<Product>> runQuery(String selectFields) async {
    final response = await supabase
        .from('products')
        .select(selectFields)
        .order('created_at', ascending: false);
    return (response as List)
        .map((item) => Product.fromSupabase(Map<String, dynamic>.from(item)))
        .toList();
  }

  try {
    return await runQuery(extendedSelect);
  } catch (error) {
    farmDebugLog(
        'Extended all-products fetch unavailable, using compatible fetch: $error');
    try {
      return await runQuery(compatibleSelect);
    } catch (compatibleError) {
      farmDebugLog('Failed to fetch all products: $compatibleError');
      return const <Product>[];
    }
  }
}

Future<Map<String, dynamic>?> adminUpdateProduct({
  required String productId,
  String? name,
  String? description,
  double? price,
  String? unit,
  String? imageUrl,
  bool? isAvailable,
  int? stockQuantity,
  String? approvalStatus,
  String? adminNote,
  String? category,
  bool? isOrganic,
  bool? isLocal,
  DateTime? harvestDate,
  double? originalPrice,
  double? discountPrice,
  double? discountPercent,
  String? discountLabel,
  DateTime? discountStartsAt,
  DateTime? discountEndsAt,
  bool? isDiscountActive,
  String? productStatus,
  bool? readySoon,
  DateTime? estimatedReadyDate,
  int? expectedStockQuantity,
  bool? isDealOfDay,
  int? dealRank,
  bool? subscribeSaveEnabled,
  double? subscribeSaveDiscountPercent,
}) async {
  await requireAdminAccess();
  if (productId.trim().isEmpty) {
    throw Exception('Missing product ID.');
  }

  try {
    final response = await supabase.rpc(
      'admin_update_product',
      params: {
        'p_product_id': productId,
        'p_name': name,
        'p_description': description,
        'p_price': price,
        'p_unit': unit,
        'p_image_url': imageUrl,
        'p_is_available': isAvailable,
        'p_stock_quantity': stockQuantity,
        'p_approval_status': approvalStatus,
        'p_admin_note': adminNote,
        'p_category': category,
        'p_is_organic': isOrganic,
        'p_harvest_date': harvestDate?.toIso8601String().split('T').first,
        'p_original_price': originalPrice,
        'p_discount_price': discountPrice,
        'p_discount_percent': discountPercent,
        'p_discount_label': discountLabel,
        'p_discount_starts_at': discountStartsAt?.toIso8601String(),
        'p_discount_ends_at': discountEndsAt?.toIso8601String(),
        'p_is_discount_active': isDiscountActive,
        'p_product_status': productStatus,
        'p_ready_soon': readySoon,
        'p_estimated_ready_date':
            estimatedReadyDate?.toIso8601String().split('T').first,
        'p_expected_stock_quantity': expectedStockQuantity,
        'p_is_deal_of_day': isDealOfDay,
        'p_deal_rank': dealRank,
        'p_subscribe_save_enabled': subscribeSaveEnabled,
        'p_subscribe_save_discount_percent': subscribeSaveDiscountPercent,
      },
    );

    if (isLocal != null) {
      try {
        await supabase
            .from('products')
            .update({'is_local': isLocal}).eq('id', productId);
      } catch (localUpdateError) {
        farmDebugLog('Local origin update skipped: $localUpdateError');
      }
    }

    FarmDataCache.clearProducts();

    if (response is Map<String, dynamic>) return response;
    if (response is Map) return Map<String, dynamic>.from(response);
    return null;
  } catch (error) {
    final cleanMessage = friendlyAppError(error);
    farmDebugLog('Admin product RPC failed: $cleanMessage');
    throw Exception(cleanMessage);
  }
}

Future<void> updateProductAvailability(
    String productId, bool isAvailable) async {
  await adminUpdateProduct(
    productId: productId,
    isAvailable: isAvailable,
    adminNote: isAvailable
        ? 'Admin made product visible from app'
        : 'Admin hid product from app',
  );
  await maybeNotifyProductReady(productId);
}

Future<void> createProduct({
  required String name,
  required double price,
  required int stockQuantity,
  required bool isAvailable,
  required String category,
  required bool isOrganic,
  bool isLocal = true,
  String? description,
  String? unit,
  String? imageUrl,
  bool isDiscountActive = false,
  double? originalPrice,
  double? discountPrice,
  double? discountPercent,
  String? discountLabel,
  String? discountStartsAt,
  String? discountEndsAt,
  String productStatus = 'available',
  bool readySoon = false,
  String? estimatedReadyDate,
  int? expectedStockQuantity,
  bool isDealOfDay = false,
  int? dealRank,
  bool subscribeSaveEnabled = false,
  double? subscribeSaveDiscountPercent,
}) async {
  await requireAdminAccess();
  final payload = {
    'name': name,
    'price': price,
    'stock_quantity': stockQuantity,
    'is_available': isAvailable,
    'category': normalizeProductCategory(category),
    'is_organic': isOrganic,
    'is_local': isLocal,
    'harvest_date': todayIsoDate(),
    'description': description,
    'unit': unit,
    'image_url': imageUrl,
    'original_price': originalPrice,
    'discount_price': discountPrice,
    'discount_percent': discountPercent,
    'discount_label': discountLabel,
    'discount_starts_at': discountStartsAt,
    'discount_ends_at': discountEndsAt,
    'is_discount_active': isDiscountActive,
    'product_status': readySoon ? 'ready_soon' : productStatus,
    'ready_soon': readySoon,
    'estimated_ready_date': estimatedReadyDate,
    'expected_stock_quantity': expectedStockQuantity,
    'is_deal_of_day': isDealOfDay,
    'deal_rank': dealRank,
    'subscribe_save_enabled': subscribeSaveEnabled,
    'subscribe_save_discount_percent': subscribeSaveDiscountPercent,
  };

  try {
    final inserted = await supabase
        .from('products')
        .insert(payload)
        .select('id')
        .maybeSingle();
    final productId = inserted == null ? '' : (inserted['id'] ?? '').toString();
    if (productId.isNotEmpty) await maybeNotifyProductReady(productId);
  } catch (error) {
    final errorText = error.toString().toLowerCase();
    final missingNewColumns = errorText.contains('schema cache') ||
        errorText.contains('pgrst204') ||
        errorText.contains('column');
    if (!missingNewColumns) rethrow;
    farmDebugLog(
        'Discount/ready-soon columns unavailable, using compatible insert: $error');
    await supabase.from('products').insert({
      'name': name,
      'price': price,
      'stock_quantity': stockQuantity,
      'is_available': isAvailable,
      'category': normalizeProductCategory(category),
      'is_organic': isOrganic,
      'harvest_date': todayIsoDate(),
      'description': description,
      'unit': unit,
      'image_url': imageUrl,
    });
  }
}

Future<void> updateProductDetails({
  required String productId,
  required String name,
  required double price,
  required int stockQuantity,
  required bool isAvailable,
  required String category,
  required bool isOrganic,
  bool isLocal = true,
  String? description,
  String? unit,
  String? imageUrl,
  bool isDiscountActive = false,
  double? originalPrice,
  double? discountPrice,
  double? discountPercent,
  String? discountLabel,
  String? discountStartsAt,
  String? discountEndsAt,
  String productStatus = 'available',
  bool readySoon = false,
  String? estimatedReadyDate,
  int? expectedStockQuantity,
  bool isDealOfDay = false,
  int? dealRank,
  bool subscribeSaveEnabled = false,
  double? subscribeSaveDiscountPercent,
}) async {
  await adminUpdateProduct(
    productId: productId,
    name: name,
    description: description,
    price: price,
    unit: unit,
    imageUrl: imageUrl,
    isAvailable: isAvailable,
    stockQuantity: stockQuantity,
    approvalStatus: 'approved',
    adminNote: 'Admin edited product details from app',
    category: normalizeProductCategory(category),
    isOrganic: isOrganic,
    isLocal: isLocal,
    harvestDate: DateTime.now(),
    originalPrice: originalPrice,
    discountPrice: discountPrice,
    discountPercent: discountPercent,
    discountLabel: discountLabel,
    discountStartsAt: parseProductDate(discountStartsAt),
    discountEndsAt: parseProductDate(discountEndsAt),
    isDiscountActive: isDiscountActive,
    productStatus: readySoon ? 'ready_soon' : productStatus,
    readySoon: readySoon,
    estimatedReadyDate: parseProductDate(estimatedReadyDate),
    expectedStockQuantity: expectedStockQuantity,
    isDealOfDay: isDealOfDay,
    dealRank: dealRank,
    subscribeSaveEnabled: subscribeSaveEnabled,
    subscribeSaveDiscountPercent: subscribeSaveDiscountPercent,
  );

  await maybeNotifyProductReady(productId);
}

Future<Map<String, int>> fetchProductStockByIds(List<String> productIds) async {
  final ids = productIds.where((id) => id.isNotEmpty).toSet().toList();
  if (ids.isEmpty) return {};

  final response = await supabase
      .from('products')
      .select(
          'id, stock_quantity, is_available, approval_status, product_status, ready_soon')
      .inFilter('id', ids);

  final stock = <String, int>{};
  for (final item in response as List) {
    final data = Map<String, dynamic>.from(item as Map);
    final status =
        (data['product_status'] ?? 'available').toString().trim().toLowerCase();
    final approvalStatus =
        (data['approval_status'] ?? 'approved').toString().trim().toLowerCase();
    final isAvailable =
        data['is_available'] == null ? true : data['is_available'] == true;
    final isReadySoon = data['ready_soon'] == true || status == 'ready_soon';
    final isHidden = status == 'hidden';
    final isApproved = approvalStatus == 'approved';
    final canCustomerBuy =
        isApproved && isAvailable && !isHidden && !isReadySoon;

    stock[(data['id'] ?? '').toString()] =
        canCustomerBuy ? Product._toInt(data['stock_quantity']) : 0;
  }
  return stock;
}

Future<String?> validateStockBeforeCheckout(List<CartLine> lines) async {
  final stockById = await fetchProductStockByIds(
    lines.map((line) => line.product.id).toList(),
  );

  for (final line in lines) {
    final productId = line.product.id;
    if (productId.isEmpty) continue;
    final availableStock = stockById[productId] ?? 0;
    if (availableStock <= 0) {
      return '${line.product.name} is out of stock.';
    }
    if (line.quantity > availableStock) {
      return 'Only $availableStock ${line.product.name} available. Please reduce quantity.';
    }
  }
  return null;
}

Future<void> reduceStockForOrder(String orderId) async {
  final cleanOrderId = orderId.trim();
  if (cleanOrderId.isEmpty) {
    throw Exception('Missing order ID for stock confirmation.');
  }

  try {
    await supabase.rpc(
      'reduce_stock_for_order',
      params: {'p_order_id': cleanOrderId},
    );
  } catch (error) {
    final cleanMessage = error.toString().replaceFirst('Exception: ', '');
    farmDebugLog('Server-side stock reduction failed: $cleanMessage');
    throw Exception(cleanMessage);
  }
}

Future<void> ensureStockReducedAfterCheckout({
  required String orderId,
  required List<SecureCartLineQuote> checkoutLines,
}) async {
  final cleanLines = checkoutLines
      .where((line) => line.product.id.trim().isNotEmpty && line.quantity > 0)
      .toList();
  if (cleanLines.isEmpty) return;

  final productIds = cleanLines.map((line) => line.product.id).toList();

  try {
    final currentStockById = await fetchProductStockByIds(productIds);
    var looksAlreadyReduced = false;
    var looksUnchanged = false;

    for (final line in cleanLines) {
      final currentStock = currentStockById[line.product.id];
      if (currentStock == null) continue;

      final expectedAfterCheckout = line.availableStock - line.quantity;
      if (currentStock <= expectedAfterCheckout) {
        looksAlreadyReduced = true;
      } else if (currentStock >= line.availableStock) {
        looksUnchanged = true;
      }
    }

    // secure_checkout / secure_checkout_with_coupon should reduce stock inside
    // the database transaction. If stock is already lower, do not call the
    // legacy reducer because that could double-reduce inventory.
    if (!looksUnchanged || looksAlreadyReduced) {
      FarmDataCache.clearProducts();
      return;
    }

    // Fallback for older database setups where checkout creates the order but
    // does not reduce product stock. The RPC should be server-side and
    // idempotent because stock changes must stay protected from race conditions.
    await reduceStockForOrder(orderId);
    FarmDataCache.clearProducts();
  } catch (error) {
    farmDebugLog('Post-checkout stock sync failed: $error');
    throw Exception(
      'Your order was created, but stock could not be updated. Please contact support before placing this order again.',
    );
  }
}

Future<void> restockProduct(String productId, int amount) async {
  await requireAdminAccess();
  if (productId.isEmpty || amount <= 0) return;

  final current = await supabase
      .from('products')
      .select('stock_quantity')
      .eq('id', productId)
      .maybeSingle();

  final currentStock =
      current == null ? 0 : Product._toInt(current['stock_quantity']);

  await adminUpdateProduct(
    productId: productId,
    stockQuantity: currentStock + amount,
    isAvailable: true,
    approvalStatus: 'approved',
    adminNote: 'Admin restocked product from app by $amount',
  );
  await maybeNotifyProductReady(productId);
}

Future<void> reuseProductThisWeek({
  required String productId,
  required int stockQuantity,
}) async {
  await requireAdminAccess();
  if (productId.isEmpty) return;

  final safeStock = stockQuantity < 0 ? 0 : stockQuantity;

  await adminUpdateProduct(
    productId: productId,
    stockQuantity: safeStock,
    isAvailable: safeStock > 0,
    approvalStatus: 'approved',
    harvestDate: DateTime.now(),
    adminNote: 'Admin marked product recently harvested from app',
  );

  await maybeNotifyProductReady(productId);
}

Future<String?> currentCustomerIdForSignedInUser() async {
  final user = supabase.auth.currentUser;
  if (user == null) return null;

  try {
    final response = await supabase
        .from('customers')
        .select('id')
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    return response == null ? null : (response['id'] ?? '').toString();
  } catch (error) {
    farmDebugLog('Secure customer id lookup failed: $error');
    return null;
  }
}

Future<String?> secureSaveCurrentCustomerAndGetId({
  required String fullName,
  required String phone,
  required String address,
}) async {
  final user = supabase.auth.currentUser;
  if (user == null) return null;

  final payload = {
    'full_name': fullName,
    'phone': phone,
    'address': address.isEmpty ? null : address,
    'email': user.email,
    'user_id': user.id,
  };

  try {
    final response = await supabase
        .from('customers')
        .upsert(payload, onConflict: 'user_id')
        .select('id')
        .single();
    return (response['id'] ?? '').toString();
  } catch (upsertError) {
    farmDebugLog(
        'Customer upsert by user_id failed, using safe fallback: $upsertError');
    final existingId = await currentCustomerIdForSignedInUser();
    if (existingId != null && existingId.isNotEmpty) {
      await supabase.from('customers').update(payload).eq('id', existingId);
      return existingId;
    }

    final response =
        await supabase.from('customers').insert(payload).select('id').single();
    return (response['id'] ?? '').toString();
  }
}

Future<CustomerProfile?> fetchCurrentCustomerProfile() async {
  if (!isLoggedIn) return null;

  final user = supabase.auth.currentUser;
  if (user == null) return null;

  try {
    final response = await supabase
        .from('customers')
        .select('id, full_name, phone, address, user_id, email')
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;
    return CustomerProfile.fromSupabase(Map<String, dynamic>.from(response));
  } catch (error) {
    farmDebugLog('Failed to fetch current user customer profile: $error');
    return null;
  }
}

Future<void> saveCurrentCustomerProfile({
  required String fullName,
  required String phone,
  required String address,
}) async {
  await secureSaveCurrentCustomerAndGetId(
    fullName: fullName,
    phone: phone,
    address: address,
  );
}

Future<List<FarmerOrderSummary>> fetchFarmerOrderSummaries(
    String farmerId) async {
  if (farmerId.isEmpty) return [];
  try {
    final response = await supabase
        .from('order_items')
        .select(
            'order_id, product_name, quantity, line_total, farmer_earning_amount, farmer_id')
        .eq('farmer_id', farmerId)
        .order('created_at', ascending: false)
        .limit(50);
    return (response as List)
        .map((item) =>
            FarmerOrderSummary.fromSupabase(Map<String, dynamic>.from(item)))
        .toList();
  } catch (error) {
    farmDebugLog('Farmer order summaries unavailable: $error');
    return [];
  }
}

Future<FarmerProfile?> fetchCurrentFarmerProfile() async {
  final user = supabase.auth.currentUser;
  if (user == null) return null;
  try {
    final response = await supabase
        .from('farmer_profiles')
        .select(
            'id, user_id, email, farm_name, farmer_name, phone, parish, address, bio, verification_status, payout_method, payout_details, created_at')
        .eq('user_id', user.id)
        .maybeSingle();
    if (response == null) return null;
    return FarmerProfile.fromSupabase(Map<String, dynamic>.from(response));
  } catch (error) {
    farmDebugLog('Farmer profile unavailable: $error');
    return null;
  }
}

Future<List<FarmerProfile>> fetchFarmerProfiles() async {
  final allowed = await isCurrentUserAdminFromDatabase();
  if (!allowed) return [];
  try {
    final response = await supabase
        .from('farmer_profiles')
        .select(
            'id, user_id, email, farm_name, farmer_name, phone, parish, address, bio, verification_status, payout_method, payout_details, created_at')
        .order('created_at', ascending: false);
    return (response as List)
        .map((item) =>
            FarmerProfile.fromSupabase(Map<String, dynamic>.from(item)))
        .toList();
  } catch (error) {
    farmDebugLog('Farmer profiles unavailable: $error');
    return [];
  }
}

Future<void> saveFarmerProfile({
  required String farmName,
  required String farmerName,
  required String phone,
  required String parish,
  required String address,
  required String bio,
  required String payoutMethod,
  required String payoutDetails,
}) async {
  final user = supabase.auth.currentUser;
  if (user == null) return;
  final payload = {
    'user_id': user.id,
    'email': user.email,
    'farm_name': farmName,
    'farmer_name': farmerName,
    'phone': phone,
    'parish': parish,
    'address': address,
    'bio': bio,
    'verification_status': 'pending',
    'payout_method': payoutMethod,
    'payout_details': payoutDetails,
  };
  final existing = await fetchCurrentFarmerProfile();
  if (existing == null || existing.id.isEmpty) {
    await supabase.from('farmer_profiles').insert(payload);
  } else {
    await supabase
        .from('farmer_profiles')
        .update(payload)
        .eq('id', existing.id);
  }

  await createAdminNotification(
    title: 'Farmer profile submitted',
    message: '$farmerName submitted or updated a farmer profile for $farmName.',
    type: 'admin',
  );
}

Future<void> updateFarmerVerification(String farmerId, String status) async {
  await requireAdminAccess();
  await supabase
      .from('farmer_profiles')
      .update({'verification_status': status}).eq('id', farmerId);
}

Future<List<Product>> fetchFarmerProducts(String farmerId) async {
  if (farmerId.isEmpty) return [];
  try {
    final response = await supabase
        .from('products')
        .select(
            'id, name, description, price, unit, image_url, is_available, stock_quantity, created_at, category, is_organic, is_local, harvest_date, farmer_id, farmer_name, farm_name, parish, approval_status, platform_commission_percent, original_price, discount_price, discount_percent, discount_label, discount_starts_at, discount_ends_at, is_discount_active, product_status, ready_soon, estimated_ready_date, expected_stock_quantity, is_deal_of_day, deal_rank, subscribe_save_enabled, subscribe_save_discount_percent')
        .eq('farmer_id', farmerId)
        .order('created_at', ascending: false);
    return (response as List)
        .map((item) => Product.fromSupabase(Map<String, dynamic>.from(item)))
        .toList();
  } catch (error) {
    farmDebugLog(
        'Farmer products unavailable, retrying without local origin: $error');
    try {
      final response = await supabase
          .from('products')
          .select(
              'id, name, description, price, unit, image_url, is_available, stock_quantity, created_at, category, is_organic, harvest_date, farmer_id, farmer_name, farm_name, parish, approval_status, platform_commission_percent, original_price, discount_price, discount_percent, discount_label, discount_starts_at, discount_ends_at, is_discount_active, product_status, ready_soon, estimated_ready_date, expected_stock_quantity, is_deal_of_day, deal_rank, subscribe_save_enabled, subscribe_save_discount_percent')
          .eq('farmer_id', farmerId)
          .order('created_at', ascending: false);
      return (response as List)
          .map((item) => Product.fromSupabase(Map<String, dynamic>.from(item)))
          .toList();
    } catch (fallbackError) {
      farmDebugLog('Farmer products fallback unavailable: $fallbackError');
      return [];
    }
  }
}

Future<void> createFarmerProduct({
  required FarmerProfile farmer,
  required String name,
  required double price,
  required int stockQuantity,
  required String category,
  required bool isOrganic,
  bool isLocal = true,
  String? description,
  String? unit,
  String? imageUrl,
  bool isDiscountActive = false,
  double? originalPrice,
  double? discountPrice,
  double? discountPercent,
  String? discountLabel,
  String? discountStartsAt,
  String? discountEndsAt,
  bool readySoon = false,
  String? estimatedReadyDate,
  int? expectedStockQuantity,
  bool isDealOfDay = false,
  int? dealRank,
  bool subscribeSaveEnabled = false,
  double? subscribeSaveDiscountPercent,
}) async {
  final cleanName = name.trim();
  if (cleanName.isEmpty) {
    throw Exception('Please enter a product name.');
  }
  if (price <= 0) {
    throw Exception('Please enter a valid product price.');
  }
  if (stockQuantity < 0) {
    throw Exception('Stock quantity cannot be negative.');
  }

  final marketplacePayload = {
    'name': cleanName,
    'price': price,
    'stock_quantity': stockQuantity,
    'is_available': false,
    'category': normalizeProductCategory(category),
    'is_organic': isOrganic,
    'is_local': isLocal,
    'harvest_date': todayIsoDate(),
    'description':
        description?.trim().isEmpty == true ? null : description?.trim(),
    'unit': unit?.trim().isEmpty == true ? null : unit?.trim(),
    'image_url': imageUrl?.trim().isEmpty == true ? null : imageUrl?.trim(),
    'farmer_id': farmer.id,
    'farmer_name': farmer.farmerName,
    'farm_name': farmer.farmName,
    'parish': farmer.parish,
    'approval_status': 'pending',
    'platform_commission_percent': 10,
    'original_price': originalPrice,
    'discount_price': discountPrice,
    'discount_percent': discountPercent,
    'discount_label': discountLabel,
    'discount_starts_at': discountStartsAt,
    'discount_ends_at': discountEndsAt,
    'is_discount_active': isDiscountActive,
    'product_status': readySoon ? 'ready_soon' : 'available',
    'ready_soon': readySoon,
    'estimated_ready_date': estimatedReadyDate,
    'expected_stock_quantity': expectedStockQuantity,
    'is_deal_of_day': isDealOfDay,
    'deal_rank': dealRank,
    'subscribe_save_enabled': subscribeSaveEnabled,
    'subscribe_save_discount_percent': subscribeSaveDiscountPercent,
  };

  try {
    await supabase.from('products').insert(marketplacePayload);
  } catch (error) {
    final errorText = error.toString().toLowerCase();

    final looksLikeMissingMarketplaceColumn = errorText.contains('column') ||
        errorText.contains('schema cache') ||
        errorText.contains('pgrst204');

    if (!looksLikeMissingMarketplaceColumn) {
      farmDebugLog('Farmer product insert failed: $error');
      throw Exception(
          'Could not submit product. Please make sure your farmer profile is approved and linked to this account.');
    }

    farmDebugLog(
      'Marketplace columns unavailable, using compatible product insert: $error',
    );

    try {
      await createProduct(
        name: cleanName,
        price: price,
        stockQuantity: stockQuantity,
        isAvailable: false,
        category: normalizeProductCategory(category),
        isOrganic: isOrganic,
        isLocal: isLocal,
        description:
            description?.trim().isEmpty == true ? null : description?.trim(),
        unit: unit?.trim().isEmpty == true ? null : unit?.trim(),
        imageUrl: imageUrl?.trim().isEmpty == true ? null : imageUrl?.trim(),
      );
    } catch (fallbackError) {
      farmDebugLog('Compatible farmer product insert failed: $fallbackError');
      throw Exception(
          'Could not submit product. Please make sure your account has permission to add products.');
    }
  }

  await createAdminNotification(
    title: 'Product awaiting approval',
    message: '${farmer.farmName} submitted $cleanName for review.',
    type: 'admin',
  );
}

Future<void> updateProductApproval(String productId, String status) async {
  await adminUpdateProduct(
    productId: productId,
    approvalStatus: status,
    isAvailable: status == 'approved',
    adminNote: 'Admin changed product approval to $status from app',
  );
}

Future<List<FarmerPayout>> fetchFarmerPayouts({String? farmerId}) async {
  try {
    dynamic query = supabase
        .from('farmer_payouts')
        .select(
            'id, farmer_id, order_id, gross_amount, commission_amount, net_amount, payout_status, payout_method, payout_reference, released_at, created_at')
        .order('created_at', ascending: false);
    if (farmerId != null && farmerId.isNotEmpty)
      query = query.eq('farmer_id', farmerId);
    final response = await query;
    return (response as List)
        .map((item) =>
            FarmerPayout.fromSupabase(Map<String, dynamic>.from(item)))
        .toList();
  } catch (error) {
    farmDebugLog('Farmer payouts unavailable: $error');
    return [];
  }
}

Future<void> updateFarmerPayoutStatus({
  required String payoutId,
  required String status,
  String? reference,
}) async {
  await requireAdminAccess();
  final update = {
    'payout_status': status,
    if (reference != null && reference.trim().isNotEmpty)
      'payout_reference': reference.trim(),
    if (status == 'released') 'released_at': DateTime.now().toIso8601String(),
  };
  await supabase.from('farmer_payouts').update(update).eq('id', payoutId);
}

Map<String, double> marketplaceAmounts(Product product, int quantity) {
  final gross = product.effectivePrice * quantity;
  final rate = product.platformCommissionPercent <= 0
      ? 10
      : product.platformCommissionPercent;
  final commission = gross * (rate / 100);
  return {
    'gross': gross,
    'commission': commission,
    'farmer': gross - commission,
  };
}

Future<CouponValidationResult> validateCouponForCheckout({
  required String code,
  required double orderTotal,
}) async {
  final response = await supabase.rpc(
    'validate_coupon_for_checkout',
    params: {
      'p_code': code.trim().toUpperCase(),
      'p_order_total': orderTotal,
    },
  );

  return CouponValidationResult.fromMap(
    Map<String, dynamic>.from(response as Map),
  );
}

Future<Coupon?> fetchActiveCoupon(String code) async {
  final cleanCode = code.trim().toUpperCase();
  if (cleanCode.isEmpty) return null;

  try {
    final response = await supabase
        .from('coupons')
        .select(
            'id, code, discount_type, discount_value, minimum_order, is_active')
        .eq('code', cleanCode)
        .eq('is_active', true)
        .maybeSingle();

    if (response == null) return null;
    return Coupon.fromSupabase(Map<String, dynamic>.from(response));
  } catch (error) {
    farmDebugLog('Coupon lookup failed: $error');
    return null;
  }
}

Future<List<Coupon>> fetchCoupons() async {
  final allowed = await isCurrentUserAdminFromDatabase();
  if (!allowed) return [];

  try {
    final response = await supabase
        .from('coupons')
        .select(
            'id, code, discount_type, discount_value, minimum_order, is_active')
        .order('created_at', ascending: false);

    return (response as List)
        .map((item) => Coupon.fromSupabase(Map<String, dynamic>.from(item)))
        .toList();
  } catch (error) {
    farmDebugLog('Failed to fetch coupons: $error');
    return [];
  }
}

Future<void> createCoupon({
  required String code,
  required String discountType,
  required double discountValue,
  required double? minimumOrder,
  required bool isActive,
}) async {
  await requireAdminAccess();
  await supabase.rpc(
    'admin_upsert_coupon',
    params: {
      'p_coupon_id': null,
      'p_code': code.trim().toUpperCase(),
      'p_discount_type': discountType,
      'p_discount_value': discountValue,
      'p_minimum_order': minimumOrder ?? 0,
      'p_is_active': isActive,
      'p_starts_at': null,
      'p_ends_at': null,
      'p_usage_limit': null,
      'p_description': 'Created from admin dashboard',
      'p_admin_note': 'Coupon created from Flutter admin dashboard',
    },
  );
}

Future<void> updateCouponAvailability(String couponId, bool isActive) async {
  await requireAdminAccess();
  await supabase.rpc(
    'admin_upsert_coupon',
    params: {
      'p_coupon_id': couponId,
      'p_code': null,
      'p_discount_type': null,
      'p_discount_value': null,
      'p_minimum_order': null,
      'p_is_active': isActive,
      'p_starts_at': null,
      'p_ends_at': null,
      'p_usage_limit': null,
      'p_description': null,
      'p_admin_note': isActive
          ? 'Coupon reactivated from Flutter admin dashboard'
          : 'Coupon disabled from Flutter admin dashboard',
    },
  );
}

Future<void> createSupportTicket({
  required String subject,
  required String message,
}) async {
  final user = supabase.auth.currentUser;
  await supabase.from('support_tickets').insert({
    'user_id': user?.id,
    'email': user?.email ?? '',
    'subject': subject,
    'message': message,
    'status': 'open',
  });

  await createAdminNotification(
    title: 'New support message',
    message: '${user?.email ?? 'A customer'} sent: $subject',
    type: 'support',
  );
}

Future<List<SupportTicket>> fetchMySupportTickets() async {
  final user = supabase.auth.currentUser;
  if (user == null) return [];

  try {
    final response = await supabase
        .from('support_tickets')
        .select('id, email, subject, message, status, admin_reply, created_at')
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(30);

    return (response as List)
        .map((item) =>
            SupportTicket.fromSupabase(Map<String, dynamic>.from(item)))
        .toList();
  } catch (error) {
    farmDebugLog('Failed to fetch this user support tickets: $error');
    return [];
  }
}

Future<void> updateSupportTicket({
  required String ticketId,
  required String status,
  String? adminReply,
}) async {
  await requireAdminAccess();
  await supabase.from('support_tickets').update({
    'status': status,
    'admin_reply': adminReply,
  }).eq('id', ticketId);
}

Future<List<ProductReview>> _attachCustomerProfileNames(
    List<ProductReview> reviews) async {
  final userIds = reviews
      .where((review) => review.userId.trim().isNotEmpty)
      .map((review) => review.userId.trim())
      .toSet()
      .toList();

  if (userIds.isEmpty) return reviews;

  try {
    final response = await supabase
        .from('customers')
        .select('user_id, full_name')
        .inFilter('user_id', userIds);

    final namesByUserId = <String, String>{};
    for (final row in response as List) {
      final data = Map<String, dynamic>.from(row as Map);
      final userId = (data['user_id'] ?? '').toString().trim();
      final name = _cleanReviewNameCandidate(data['full_name']?.toString());
      if (userId.isNotEmpty && name.isNotEmpty) {
        namesByUserId[userId] = name;
      }
    }

    if (namesByUserId.isEmpty) return reviews;

    return reviews.map((review) {
      final profileName = namesByUserId[review.userId.trim()];
      final displayName = safeReviewDisplayName(
        profileName: profileName,
        reviewName: review.customerName,
        email: review.email,
      );
      return review.copyWith(customerName: displayName);
    }).toList();
  } catch (error) {
    farmDebugLog('Review customer names lookup skipped: $error');
    return reviews;
  }
}

Future<void> createProductReview({
  required String productId,
  required String productName,
  required int rating,
  required String comment,
}) async {
  final user = supabase.auth.currentUser;
  final customerName = await currentReviewCustomerName();
  final payload = <String, dynamic>{
    'product_id': productId.isEmpty ? null : productId,
    'product_name': productName,
    'user_id': user?.id,
    'customer_name': customerName,
    'email': user?.email ?? '',
    'rating': rating,
    'comment': comment,
  };

  try {
    await supabase.from('product_reviews').insert(payload);
  } catch (error) {
    final message = error.toString().toLowerCase();
    if (message.contains('customer_name') || message.contains('column')) {
      final fallbackPayload = Map<String, dynamic>.from(payload)
        ..remove('customer_name');
      await supabase.from('product_reviews').insert(fallbackPayload);
    } else {
      rethrow;
    }
  }

  await createAdminNotification(
    title: 'New product review',
    message:
        '$customerName left a $rating-star review for $productName.',
    type: 'review',
  );
}

Future<List<ProductReview>> fetchProductReviews() async {
  Future<List<ProductReview>> parseReviews(dynamic response) async {
    final reviews = (response as List)
        .map((item) =>
            ProductReview.fromSupabase(Map<String, dynamic>.from(item)))
        .toList();
    return _attachCustomerProfileNames(reviews);
  }

  try {
    final response = await supabase
        .from('product_reviews')
        .select(
            'id, product_id, product_name, user_id, customer_name, email, rating, comment, created_at, products(name)')
        .order('created_at', ascending: false)
        .limit(100);

    return parseReviews(response);
  } catch (firstError) {
    try {
      final response = await supabase
          .from('product_reviews')
          .select(
              'id, product_id, product_name, user_id, email, rating, comment, created_at, products(name)')
          .order('created_at', ascending: false)
          .limit(100);

      return parseReviews(response);
    } catch (secondError) {
      try {
        final response = await supabase
            .from('product_reviews')
            .select(
                'id, product_id, product_name, email, rating, comment, created_at, products(name)')
            .order('created_at', ascending: false)
            .limit(100);

        return parseReviews(response);
      } catch (error) {
        farmDebugLog('Failed to fetch product reviews: $error');
        return [];
      }
    }
  }
}

Future<bool> requireLoginForCheckout(BuildContext context) async {
  if (isLoggedIn) return true;

  final action = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
          ),
          child: GuestSignInPrompt(
            title: 'Sign in to complete your order',
            message:
                'Your farm box is saved. Log in or create an account to place your order.',
            primaryLabel: 'Log in',
            secondaryLabel: 'Create account',
            onLogin: () => Navigator.pop(sheetContext, 'login'),
            onCreateAccount: () => Navigator.pop(sheetContext, 'register'),
            onContinueBrowsing: () => Navigator.pop(sheetContext, 'cancel'),
          ),
        ),
      );
    },
  );

  if (action != 'login' && action != 'register') return false;
  if (!context.mounted) return false;

  final signedIn = await Navigator.push<bool>(
    context,
    MaterialPageRoute(
      builder: (_) => LoginScreen(
        returnToPrevious: true,
        startInRegister: action == 'register',
      ),
    ),
  );

  return signedIn == true || isLoggedIn;
}

String personalizedHeroMessage({
  required CustomerProfile? profile,
  required LoyaltySummary loyalty,
  required List<Product> allProducts,
  required List<Product> buyAgainProducts,
  required List<Product> favoriteProducts,
  required List<Product> recentlyViewedProducts,
}) {
  final firstName = personalizedFirstName(profile);
  // Keep the hero stable when a customer taps Favorite. Favorites should change
  // the heart state, not rewrite the hero message and shift the page.
  final categories = <String>[
    ...buyAgainProducts.map((product) => product.category),
    ...recentlyViewedProducts.map((product) => product.category),
  ].map((value) => value.trim()).where((value) => value.isNotEmpty).toList();

  final favoriteCategory = mostCommonText(categories);
  final freshFavorites = allProducts.where((product) {
    return isProductHarvestedThisWeek(product) &&
        (favoriteCategory == null || product.category == favoriteCategory);
  }).toList();

  if (buyAgainProducts.isEmpty && recentlyViewedProducts.isEmpty) {
    return 'Welcome, $firstName — fresh local picks are ready for your first farm box.';
  }
  if (loyalty.tier == 'Platinum') {
    return '$firstName, your Platinum harvest picks are ready with priority deals.';
  }
  if (freshFavorites.isNotEmpty && favoriteCategory != null) {
    return 'Fresh $favoriteCategory picked for you today, $firstName.';
  }
  if (buyAgainProducts.isNotEmpty) {
    return '${buyAgainProducts.first.name} and more favorites are ready to buy again.';
  }
  return 'Fresh local produce picked for you today, $firstName.';
}

List<Product> sortProductsForPersonalization({
  required List<Product> products,
  required List<Product> recentlyViewedProducts,
  required List<Product> buyAgainProducts,
  required List<Product> favoriteProducts,
}) {
  final boughtIds = buyAgainProducts.map((product) => product.id).toSet();
  final viewedIds = recentlyViewedProducts.map((product) => product.id).toSet();

  // Favorites should update the heart icon without immediately reordering the
  // shop/home grids. Keeping favorites out of the live sort prevents cards from
  // jumping around when a customer taps the heart.
  final signalCategories = <String>{
    ...buyAgainProducts.map((product) => product.category.toLowerCase()),
    ...recentlyViewedProducts.map((product) => product.category.toLowerCase()),
  }..removeWhere((category) => category.trim().isEmpty);

  int score(Product product) {
    var value = 0;
    if (boughtIds.contains(product.id)) value += 80;
    if (viewedIds.contains(product.id)) value += 55;
    if (signalCategories.contains(product.category.toLowerCase())) value += 35;
    if (product.showAsDealOfDay || product.hasActiveDiscount) value += 25;
    if (isProductHarvestedThisWeek(product)) value += 20;
    if (product.isLowStock) value += 8;
    if (!product.canAddToCart) value -= 100;
    return value;
  }

  final output = List<Product>.from(products);
  output.sort((a, b) {
    final byScore = score(b).compareTo(score(a));
    if (byScore != 0) return byScore;
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });
  return output;
}

List<PopularCategorySummary> buildPopularCategorySummaries(
  List<Product> products,
) {
  final grouped = <String, List<Product>>{};
  final seenProductIds = <String>{};

  for (final product in products) {
    final id = product.id.trim();
    if (id.isNotEmpty && !seenProductIds.add(id)) continue;
    if (!isVisibleCustomerProduct(product)) continue;

    final category = normalizeProductCategory(product.category);
    grouped.putIfAbsent(category, () => <Product>[]).add(product);
  }

  final summaries = grouped.entries
      .where((entry) => entry.value.isNotEmpty)
      .map(
        (entry) => PopularCategorySummary(
          name: entry.key,
          availableItemCount: entry.value.length,
          previewProduct: entry.value.firstWhere(
            (product) => cleanHostedImageUrl(product.imageUrl) != null,
            orElse: () => entry.value.first,
          ),
        ),
      )
      .toList();

  int categoryOrder(String category) {
    final index = productCategoryOptions.indexWhere(
      (option) => option.toLowerCase() == category.toLowerCase(),
    );
    return index == -1 ? productCategoryOptions.length : index;
  }

  summaries.sort((a, b) {
    final countCompare = b.availableItemCount.compareTo(a.availableItemCount);
    if (countCompare != 0) return countCompare;

    final orderCompare = categoryOrder(a.name).compareTo(categoryOrder(b.name));
    if (orderCompare != 0) return orderCompare;

    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });

  return summaries.take(8).toList();
}

List<Product> buildRecommendedForYouProducts({
  required List<Product> allProducts,
  required List<Product> recentlyViewedProducts,
  required List<Product> buyAgainProducts,
  required List<Product> favoriteProducts,
  String selectedCategory = 'All',
  Set<String> excludeIds = const {},
}) {
  final visibleProducts = uniqueVisibleProducts(allProducts, limit: 500);
  final excludedIds = <String>{
    ...excludeIds,
    ...recentlyViewedProducts.map((product) => product.id),
    ...buyAgainProducts.map((product) => product.id),
  };
  final seen = <String>{};
  final output = <Product>[];

  void add(Product product) {
    if (output.length >= 8) return;
    if (!isVisibleCustomerProduct(product)) return;
    if (excludedIds.contains(product.id)) return;
    if (!seen.add(product.id)) return;
    output.add(product);
  }

  // Do not use favorites as an instant recommendation signal. Tapping the
  // heart should only update the heart state, not reshuffle product rails.
  final signalCategories = <String>{
    ...recentlyViewedProducts.map((product) => product.category.toLowerCase()),
    ...buyAgainProducts.map((product) => product.category.toLowerCase()),
  }..removeWhere((category) => category.trim().isEmpty);

  for (final product in visibleProducts) {
    if (product.showAsDealOfDay || product.hasActiveDiscount) add(product);
  }

  for (final product in visibleProducts) {
    if (signalCategories.contains(product.category.toLowerCase())) add(product);
  }

  if (selectedCategory != 'All') {
    final selected = selectedCategory.toLowerCase();
    for (final product in visibleProducts) {
      if (product.category.toLowerCase() == selected ||
          product.name.toLowerCase().contains(selected)) {
        add(product);
      }
    }
  }

  for (final product in visibleProducts) {
    if (isProductHarvestedThisWeek(product) || product.isLowStock) add(product);
  }

  for (final product in visibleProducts) {
    add(product);
  }

  return output;
}

List<Product> buildSmartRecommendations({
  required List<Product> products,
  required List<Product> recentlyViewed,
  required String selectedCategory,
}) {
  return buildRecommendedForYouProducts(
    allProducts: products,
    recentlyViewedProducts: recentlyViewed,
    buyAgainProducts: const [],
    favoriteProducts: const [],
    selectedCategory: selectedCategory,
  );
}

Future<LaunchChecklistSnapshot> buildLaunchChecklistSnapshot() async {
  await requireAdminAccess();

  final products = await fetchProducts();
  final visibleProducts = products.where(isVisibleCustomerProduct).toList();
  final activeProducts =
      visibleProducts.where((product) => product.canAddToCart).toList();
  final productsWithImages = visibleProducts
      .where((product) => cleanHostedImageUrl(product.imageUrl) != null)
      .length;
  final outOfStockVisible =
      visibleProducts.where((product) => product.isOutOfStock).length;

  List<HomeHeroSlide> heroSlides = <HomeHeroSlide>[];
  try {
    heroSlides = await fetchAdminHomeHeroSlides();
  } catch (_) {
    heroSlides = <HomeHeroSlide>[];
  }

  List<AdminOrder> orders = <AdminOrder>[];
  try {
    orders = await fetchAdminOrders();
  } catch (_) {
    orders = <AdminOrder>[];
  }

  final uploadedHeroSlides = heroSlides
      .where((slide) =>
          !slide.id.startsWith('default-') &&
          cleanHostedImageUrl(slide.imageUrl) != null)
      .length;

  LaunchCheckItem ready({
    required String title,
    required String detail,
    required IconData icon,
  }) {
    return LaunchCheckItem(
      title: title,
      status: 'Ready',
      detail: detail,
      icon: icon,
      color: FarmColors.success,
    );
  }

  LaunchCheckItem review({
    required String title,
    required String detail,
    required IconData icon,
  }) {
    return LaunchCheckItem(
      title: title,
      status: 'Review',
      detail: detail,
      icon: icon,
      color: FarmColors.warning,
    );
  }

  LaunchCheckItem action({
    required String title,
    required String detail,
    required IconData icon,
  }) {
    return LaunchCheckItem(
      title: title,
      status: 'Action',
      detail: detail,
      icon: icon,
      color: FarmColors.danger,
    );
  }

  final imageTarget = visibleProducts.length < 3 ? visibleProducts.length : 3;
  final checks = <LaunchCheckItem>[
    ready(
      title: 'Protected access',
      detail: 'Current user passed the protected access check.',
      icon: Icons.admin_panel_settings_outlined,
    ),
    activeProducts.isNotEmpty
        ? ready(
            title: 'Customer products',
            detail:
                '${activeProducts.length} in-stock products are visible for shopping. ${visibleProducts.length} total products are customer-visible.',
            icon: Icons.storefront_outlined,
          )
        : action(
            title: 'Customer products',
            detail:
                'Add or restock at least one approved visible product before launch.',
            icon: Icons.storefront_outlined,
          ),
    imageTarget == 0
        ? review(
            title: 'Product images',
            detail:
                'No visible products found yet. Add products, then upload clear images.',
            icon: Icons.image_outlined,
          )
        : productsWithImages >= imageTarget
            ? ready(
                title: 'Product images',
                detail:
                    '$productsWithImages visible products have customer-facing images.',
                icon: Icons.image_outlined,
              )
            : review(
                title: 'Product images',
                detail:
                    '$productsWithImages visible products have images. Upload more product photos for a premium shop feel.',
                icon: Icons.image_outlined,
              ),
    ready(
      title: 'Stock display',
      detail: outOfStockVisible == 0
          ? 'Out-of-stock products are supported and will show a friendly unavailable state when needed.'
          : '$outOfStockVisible out-of-stock products remain visible with friendly labels and disabled add buttons.',
      icon: Icons.inventory_2_outlined,
    ),
    uploadedHeroSlides >= 3
        ? ready(
            title: 'Hero slideshow',
            detail: 'All 3 home hero slides are uploaded from admin.',
            icon: Icons.photo_library_outlined,
          )
        : uploadedHeroSlides > 0
            ? review(
                title: 'Hero slideshow',
                detail:
                    '$uploadedHeroSlides of 3 home hero slides are custom uploaded. Add the rest before launch.',
                icon: Icons.photo_library_outlined,
              )
            : action(
                title: 'Hero slideshow',
                detail:
                    'Upload 3 strong home banner images in Admin > Hero before launch.',
                icon: Icons.photo_library_outlined,
              ),
    orders.isNotEmpty
        ? ready(
            title: 'Test order flow',
            detail:
                '${orders.length} orders exist. Open the newest order and confirm customer/admin views.',
            icon: Icons.receipt_long_outlined,
          )
        : review(
            title: 'Test order flow',
            detail:
                'Place at least one real test order, then verify order details, totals, and notifications.',
            icon: Icons.receipt_long_outlined,
          ),
    review(
      title: 'Notifications',
      detail:
          'After a test order, tap the admin notification and customer notification to confirm both open the correct order.',
      icon: Icons.notifications_active_outlined,
    ),
    ready(
      title: 'Checkout safety',
      detail:
          'Checkout rechecks product stock and blocks unavailable products before order placement.',
      icon: Icons.verified_user_outlined,
    ),
    ready(
      title: 'Terms & Privacy',
      detail:
          'Customer trust screens are present and ready for final phone testing.',
      icon: Icons.policy_outlined,
    ),
    (productsWithImages > 0 || uploadedHeroSlides > 0)
        ? ready(
            title: 'Storage uploads',
            detail:
                'Supabase Storage image upload path appears to be in use for products or hero slides.',
            icon: Icons.cloud_done_outlined,
          )
        : review(
            title: 'Storage uploads',
            detail:
                'Upload a product image and hero image from admin to confirm Storage policies on the deployed app.',
            icon: Icons.cloud_upload_outlined,
          ),
  ];

  return LaunchChecklistSnapshot(
    checks: checks,
    visibleProductCount: visibleProducts.length,
    activeProductCount: activeProducts.length,
    productImageCount: productsWithImages,
    heroSlideCount: uploadedHeroSlides,
    orderCount: orders.length,
  );
}

double loyaltyProgressValue(LoyaltySummary summary) {
  final lifetime = summary.lifetimePoints < 0 ? 0 : summary.lifetimePoints;
  if (lifetime >= 1000) return 1;
  if (lifetime >= 500) return ((lifetime - 500) / 500).clamp(0, 1).toDouble();
  return (lifetime / 500).clamp(0, 1).toDouble();
}

int loyaltyPointsToNextTier(LoyaltySummary summary) {
  final lifetime = summary.lifetimePoints < 0 ? 0 : summary.lifetimePoints;
  if (lifetime >= 1000) return 0;
  if (lifetime >= 500) return 1000 - lifetime;
  return 500 - lifetime;
}

String loyaltyNextTierName(LoyaltySummary summary) {
  final lifetime = summary.lifetimePoints < 0 ? 0 : summary.lifetimePoints;
  if (lifetime >= 1000) return 'Platinum';
  if (lifetime >= 500) return 'Platinum';
  return 'Gold';
}

Color loyaltyTierColor(String tier) {
  switch (tier.trim().toLowerCase()) {
    case 'platinum':
      return FarmColors.primaryDark;
    case 'gold':
      return FarmColors.gold;
    default:
      return FarmColors.green;
  }
}

String farmNotificationTypeLabel(FarmNotification notice) {
  switch (notice.type.trim().toLowerCase()) {
    case 'payment':
      return 'Payment';
    case 'delivery':
      return 'Delivery';
    case 'product_ready':
      return 'Ready';
    case 'stock':
      return 'Stock';
    case 'support':
      return 'Support';
    case 'review':
      return 'Review';
    case 'admin':
      return 'Admin';
    case 'order':
      return 'Order';
    default:
      return 'Update';
  }
}

Color farmNotificationAccent(FarmNotification notice) {
  switch (notice.type.trim().toLowerCase()) {
    case 'payment':
      return FarmColors.success;
    case 'delivery':
      return FarmColors.green;
    case 'stock':
      return FarmColors.warning;
    case 'support':
      return FarmColors.primaryDark;
    case 'review':
      return FarmColors.accent;
    default:
      return FarmColors.green;
  }
}
