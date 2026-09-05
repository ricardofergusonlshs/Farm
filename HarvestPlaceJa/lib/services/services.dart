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
            // Every HPJ upload path includes a timestamp, so this is always
            // a new object. Avoid Storage upsert because upsert requires
            // broader SELECT/UPDATE permissions than a normal upload.
            upsert: false,
          ),
        );

    return supabase.storage.from(productImageStorageBucket).getPublicUrl(path);
  } catch (error) {
    farmDebugLog('Product image storage upload failed: $error');
    final message = error.toString().toLowerCase();
    if (message.contains('bucket') || message.contains('not found')) {
      throw Exception(
        'Image upload setup needs attention. Please check storage settings.',
      );
    }
    if (message.contains('permission') ||
        message.contains('policy') ||
        message.contains('403') ||
        message.contains('401')) {
      throw Exception(
        'Image upload permission needs attention. Please check admin storage settings.',
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
            // Every HPJ upload path includes a timestamp, so this is always
            // a new object. Avoid Storage upsert because upsert requires
            // broader SELECT/UPDATE permissions than a normal upload.
            upsert: false,
          ),
        );

    return supabase.storage.from(productImageStorageBucket).getPublicUrl(path);
  } catch (error) {
    farmDebugLog('Hero image storage upload failed: $error');
    final message = error.toString().toLowerCase();
    if (message.contains('bucket') || message.contains('not found')) {
      throw Exception(
        'Image upload setup needs attention. Please check storage settings.',
      );
    }
    if (message.contains('permission') ||
        message.contains('policy') ||
        message.contains('403') ||
        message.contains('401')) {
      throw Exception(
        'Hero image upload permission needs attention. Please check admin storage settings.',
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
      'Hero slideshow setup needs attention before saving.',
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
  String? dedupeKey,
}) async {
  final cleanOrderId = orderId?.trim();
  final cleanDedupeKey = dedupeKey?.trim();
  final cleanUserId = userId?.trim();
  final cleanEmail = userEmail?.trim().toLowerCase();

  if ((cleanOrderId == null || cleanOrderId.isEmpty) &&
      (cleanDedupeKey == null || cleanDedupeKey.isEmpty)) {
    return false;
  }

  try {
    var query = supabase.from('notifications').select('id');

    if (cleanDedupeKey != null && cleanDedupeKey.isNotEmpty) {
      query = query.eq('dedupe_key', cleanDedupeKey);
    } else {
      query = query
          .eq('order_id', cleanOrderId!)
          .eq('type', type)
          .eq('title', title);
    }

    if (cleanUserId != null && cleanUserId.isNotEmpty) {
      query = query.eq('user_id', cleanUserId);
    } else if (cleanEmail != null && cleanEmail.isNotEmpty) {
      query = query.eq('user_email', cleanEmail);
    }

    final existing = await query.limit(1);
    return (existing as List).isNotEmpty;
  } catch (error) {
    // Older notification tables may not have action/dedupe/order columns.
    // Keep the existing compatibility path and let the insert/fallback run.
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

const String savedCartSource = 'mobile_app';

const String _savedCartProductSelectFields =
    'id, name, description, price, unit, image_url, is_available, stock_quantity, created_at, category, is_organic, is_local, harvest_date, farmer_id, farmer_name, farm_name, parish, approval_status, platform_commission_percent, original_price, discount_price, discount_percent, discount_label, discount_starts_at, discount_ends_at, is_discount_active, product_status, ready_soon, estimated_ready_date, expected_stock_quantity, is_deal_of_day, deal_rank, subscribe_save_enabled, subscribe_save_discount_percent, nutrient_strong, nutrient_good, nutrient_contains, nutrition_notes, nutrition_source, nutrition_verified, usda_fdc_id, serving_size_g';

class SavedCustomerProductSnapshot {
  final List<Product> favoriteProducts;
  final List<Product> recentlyViewedProducts;

  const SavedCustomerProductSnapshot({
    this.favoriteProducts = const <Product>[],
    this.recentlyViewedProducts = const <Product>[],
  });
}

String _cleanSavedProductId(String? value) {
  return (value ?? '').trim();
}

List<String> _uniqueSavedProductIds(Iterable<String> ids) {
  final seen = <String>{};
  final output = <String>[];

  for (final rawId in ids) {
    final id = _cleanSavedProductId(rawId);
    if (id.isEmpty) continue;
    if (seen.add(id)) output.add(id);
  }

  return output;
}

List<Product> _fallbackProductsBySavedIds({
  required List<String> ids,
  required List<Product> fallbackProducts,
}) {
  if (ids.isEmpty || fallbackProducts.isEmpty) return const <Product>[];

  final byId = <String, Product>{};
  for (final product in fallbackProducts) {
    final id = _cleanSavedProductId(product.id);
    if (id.isNotEmpty) byId[id] = product;
  }

  return ids
      .map((id) => byId[id])
      .whereType<Product>()
      .where(isVisibleCustomerProduct)
      .toList();
}

Future<List<Product>> _fetchSavedProductsByIdsInOrder({
  required List<String> ids,
  List<Product> fallbackProducts = const <Product>[],
}) async {
  final orderedIds = _uniqueSavedProductIds(ids);
  if (orderedIds.isEmpty) return const <Product>[];

  final fallback = _fallbackProductsBySavedIds(
    ids: orderedIds,
    fallbackProducts: fallbackProducts,
  );

  try {
    final response = await supabase
        .from('products')
        .select(_savedCartProductSelectFields)
        .inFilter('id', orderedIds);

    final byId = <String, Product>{};
    for (final item in response as List) {
      final product =
          Product.fromSupabase(Map<String, dynamic>.from(item as Map));
      final id = _cleanSavedProductId(product.id);
      if (id.isNotEmpty && isVisibleCustomerProduct(product)) {
        byId[id] = product;
      }
    }

    final products =
        orderedIds.map((id) => byId[id]).whereType<Product>().toList();

    if (products.isNotEmpty) return products;
  } catch (error) {
    farmDebugLog('Saved product details load skipped safely: $error');
  }

  return fallback;
}

Future<List<String>> fetchFavoriteProductIdsForCurrentUser({
  int limit = 120,
}) async {
  final user = supabase.auth.currentUser;
  if (user == null) return const <String>[];

  try {
    final response = await supabase
        .from('customer_favorites')
        .select('product_id, created_at')
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(limit);

    return _uniqueSavedProductIds(
      (response as List)
          .map((row) => (row as Map)['product_id']?.toString() ?? ''),
    );
  } catch (error) {
    farmDebugLog('Favorite product ids load skipped safely: $error');
    return const <String>[];
  }
}

Future<List<Product>> fetchFavoriteProductsForCurrentUser({
  List<Product> fallbackProducts = const <Product>[],
  int limit = 120,
}) async {
  final ids = await fetchFavoriteProductIdsForCurrentUser(limit: limit);
  return _fetchSavedProductsByIdsInOrder(
    ids: ids,
    fallbackProducts: fallbackProducts,
  );
}

Future<void> setFavoriteForCurrentUser(
  Product product, {
  required bool isFavorite,
}) async {
  final user = supabase.auth.currentUser;
  final productId = _cleanSavedProductId(product.id);
  if (user == null || productId.isEmpty) return;

  try {
    if (isFavorite) {
      await supabase.from('customer_favorites').upsert(
        {
          'user_id': user.id,
          'product_id': productId,
          'created_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'user_id,product_id',
      );
    } else {
      await supabase
          .from('customer_favorites')
          .delete()
          .eq('user_id', user.id)
          .eq('product_id', productId);
    }
  } catch (error) {
    farmDebugLog('Favorite save/remove skipped safely: $error');
  }
}

Future<void> saveFavoriteForCurrentUser(Product product) {
  return setFavoriteForCurrentUser(product, isFavorite: true);
}

Future<void> removeFavoriteForCurrentUser(Product product) {
  return setFavoriteForCurrentUser(product, isFavorite: false);
}

Future<void> saveRecentlyViewedForCurrentUser(Product product) async {
  final user = supabase.auth.currentUser;
  final productId = _cleanSavedProductId(product.id);
  if (user == null || productId.isEmpty) return;

  try {
    await supabase.from('customer_recently_viewed').upsert(
      {
        'user_id': user.id,
        'product_id': productId,
        'viewed_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'user_id,product_id',
    );
  } catch (error) {
    farmDebugLog('Recently viewed save skipped safely: $error');
  }
}

Future<List<String>> fetchRecentlyViewedProductIdsForCurrentUser({
  int limit = 30,
}) async {
  final user = supabase.auth.currentUser;
  if (user == null) return const <String>[];

  try {
    final response = await supabase
        .from('customer_recently_viewed')
        .select('product_id, viewed_at')
        .eq('user_id', user.id)
        .order('viewed_at', ascending: false)
        .limit(limit);

    return _uniqueSavedProductIds(
      (response as List)
          .map((row) => (row as Map)['product_id']?.toString() ?? ''),
    );
  } catch (error) {
    farmDebugLog('Recently viewed ids load skipped safely: $error');
    return const <String>[];
  }
}

Future<List<Product>> fetchRecentlyViewedProductsForCurrentUser({
  List<Product> fallbackProducts = const <Product>[],
  int limit = 30,
}) async {
  final ids = await fetchRecentlyViewedProductIdsForCurrentUser(limit: limit);
  return _fetchSavedProductsByIdsInOrder(
    ids: ids,
    fallbackProducts: fallbackProducts,
  );
}

Future<SavedCustomerProductSnapshot> fetchSavedCustomerProductSnapshot({
  List<Product> fallbackFavoriteProducts = const <Product>[],
  List<Product> fallbackRecentlyViewedProducts = const <Product>[],
}) async {
  if (!isLoggedIn || supabase.auth.currentUser == null) {
    return SavedCustomerProductSnapshot(
      favoriteProducts: fallbackFavoriteProducts,
      recentlyViewedProducts: fallbackRecentlyViewedProducts,
    );
  }

  try {
    final results = await Future.wait<List<Product>>([
      fetchFavoriteProductsForCurrentUser(
        fallbackProducts: fallbackFavoriteProducts,
      ),
      fetchRecentlyViewedProductsForCurrentUser(
        fallbackProducts: fallbackRecentlyViewedProducts,
      ),
    ]);

    return SavedCustomerProductSnapshot(
      favoriteProducts: results[0],
      recentlyViewedProducts: results[1],
    );
  } catch (error) {
    farmDebugLog('Saved customer product snapshot skipped safely: $error');
    return SavedCustomerProductSnapshot(
      favoriteProducts: fallbackFavoriteProducts,
      recentlyViewedProducts: fallbackRecentlyViewedProducts,
    );
  }
}

Future<void> saveCartItemForCurrentUser(Product product) async {
  final user = supabase.auth.currentUser;
  if (user == null || product.id.trim().isEmpty || !product.canAddToCart) {
    return;
  }

  try {
    final existing = await supabase
        .from('cart_items')
        .select('quantity')
        .eq('user_id', user.id)
        .eq('product_id', product.id)
        .maybeSingle();

    final currentQuantity =
        existing == null ? 0 : Product._toInt((existing as Map)['quantity']);
    final maxQuantity =
        product.stockQuantity > 0 ? product.stockQuantity : 999999;
    final nextQuantity = (currentQuantity + 1).clamp(1, maxQuantity).toInt();

    await supabase.from('cart_items').upsert(
      {
        'user_id': user.id,
        'product_id': product.id,
        'quantity': nextQuantity,
        'unit_price': product.effectivePrice,
        'source': savedCartSource,
        'updated_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'user_id,product_id',
    );
  } catch (error) {
    farmDebugLog('Saved cart add skipped safely: $error');
  }
}

Future<void> removeCartItemForCurrentUser(Product product) async {
  final user = supabase.auth.currentUser;
  if (user == null || product.id.trim().isEmpty) return;

  try {
    final existing = await supabase
        .from('cart_items')
        .select('id, quantity')
        .eq('user_id', user.id)
        .eq('product_id', product.id)
        .maybeSingle();

    if (existing == null) return;

    final row = Map<String, dynamic>.from(existing as Map);
    final quantity = Product._toInt(row['quantity']);

    if (quantity <= 1) {
      await supabase
          .from('cart_items')
          .delete()
          .eq('user_id', user.id)
          .eq('product_id', product.id);
      return;
    }

    await supabase
        .from('cart_items')
        .update({
          'quantity': quantity - 1,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('user_id', user.id)
        .eq('product_id', product.id);
  } catch (error) {
    farmDebugLog('Saved cart remove skipped safely: $error');
  }
}

Future<void> setCartItemQuantityForCurrentUser({
  required Product product,
  required int quantity,
}) async {
  final user = supabase.auth.currentUser;
  if (user == null || product.id.trim().isEmpty) return;

  try {
    if (quantity <= 0) {
      await supabase
          .from('cart_items')
          .delete()
          .eq('user_id', user.id)
          .eq('product_id', product.id);
      return;
    }

    final maxQuantity =
        product.stockQuantity > 0 ? product.stockQuantity : quantity;
    final safeQuantity = quantity.clamp(1, maxQuantity).toInt();

    await supabase.from('cart_items').upsert(
      {
        'user_id': user.id,
        'product_id': product.id,
        'quantity': safeQuantity,
        'unit_price': product.effectivePrice,
        'source': savedCartSource,
        'updated_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'user_id,product_id',
    );
  } catch (error) {
    farmDebugLog('Saved cart quantity update skipped safely: $error');
  }
}

Future<void> clearSavedCartForCurrentUser() async {
  final user = supabase.auth.currentUser;
  if (user == null) return;

  try {
    await supabase.from('cart_items').delete().eq('user_id', user.id);
  } catch (error) {
    farmDebugLog('Saved cart clear skipped safely: $error');
  }
}

Future<List<CartLine>> fetchSavedCartLinesForCurrentUser() async {
  final user = supabase.auth.currentUser;
  if (user == null) return const <CartLine>[];

  try {
    // Do not use an embedded Supabase/PostgREST relationship here.
    // Some projects do not expose cart_items -> products immediately in the
    // PostgREST schema cache, even when the normal SQL join works.
    // This two-step load is safer: first read the customer's cart rows,
    // then fetch the matching products directly from the products table.
    final cartResponse = await supabase
        .from('cart_items')
        .select(
            'id, user_id, product_id, quantity, unit_price, source, created_at, updated_at')
        .eq('user_id', user.id)
        .order('updated_at', ascending: false)
        .limit(120);

    final cartRows = (cartResponse as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();

    if (cartRows.isEmpty) return const <CartLine>[];

    final productIds = cartRows
        .map((row) => (row['product_id'] ?? '').toString().trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    if (productIds.isEmpty) return const <CartLine>[];

    final productResponse = await supabase
        .from('products')
        .select(_savedCartProductSelectFields)
        .inFilter('id', productIds);

    final productsById = <String, Product>{};
    for (final item in productResponse as List) {
      final row = Map<String, dynamic>.from(item as Map);
      final product = Product.fromSupabase(row);
      if (product.id.trim().isNotEmpty) {
        productsById[product.id] = product;
      }
    }

    final lines = <CartLine>[];

    for (final row in cartRows) {
      final quantity = Product._toInt(row['quantity']);
      if (quantity <= 0) continue;

      final productId = (row['product_id'] ?? '').toString().trim();
      final product = productsById[productId];
      if (product == null || product.id.trim().isEmpty) continue;

      lines.add(
        CartLine(
          product: product,
          quantity: quantity,
        ),
      );
    }

    return lines;
  } catch (error) {
    farmDebugLog('Saved cart load skipped safely: $error');
    return const <CartLine>[];
  }
}

List<Product> expandCartLinesToProducts(List<CartLine> lines) {
  final products = <Product>[];

  for (final line in lines) {
    if (line.quantity <= 0) continue;
    for (var index = 0; index < line.quantity; index++) {
      products.add(line.product);
    }
  }

  return products;
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

const int referralRewardPoints = 100;

String cleanReferralCode(String value) {
  final clean =
      value.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9-]'), '');
  return clean.length > 40 ? clean.substring(0, 40) : clean;
}

String referralCodeForUserId(String userId) {
  final clean =
      userId.trim().replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
  if (clean.isEmpty) return 'HPJ-GUEST';
  final short =
      clean.length >= 8 ? clean.substring(0, 8) : clean.padRight(8, 'X');
  return 'HPJ-$short';
}

String buildCustomerReferralLink({
  required String referralCode,
  required String referrerId,
}) {
  final base = AppConfig.shareableAppLink.trim();
  final safeBase = base.isEmpty ? AppConfig.appName : base;
  final code = cleanReferralCode(referralCode);
  final cleanReferrerId = referrerId.trim();

  final uri = Uri.tryParse(safeBase);
  if (uri != null && uri.hasScheme) {
    final nextQuery = Map<String, String>.from(uri.queryParameters);
    nextQuery['ref'] = code;
    if (cleanReferrerId.isNotEmpty) {
      nextQuery['referrer'] = cleanReferrerId;
    }
    return uri.replace(queryParameters: nextQuery).toString();
  }

  final separator = safeBase.contains('?') ? '&' : '?';
  final referrerParam = cleanReferrerId.isEmpty
      ? ''
      : '&referrer=${Uri.encodeComponent(cleanReferrerId)}';
  return '$safeBase${separator}ref=${Uri.encodeComponent(code)}$referrerParam';
}

Map<String, String> _activeReferralParams() {
  final params = Map<String, String>.from(AppConfig.authCallbackParams);

  try {
    final uri = Uri.base;
    params.addAll(uri.queryParameters);
  } catch (_) {}

  return params;
}

String? _incomingReferralCodeFromParams() {
  final params = _activeReferralParams();
  final raw = params['ref'] ??
      params['referral'] ??
      params['referral_code'] ??
      params['invite'];
  if (raw == null) return null;
  final clean = cleanReferralCode(raw);
  return clean.isEmpty ? null : clean;
}

String? _incomingReferrerIdFromParams() {
  final params = _activeReferralParams();
  final raw = params['referrer'] ??
      params['referrer_id'] ??
      params['referrerUserId'] ??
      params['referrer_user_id'];
  if (raw == null) return null;
  final clean = raw.trim();
  return clean.isEmpty ? null : clean;
}

Future<void> recordIncomingReferralForCurrentUser() async {
  if (!isLoggedIn) return;

  final user = supabase.auth.currentUser;
  if (user == null) return;

  final referralCode = _incomingReferralCodeFromParams();
  final referrerId = _incomingReferrerIdFromParams();

  if (referralCode == null ||
      referrerId == null ||
      referrerId == user.id) {
    return;
  }

  final operationBoundary =
      captureHpjPrivateOperationBoundary();

  try {
    final referralLink = buildCustomerReferralLink(
      referralCode: referralCode,
      referrerId: referrerId,
    );

    await supabase.rpc(
      'record_customer_referral_secure',
      params: {
        'p_referrer_id': referrerId,
        'p_referral_code': referralCode,
        'p_referral_link': referralLink,
      },
    );

    if (!isHpjPrivateOperationBoundaryCurrent(operationBoundary)) {
      return;
    }
  } catch (error) {
    farmDebugLog(
      'Referral link capture skipped safely: $error',
    );
  }
}

Future<CustomerReferralSummary> fetchCustomerReferralSummary() async {
  if (!isLoggedIn) return const CustomerReferralSummary();

  final user = supabase.auth.currentUser;
  if (user == null) return const CustomerReferralSummary();

  try {
    final response = await supabase
        .from('customer_referrals')
        .select('status, points_awarded')
        .eq('referrer_id', user.id)
        .limit(500);

    var pending = 0;
    var completed = 0;
    var points = 0;

    for (final item in response as List) {
      final row = Map<String, dynamic>.from(item as Map);
      final status = (row['status'] ?? '').toString().trim().toLowerCase();
      final awarded = Product._toInt(row['points_awarded']);

      if (status == 'completed' || awarded > 0) {
        completed++;
        points += awarded;
      } else if (status != 'cancelled' &&
          status != 'canceled' &&
          status != 'rejected') {
        pending++;
      }
    }

    return CustomerReferralSummary(
      pendingCount: pending,
      completedCount: completed,
      pointsEarned: points,
    );
  } catch (_) {
    farmDebugLog('Referral summary unavailable. Continuing safely.');
    return const CustomerReferralSummary();
  }
}

Future<ReferralShareSnapshot> fetchReferralShareSnapshot() async {
  final operationBoundary = captureHpjPrivateOperationBoundary();
  final userId = operationBoundary.userId?.trim() ?? '';

  if (userId.isEmpty) {
    throw Exception('Please sign in to share your HPJ referral link.');
  }

  final code = referralCodeForUserId(userId);
  final link = buildCustomerReferralLink(
    referralCode: code,
    referrerId: userId,
  );

  final results = await Future.wait<dynamic>([
    fetchCustomerReferralSummary(),
    fetchLoyaltySummary(),
  ]);

  if (!isHpjPrivateOperationBoundaryCurrent(operationBoundary)) {
    throw const HpjPrivateMutationInterruptedException(
      'Your account changed while referral details were loading. Please try again.',
    );
  }

  final summary = results[0] as CustomerReferralSummary;
  final loyalty = results[1] as LoyaltySummary;

  final message =
      'I am inviting you to ${AppConfig.appName}. Shop fresh local produce, build your farm box, and track your order here: $link\n\nMy referral code: $code';

  return ReferralShareSnapshot(
    referralCode: code,
    referralLink: link,
    inviteMessage: message,
    referralSummary: summary,
    loyaltySummary: loyalty,
  );
}

Future<void> completeReferralRewardForCurrentUserFirstOrder({
  required String orderId,
}) async {
  final cleanOrderId = orderId.trim();

  if (!isLoggedIn || cleanOrderId.isEmpty) return;

  final user = supabase.auth.currentUser;
  if (user == null) return;

  final operationBoundary =
      captureHpjPrivateOperationBoundary();

  try {
    await supabase.rpc(
      'complete_referral_after_eligible_order',
      params: {
        'p_order_id': cleanOrderId,
      },
    );

    if (!isHpjPrivateOperationBoundaryCurrent(operationBoundary)) {
      return;
    }
  } catch (error) {
    // Rewards must never block the customer order flow. There is deliberately
    // no client-side reward fallback: only the server may mutate rewards.
    farmDebugLog(
      'Referral reward completion skipped safely: $error',
    );
  }
}

Future<LoyaltySummary> fetchLoyaltySummary() async {
  if (!isLoggedIn) {
    return const LoyaltySummary(points: 0, lifetimePoints: 0, tier: 'Green');
  }

  final operationBoundary = captureHpjPrivateOperationBoundary();
  final user = supabase.auth.currentUser;
  if (user == null || operationBoundary.userId != user.id) {
    return const LoyaltySummary(points: 0, lifetimePoints: 0, tier: 'Green');
  }

  await recordIncomingReferralForCurrentUser();

  if (!isHpjPrivateOperationBoundaryCurrent(operationBoundary)) {
    return const LoyaltySummary(points: 0, lifetimePoints: 0, tier: 'Green');
  }

  try {
    final response = await supabase
        .from('customer_loyalty_points')
        .select('points, lifetime_points, tier')
        .eq('user_id', user.id)
        .maybeSingle();

    if (!isHpjPrivateOperationBoundaryCurrent(operationBoundary)) {
      return const LoyaltySummary(points: 0, lifetimePoints: 0, tier: 'Green');
    }

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

    // No ledger row means this account has no recorded loyalty balance yet.
    return const LoyaltySummary(points: 0, lifetimePoints: 0, tier: 'Green');
  } catch (error) {
    // Loyalty is server-owned. Never invent a redeemable-looking balance from
    // paid order totals when the real ledger is temporarily unavailable.
    farmDebugLog(
      'Loyalty balance unavailable; returning safe zero balance: $error',
    );
    return const LoyaltySummary(points: 0, lifetimePoints: 0, tier: 'Green');
  }
}

Future<void> awardLoyaltyPointsForOrder({
  required String orderId,
  required double total,
}) async {
  final cleanOrderId = orderId.trim();

  if (!isLoggedIn || cleanOrderId.isEmpty) return;

  final user = supabase.auth.currentUser;
  if (user == null) return;

  // `total` remains in the public Dart signature so older call sites do not
  // break, but it is intentionally not used as reward authority. The secure
  // RPC reads the real order total from PostgreSQL.
  final operationBoundary =
      captureHpjPrivateOperationBoundary();

  try {
    await supabase.rpc(
      'award_loyalty_points_for_current_order',
      params: {
        'p_order_id': cleanOrderId,
      },
    );

    if (!isHpjPrivateOperationBoundaryCurrent(operationBoundary)) {
      return;
    }
  } catch (error) {
    // Never fall back to a direct loyalty_transactions INSERT.
    // Reward ledgers are server-owned after Repair 024.
    farmDebugLog(
      'Loyalty award skipped safely: $error',
    );
  }

  if (!isHpjPrivateOperationBoundaryCurrent(operationBoundary)) {
    return;
  }

  await completeReferralRewardForCurrentUserFirstOrder(
    orderId: cleanOrderId,
  );
}

Future<ProductTraceRecord?> fetchTraceRecordByCode(String code) async {
  final cleanCode = code.trim().toUpperCase();
  if (cleanCode.isEmpty) return null;

  try {
    final response = await supabase.rpc(
      'lookup_product_trace_record_secure',
      params: {
        'p_trace_code': cleanCode,
      },
    );

    if (response == null) return null;

    Map<String, dynamic>? row;

    if (response is Map) {
      row = Map<String, dynamic>.from(response);
    } else if (response is List && response.isNotEmpty) {
      final first = response.first;
      if (first is Map) {
        row = Map<String, dynamic>.from(first);
      }
    }

    if (row == null || row.isEmpty) return null;

    return ProductTraceRecord.fromSupabase(row);
  } catch (rpcError) {
    // Repair 025 deliberately does not fall back to a client UPDATE. If the
    // secure scan RPC is temporarily unavailable, a read-only lookup keeps a
    // valid trace code useful without weakening RLS or scan-count integrity.
    farmDebugLog(
      'Secure trace lookup unavailable; using read-only fallback: $rpcError',
    );

    try {
      final response = await supabase
          .from('product_trace_records')
          .select(
              'id, trace_code, product_name, farm_location, harvest_date, harvest_time, farmer_name, farming_method, batch_notes, qr_scan_count')
          .eq('trace_code', cleanCode)
          .maybeSingle();

      if (response == null) return null;

      return ProductTraceRecord.fromSupabase(
        Map<String, dynamic>.from(response),
      );
    } catch (fallbackError) {
      farmDebugLog('Trace lookup failed: $fallbackError');
      return null;
    }
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

class HpjPrivateOperationBoundary {
  final int generation;
  final String? userId;

  const HpjPrivateOperationBoundary({
    required this.generation,
    required this.userId,
  });
}

class HpjPrivateMutationInterruptedException implements Exception {
  final String message;

  const HpjPrivateMutationInterruptedException([
    this.message =
        'Your account changed while this request was processing. '
        'Refresh your activity before trying again.',
  ]);

  @override
  String toString() => message;
}


int _hpjIdempotencySequence = 0;

String newHpjIdempotencyKey(String operation) {
  final boundary = captureHpjPrivateOperationBoundary();

  if (!isHpjPrivateOperationBoundaryCurrent(boundary) ||
      boundary.userId == null ||
      boundary.userId!.trim().isEmpty) {
    throw const HpjPrivateMutationInterruptedException();
  }

  final cleanOperation = operation
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9_-]+'), '-');

  _hpjIdempotencySequence++;

  return '${cleanOperation.isEmpty ? 'mutation' : cleanOperation}:'
      '${boundary.userId}:'
      '${boundary.generation}:'
      '${DateTime.now().microsecondsSinceEpoch}:'
      '$_hpjIdempotencySequence';
}

final Set<String> _hpjPrivateMutationsInFlight = <String>{};

class HpjPrivateMutationLease {
  final String _scopedKey;
  final HpjPrivateOperationBoundary boundary;
  bool _released = false;

  HpjPrivateMutationLease._({
    required String scopedKey,
    required this.boundary,
  }) : _scopedKey = scopedKey;

  void ensureCurrent() {
    if (!isHpjPrivateOperationBoundaryCurrent(boundary)) {
      throw const HpjPrivateMutationInterruptedException();
    }
  }

  void release() {
    if (_released) return;
    _released = true;
    _hpjPrivateMutationsInFlight.remove(_scopedKey);
  }
}

HpjPrivateMutationLease acquireHpjPrivateMutation(
  String operationKey, {
  HpjPrivateOperationBoundary? expectedBoundary,
}) {
  final boundary =
      expectedBoundary ?? captureHpjPrivateOperationBoundary();

  if (!isHpjPrivateOperationBoundaryCurrent(boundary)) {
    throw const HpjPrivateMutationInterruptedException();
  }

  final userId = boundary.userId?.trim() ?? '';
  if (userId.isEmpty) {
    throw Exception('Please sign in before continuing.');
  }

  final cleanKey = operationKey.trim().toLowerCase();
  if (cleanKey.isEmpty) {
    throw ArgumentError.value(
      operationKey,
      'operationKey',
      'Mutation operation key cannot be empty.',
    );
  }

  final scopedKey = '$userId:$cleanKey';

  if (!_hpjPrivateMutationsInFlight.add(scopedKey)) {
    throw Exception(
      'This request is already being processed. Please wait for it to finish.',
    );
  }

  return HpjPrivateMutationLease._(
    scopedKey: scopedKey,
    boundary: boundary,
  );
}

bool _hpjPrivateBoundaryInitialized = false;
String? _hpjPrivateBoundaryUserId;
int _hpjPrivateBoundaryGeneration = 0;

String? _hpjOrdersCacheUserId;
String? _hpjBuyAgainCacheUserId;
String? _hpjNotificationsCacheUserId;

String? _hpjCurrentBoundaryUserId() {
  final raw = supabase.auth.currentUser?.id.trim() ?? '';
  return raw.isEmpty ? null : raw;
}

void _syncHpjPrivateBoundaryIdentity() {
  final currentUserId = _hpjCurrentBoundaryUserId();

  if (!_hpjPrivateBoundaryInitialized) {
    _hpjPrivateBoundaryInitialized = true;
    _hpjPrivateBoundaryUserId = currentUserId;
    return;
  }

  if (currentUserId == _hpjPrivateBoundaryUserId) return;

  _hpjPrivateBoundaryUserId = currentUserId;
  _hpjPrivateBoundaryGeneration++;

  // These cache owners are user-specific. Drop ownership immediately even
  // before the root auth listeners finish rebuilding the UI.
  _hpjOrdersCacheUserId = null;
  _hpjBuyAgainCacheUserId = null;
  _hpjNotificationsCacheUserId = null;
}

HpjPrivateOperationBoundary captureHpjPrivateOperationBoundary() {
  _syncHpjPrivateBoundaryIdentity();

  return HpjPrivateOperationBoundary(
    generation: _hpjPrivateBoundaryGeneration,
    userId: _hpjPrivateBoundaryUserId,
  );
}

bool isHpjPrivateOperationBoundaryCurrent(
  HpjPrivateOperationBoundary boundary,
) {
  _syncHpjPrivateBoundaryIdentity();

  return boundary.generation == _hpjPrivateBoundaryGeneration &&
      boundary.userId == _hpjPrivateBoundaryUserId;
}

void clearHpjPrivateAccountMemory({
  bool forceBoundary = false,
}) {
  _syncHpjPrivateBoundaryIdentity();

  if (forceBoundary) {
    _hpjPrivateBoundaryGeneration++;
  }

  _hpjOrdersCacheUserId = null;
  _hpjBuyAgainCacheUserId = null;
  _hpjNotificationsCacheUserId = null;
  _hpjPrivateMutationsInFlight.clear();

  PushNotificationService.clearPendingNavigationState();
  FarmDataCache.clearAll();
  hpjCurrentUserExperiencePreferences =
      UserExperiencePreferences.defaults;
}

Future<void> signOutFromHpjSession() async {
  clearHpjPrivateAccountMemory(forceBoundary: true);

  try {
    await PushNotificationService.unregisterCurrentDevice();
  } catch (error) {
    farmDebugLog('Push token cleanup skipped during sign out: $error');
  }

  // A second layer of protection: invalidate the Firebase token locally so a
  // stale server registration cannot continue delivering private pushes.
  await PushNotificationService.invalidateLocalPushToken();

  try {
    await supabase.auth.signOut();
  } finally {
    clearHpjPrivateAccountMemory();
  }
}

Future<void> clearPrivateSessionStateForGuestBrowsing() async {
  clearHpjPrivateAccountMemory();

  if (hasSupabaseSession) {
    try {
      await signOutFromHpjSession();
    } catch (error) {
      farmDebugLog(
          'Supabase sign out skipped while entering guest mode: $error');
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
  Object? lastError;

  for (var attempt = 1; attempt <= 2; attempt++) {
    try {
      final products = await fetchProducts(
        forceRefresh: forceRefresh || attempt > 1,
      ).timeout(
        timeout,
        onTimeout: () {
          farmDebugLog(
            'Product load timed out after ${timeout.inSeconds}s on attempt $attempt.',
          );
          if (cached != null && cached.isNotEmpty) return cached;
          throw TimeoutException('Product load timed out.');
        },
      );

      if (products.isNotEmpty) {
        return products;
      }

      if (cached != null && cached.isNotEmpty) {
        farmDebugLog('Product load returned empty, using cached products.');
        return cached;
      }
    } catch (error) {
      lastError = error;
      farmDebugLog('Product load attempt $attempt failed: $error');

      if (attempt < 2) {
        await Future<void>.delayed(const Duration(milliseconds: 700));
      }
    }
  }

  farmDebugLog(
      'Product load fallback used: ${lastError ?? 'No products returned'}');
  return cached ?? const <Product>[];
}

Future<List<Product>> _fetchProductsUncached() async {
  final extendedSelect =
      'id, name, description, price, unit, image_url, is_available, stock_quantity, created_at, category, is_organic, is_local, harvest_date, farmer_id, farmer_name, farm_name, parish, approval_status, platform_commission_percent, original_price, discount_price, discount_percent, discount_label, discount_starts_at, discount_ends_at, is_discount_active, product_status, ready_soon, estimated_ready_date, expected_stock_quantity, is_deal_of_day, deal_rank, subscribe_save_enabled, subscribe_save_discount_percent, nutrient_strong, nutrient_good, nutrient_contains, nutrition_notes, nutrition_source, nutrition_verified, usda_fdc_id, serving_size_g';
  final compatibleSelect =
      'id, name, description, price, unit, image_url, is_available, stock_quantity, created_at';

  Future<List<Product>> runQuery(String selectFields) async {
    final response = await supabase
        .from('products')
        .select(selectFields)
        .order('created_at', ascending: false)
        .limit(120)
        .timeout(
      const Duration(seconds: 12),
      onTimeout: () {
        farmDebugLog('Supabase products query timed out after 12s.');
        throw TimeoutException('Supabase products query timed out.');
      },
    );

    return (response as List)
        .map((item) => Product.fromSupabase(Map<String, dynamic>.from(item)))
        .where(isVisibleCustomerProduct)
        .toList();
  }

  try {
    return await runQuery(extendedSelect);
  } catch (error) {
    farmDebugLog(
        'Extended product fetch unavailable, using compatible fetch: $error');
    try {
      return await runQuery(compatibleSelect);
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
      'id, name, description, price, unit, image_url, is_available, stock_quantity, created_at, category, is_organic, is_local, harvest_date, farmer_id, farmer_name, farm_name, parish, approval_status, platform_commission_percent, original_price, discount_price, discount_percent, discount_label, discount_starts_at, discount_ends_at, is_discount_active, product_status, ready_soon, estimated_ready_date, expected_stock_quantity, is_deal_of_day, deal_rank, subscribe_save_enabled, subscribe_save_discount_percent, nutrient_strong, nutrient_good, nutrient_contains, nutrition_notes, nutrition_source, nutrition_verified, usda_fdc_id, serving_size_g';

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
      'id, name, description, price, unit, image_url, is_available, stock_quantity, created_at, category, is_organic, is_local, harvest_date, farmer_id, farmer_name, farm_name, parish, approval_status, platform_commission_percent, original_price, discount_price, discount_percent, discount_label, discount_starts_at, discount_ends_at, is_discount_active, product_status, ready_soon, estimated_ready_date, expected_stock_quantity, is_deal_of_day, deal_rank, subscribe_save_enabled, subscribe_save_discount_percent, nutrient_strong, nutrient_good, nutrient_contains, nutrition_notes, nutrition_source, nutrition_verified, usda_fdc_id, serving_size_g';

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
      'id, name, description, price, unit, image_url, is_available, stock_quantity, created_at, category, is_organic, is_local, harvest_date, farmer_id, farmer_name, farm_name, parish, approval_status, platform_commission_percent, original_price, discount_price, discount_percent, discount_label, discount_starts_at, discount_ends_at, is_discount_active, product_status, ready_soon, estimated_ready_date, expected_stock_quantity, is_deal_of_day, deal_rank, subscribe_save_enabled, subscribe_save_discount_percent, nutrient_strong, nutrient_good, nutrient_contains, nutrition_notes, nutrition_source, nutrition_verified, usda_fdc_id, serving_size_g';

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
  final boundary = captureHpjPrivateOperationBoundary();
  final userId = boundary.userId;

  if (userId == null) return const <FarmOrder>[];

  if (!forceRefresh && _hpjOrdersCacheUserId == userId) {
    final cached = FarmDataCache.orders;
    if (cached != null) return cached;
  }

  final orders = await _fetchOrdersUncached();

  if (!isHpjPrivateOperationBoundaryCurrent(boundary)) {
    farmDebugLog(
      'Discarded stale Orders response after account/session boundary change.',
    );
    return const <FarmOrder>[];
  }

  FarmDataCache.orders = orders;
  _hpjOrdersCacheUserId = userId;
  return orders;
}

Future<List<Product>> fetchBuyAgainProducts({bool forceRefresh = false}) async {
  final boundary = captureHpjPrivateOperationBoundary();
  final userId = boundary.userId;

  if (userId == null) return const <Product>[];

  if (!forceRefresh && _hpjBuyAgainCacheUserId == userId) {
    final cached = FarmDataCache.buyAgain;
    if (cached != null) return cached;
  }

  final products = await _fetchBuyAgainProductsUncached();

  if (!isHpjPrivateOperationBoundaryCurrent(boundary)) {
    farmDebugLog(
      'Discarded stale Buy Again response after account/session boundary change.',
    );
    return const <Product>[];
  }

  FarmDataCache.buyAgain = products;
  _hpjBuyAgainCacheUserId = userId;
  return products;
}

Future<List<Product>> fetchBuyAgainProductsForCustomerUi({
  bool forceRefresh = false,
  Duration timeout = const Duration(seconds: 7),
}) async {
  final boundary = captureHpjPrivateOperationBoundary();

  final cached =
      boundary.userId != null &&
              _hpjBuyAgainCacheUserId == boundary.userId
          ? FarmDataCache.buyAgain
          : null;

  try {
    final products = await fetchBuyAgainProducts(forceRefresh: forceRefresh)
        .timeout(timeout, onTimeout: () => cached ?? const <Product>[]);

    if (!isHpjPrivateOperationBoundaryCurrent(boundary)) {
      return const <Product>[];
    }

    return products;
  } catch (error) {
    farmDebugLog('Buy again load fallback used: $error');

    if (!isHpjPrivateOperationBoundaryCurrent(boundary)) {
      return const <Product>[];
    }

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
      'id, name, description, price, unit, image_url, is_available, stock_quantity, created_at, category, is_organic, is_local, harvest_date, farmer_id, farmer_name, farm_name, parish, approval_status, platform_commission_percent, original_price, discount_price, discount_percent, discount_label, discount_starts_at, discount_ends_at, is_discount_active, product_status, ready_soon, estimated_ready_date, expected_stock_quantity, is_deal_of_day, deal_rank, subscribe_save_enabled, subscribe_save_discount_percent, nutrient_strong, nutrient_good, nutrient_contains, nutrition_notes, nutrition_source, nutrition_verified, usda_fdc_id, serving_size_g';

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
  final purchaseCount = <String, int>{};
  final recencyRank = <String, int>{};

  for (var index = 0; index < itemRows.length; index++) {
    final row = itemRows[index];
    final productId = (row['product_id'] ?? '').toString().trim();
    final productName = (row['product_name'] ?? '').toString().trim();
    final product =
        productsById[productId] ?? productsByName[productName.toLowerCase()];

    if (product == null || !isVisibleCustomerProduct(product)) continue;
    purchaseCount[product.id] = (purchaseCount[product.id] ?? 0) + 1;
    recencyRank.putIfAbsent(product.id, () => index);
    if (!seen.add(product.id)) continue;
    result.add(product);
  }

  result.sort((a, b) {
    final countCompare =
        (purchaseCount[b.id] ?? 0).compareTo(purchaseCount[a.id] ?? 0);
    if (countCompare != 0) return countCompare;
    final recencyCompare =
        (recencyRank[a.id] ?? 999999).compareTo(recencyRank[b.id] ?? 999999);
    if (recencyCompare != 0) return recencyCompare;
    if (a.canAddToCart != b.canAddToCart) return a.canAddToCart ? -1 : 1;
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });

  return result.take(10).toList();
}

String? notificationOrderShortId(FarmNotification notification) {
  final text = '${notification.title} ${notification.message}';
  final match = RegExp(r'#([A-Za-z0-9]+)').firstMatch(text);
  return match?.group(1)?.trim().toUpperCase();
}

// Sends an already-saved private notification through the secured Supabase
// Edge Function. Firebase service-account credentials stay on the server and
// are never bundled into the HPJ app.
Future<void> _dispatchStoredPushNotification({
  String? notificationId,
  String? dedupeKey,
}) async {
  final cleanId = notificationId?.trim() ?? '';
  final cleanDedupeKey = dedupeKey?.trim() ?? '';
  if ((cleanId.isEmpty && cleanDedupeKey.isEmpty) ||
      supabase.auth.currentUser == null) {
    return;
  }

  final accessToken = supabase.auth.currentSession?.accessToken.trim() ?? '';
  if (accessToken.isEmpty) return;

  try {
    final response = await supabase.functions.invoke(
      'send-push-notification',
      headers: <String, String>{
        'Authorization': 'Bearer $accessToken',
      },
      body: <String, dynamic>{
        if (cleanId.isNotEmpty) 'notification_id': cleanId,
        if (cleanDedupeKey.isNotEmpty) 'dedupe_key': cleanDedupeKey,
      },
    );

    if (response.status < 200 || response.status >= 300) {
      farmDebugLog(
        'Push dispatch returned HTTP ${response.status} '
        'for ${cleanId.isNotEmpty ? cleanId : cleanDedupeKey}.',
      );
    }
  } catch (error, stackTrace) {
    // Saving the in-app notification is more important than the remote push.
    // A temporary FCM/Edge Function outage must never break checkout, chat,
    // procurement, farmer or wholesale workflows.
    farmDebugLog('Remote push dispatch skipped: $error');
    farmDebugLog('$stackTrace');
  }
}

Future<void> dispatchStoredPushNotification(String notificationId) {
  return _dispatchStoredPushNotification(notificationId: notificationId);
}

Future<void> dispatchStoredPushNotificationByDedupeKey(String dedupeKey) {
  return _dispatchStoredPushNotification(dedupeKey: dedupeKey);
}


String hpjCanonicalNotificationActionType(String? value) {
  final clean = (value ?? '').trim().toLowerCase();

  switch (clean) {
    case 'customer_order':
      return 'order';
    case 'farmer_payout':
      return 'farmer_payment';
    case 'wholesale_orders':
    case 'wholesale_request':
      return 'wholesale_order';
    case 'customer_care':
    case 'customer_care_chat':
    case 'chat':
      return 'support_chat';
    case 'staff_support_chat':
      return 'admin_support_chat';
    default:
      return clean;
  }
}

bool hpjNotificationActionBenefitsFromId(String actionType) {
  switch (hpjCanonicalNotificationActionType(actionType)) {
    case 'order':
    case 'support_chat':
    case 'admin_support_chat':
    case 'customer_product':
    case 'wholesale_product':
    case 'farmer_demand':
    case 'farmer_collection':
    case 'farmer_supply':
    case 'farmer_payment':
    case 'wholesale_plan':
    case 'wholesale_order':
    case 'admin_customer_order':
    case 'admin_farmer_application':
    case 'admin_product_approval':
    case 'admin_review':
    case 'admin_inventory':
    case 'admin_wholesale_demand':
    case 'admin_wholesale_payment':
    case 'admin_wholesale_application':
    case 'admin_wholesale_order':
      return true;
    default:
      return false;
  }
}

String _hpjNotificationDedupeSlug(String value) {
  final slug = value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');

  if (slug.isEmpty) return 'update';
  return slug.length <= 50 ? slug : slug.substring(0, 50);
}

({String actionType, String actionId}) hpjResolveNotificationAction({
  required String type,
  String? orderId,
  String? actionType,
  String? actionId,
}) {
  final cleanType = type.trim().toLowerCase();
  final cleanOrderId = (orderId ?? '').trim();
  var resolvedType = hpjCanonicalNotificationActionType(actionType);
  var resolvedId = (actionId ?? '').trim();

  if (resolvedType.isEmpty && cleanOrderId.isNotEmpty) {
    resolvedType = 'order';
    resolvedId = cleanOrderId;
  }

  if (resolvedType.isEmpty && resolvedId.isNotEmpty) {
    switch (cleanType) {
      case 'support':
        resolvedType = 'support_chat';
        break;
      case 'product_ready':
      case 'watch':
      case 'price_drop':
        resolvedType = 'customer_product';
        break;
      case 'farmer_demand':
      case 'farmer_collection':
      case 'farmer_supply':
      case 'farmer_payment':
      case 'farmer_payout':
        resolvedType = hpjCanonicalNotificationActionType(cleanType);
        break;
      case 'wholesale_plan':
      case 'wholesale_order':
      case 'wholesale_orders':
      case 'wholesale_account':
        resolvedType = hpjCanonicalNotificationActionType(cleanType);
        break;
    }
  }

  if (resolvedId.isEmpty &&
      cleanOrderId.isNotEmpty &&
      const <String>{
        'order',
        'admin_customer_order',
      }.contains(resolvedType)) {
    resolvedId = cleanOrderId;
  }

  return (
    actionType: resolvedType,
    actionId: resolvedId,
  );
}

Future<void> createFarmNotification({
  required String title,
  required String message,
  String type = 'order',
  String? userEmail,
  String? userId,
  String? orderId,
  String? actionType,
  String? actionId,
  String? dedupeKey,
}) async {
  final currentUser = supabase.auth.currentUser;
  final explicitUserEmail = userEmail != null && userEmail.trim().isNotEmpty;
  final targetUserId =
      (userId ?? (explicitUserEmail ? null : currentUser?.id))?.trim();
  final targetEmail =
      (userEmail ?? currentUser?.email)?.trim().toLowerCase();
  final cleanType = type.trim().toLowerCase().isEmpty
      ? 'notification'
      : type.trim().toLowerCase();
  final cleanOrderId = orderId?.trim();

  final route = hpjResolveNotificationAction(
    type: cleanType,
    orderId: cleanOrderId,
    actionType: actionType,
    actionId: actionId,
  );

  final resolvedActionType = route.actionType;
  final resolvedActionId = route.actionId;
  final requestedDedupeKey = dedupeKey?.trim() ?? '';

  if (resolvedActionType.isNotEmpty &&
      hpjNotificationActionBenefitsFromId(resolvedActionType) &&
      resolvedActionId.isEmpty) {
    farmDebugLog(
      'Notification route metadata is incomplete: '
      '$resolvedActionType has no action_id for "$title".',
    );
  }

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

  // Every modern notification gets a private dispatch key. We do not request
  // the inserted row back from PostgREST because the sender often cannot SELECT
  // a notification targeted to another user under RLS. The Edge Function can
  // securely resolve this key with the service role and verify created_by.
  final dispatchDedupeKey = requestedDedupeKey.isNotEmpty
      ? requestedDedupeKey
      : 'push:${currentUser?.id ?? 'anonymous'}:'
          '${DateTime.now().microsecondsSinceEpoch}:'
          '$cleanType:'
          '${resolvedActionType.isEmpty ? 'general' : resolvedActionType}:'
          '${resolvedActionId.isEmpty ? title.hashCode.abs() : resolvedActionId}';

  final notificationPayload = <String, dynamic>{
    'user_id': targetUserId,
    'user_email': targetEmail,
    'title': title,
    'message': message,
    'type': cleanType,
    'is_read': false,
    if (cleanOrderId != null && cleanOrderId.isNotEmpty)
      'order_id': cleanOrderId,
    if (resolvedActionType.isNotEmpty) 'action_type': resolvedActionType,
    if (resolvedActionId.isNotEmpty) 'action_id': resolvedActionId,
    'dedupe_key': dispatchDedupeKey,
  };

  if (await farmNotificationAlreadyExists(
    title: title,
    type: cleanType,
    userId: targetUserId,
    userEmail: targetEmail,
    orderId: cleanOrderId,
    dedupeKey: requestedDedupeKey.isEmpty ? null : requestedDedupeKey,
  )) {
    // A prior attempt may have saved the notification while FCM was
    // temporarily unavailable. The Edge Function is idempotent and will only
    // send it if push_sent_at is still empty.
    if (requestedDedupeKey.isNotEmpty) {
      await dispatchStoredPushNotificationByDedupeKey(requestedDedupeKey);
    }

    showBrowserNotificationForTarget(
      title: title,
      message: message,
      type: cleanType,
      userId: targetUserId,
      userEmail: targetEmail,
      orderId: cleanOrderId,
    );
    return;
  }

  try {
    await supabase.from('notifications').insert(notificationPayload);

    // Notification data changed — force the inbox to reload next time.
    FarmDataCache.notifications = null;

    await dispatchStoredPushNotificationByDedupeKey(dispatchDedupeKey);

    showBrowserNotificationForTarget(
      title: title,
      message: message,
      type: cleanType,
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

    // Compatibility fallback for older notifications tables. Remote Android
    // push requires migration 009, but the legacy in-app notification remains
    // available so older test databases do not break the workflow.
    try {
      if (targetEmail == null || targetEmail.isEmpty) return;
      final legacyPayload = Map<String, dynamic>.from(notificationPayload)
        ..remove('user_id')
        ..remove('order_id')
        ..remove('action_type')
        ..remove('action_id')
        ..remove('dedupe_key');
      await supabase.from('notifications').insert(legacyPayload);

      FarmDataCache.notifications = null;

      showBrowserNotificationForTarget(
        title: title,
        message: message,
        type: cleanType,
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
      actionType: 'order',
      actionId: orderId,
      dedupeKey:
          'customer-order:$orderId:${type.trim().toLowerCase()}:${_hpjNotificationDedupeSlug(title)}',
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
  final boundary = captureHpjPrivateOperationBoundary();
  final userId = boundary.userId;

  if (userId == null) return const <FarmNotification>[];

  if (!forceRefresh && _hpjNotificationsCacheUserId == userId) {
    final cached = FarmDataCache.notifications;
    if (cached != null) return cached;
  }

  final notifications = await _fetchFarmNotificationsUncached();

  if (!isHpjPrivateOperationBoundaryCurrent(boundary)) {
    farmDebugLog(
      'Discarded stale Notifications response after account/session boundary change.',
    );
    return const <FarmNotification>[];
  }

  FarmDataCache.notifications = notifications;
  _hpjNotificationsCacheUserId = userId;
  return notifications;
}

Future<int> fetchUnreadNotificationCount() async {
  final boundary = captureHpjPrivateOperationBoundary();
  final user = supabase.auth.currentUser;

  if (user == null || boundary.userId == null) return 0;

  try {
    final response = await supabase
        .from('notifications')
        .select('id')
        .eq('user_id', user.id)
        .eq('is_read', false);

    if (!isHpjPrivateOperationBoundaryCurrent(boundary)) {
      return 0;
    }

    return (response as List).length;
  } catch (userIdError) {
    final userEmail = (user.email ?? '').trim().toLowerCase();

    if (userEmail.isEmpty) return 0;

    try {
      final response = await supabase
          .from('notifications')
          .select('id')
          .eq('user_email', userEmail)
          .eq('is_read', false);

      if (!isHpjPrivateOperationBoundaryCurrent(boundary)) {
        return 0;
      }

      return (response as List).length;
    } catch (emailError) {
      farmDebugLog(
        'Unread notification count skipped: $emailError',
      );

      return 0;
    }
  }
}

Future<void> markNotificationsRead() async {
  final user = supabase.auth.currentUser;
  if (user == null) return;

  try {
    await supabase
        .from('notifications')
        .update({'is_read': true}).eq('user_id', user.id);

    // Force notification screen to reload fresh data.
    FarmDataCache.notifications = null;
  } catch (userIdError) {
    try {
      final userEmail = (user.email ?? '').trim().toLowerCase();

      if (userEmail.isEmpty) return;

      await supabase
          .from('notifications')
          .update({'is_read': true}).eq('user_email', userEmail);

      // Force notification screen to reload fresh data.
      FarmDataCache.notifications = null;
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
        actionType: 'customer_product',
        actionId: product.id,
        dedupeKey: 'product-ready:${product.id}:'
            '${subId.isNotEmpty ? subId : (userId ?? email ?? 'customer')}',
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
      'id, order_status, fulfillment_type, subtotal, delivery_fee, discount_amount, total, payment_status, payment_method, delivery_address, delivery_zone, scheduled_date, scheduled_time, notes, created_at, order_items(product_id, product_name, quantity, unit_price, line_total)';

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
      actionType: 'admin_customer_order',
      actionId: orderId,
      dedupeKey: 'admin-order-status:$orderId:${status.trim().toLowerCase()}',
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
      'id, name, description, price, unit, image_url, is_available, stock_quantity, created_at, category, is_organic, is_local, harvest_date, farmer_id, farmer_name, farm_name, parish, approval_status, platform_commission_percent, original_price, discount_price, discount_percent, discount_label, discount_starts_at, discount_ends_at, is_discount_active, product_status, ready_soon, estimated_ready_date, expected_stock_quantity, is_deal_of_day, deal_rank, subscribe_save_enabled, subscribe_save_discount_percent, nutrient_strong, nutrient_good, nutrient_contains, nutrition_notes, nutrition_source, nutrition_verified, usda_fdc_id, serving_size_g';
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

Future<void> markProductHarvestedNow(
  String productId,
) async {
  await requireAdminAccess();

  final cleanId = productId.trim();
  if (cleanId.isEmpty) return;

  final now = DateTime.now().toUtc();

  await supabase.from('products').update({
    'harvested_at': now.toIso8601String(),
    'harvest_date': now.toIso8601String().split('T').first,
  }).eq('id', cleanId);

  FarmDataCache.clearProducts();
}

Future<void> updateProductNutritionTags({
  required String productId,
  List<String> nutrientStrong = const <String>[],
  List<String> nutrientGood = const <String>[],
  List<String> nutrientContains = const <String>[],
  String? nutritionNotes,
  String? nutritionSource,
  bool nutritionVerified = false,
  String? usdaFdcId,
  double servingSizeG = 100,
}) async {
  await requireAdminAccess();

  List<String> cleanList(List<String> values) {
    return values
        .map((value) =>
            value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' '))
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  final cleanProductId = productId.trim();
  if (cleanProductId.isEmpty) {
    throw Exception('Missing product ID.');
  }

  await supabase.from('products').update({
    'nutrient_strong': cleanList(nutrientStrong),
    'nutrient_good': cleanList(nutrientGood),
    'nutrient_contains': cleanList(nutrientContains),
    'nutrition_notes': nutritionNotes?.trim(),
    'nutrition_source': nutritionSource?.trim(),
    'nutrition_verified': nutritionVerified,
    'usda_fdc_id': usdaFdcId?.trim(),
    'serving_size_g': servingSizeG <= 0 ? 100 : servingSizeG,
  }).eq('id', cleanProductId);

  FarmDataCache.clearProducts();
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

List<String> _cleanProductNutrientValues(Iterable<String> values) {
  final cleaned = values
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toSet()
      .toList();
  cleaned.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return cleaned;
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
  List<String> nutrientStrong = const <String>[],
  List<String> nutrientGood = const <String>[],
  List<String> nutrientContains = const <String>[],
  bool nutritionVerified = false,
  String? nutritionNotes,
  String? nutritionSource,
  String? usdaFdcId,
  double servingSizeG = 100,
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
    'nutrient_strong': _cleanProductNutrientValues(nutrientStrong),
    'nutrient_good': _cleanProductNutrientValues(nutrientGood),
    'nutrient_contains': _cleanProductNutrientValues(nutrientContains),
    'nutrition_verified': nutritionVerified,
    'nutrition_notes': nutritionNotes?.trim(),
    'nutrition_source': nutritionSource?.trim(),
    'usda_fdc_id': usdaFdcId?.trim(),
    'serving_size_g': servingSizeG <= 0 ? 100 : servingSizeG,
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

Future<String?> _resolveFarmerReadScope({
  String? farmerId,
  bool allowAdminAll = false,
}) async {
  final requestedFarmerId = farmerId?.trim() ?? '';

  // An administrator may explicitly request the all-farmer view only from
  // functions that opt in with allowAdminAll. Farmers never receive an
  // unfiltered financial/operational query from the client.
  if (allowAdminAll && requestedFarmerId.isEmpty) {
    final isAdmin = await isCurrentUserAdminFromDatabase();
    if (isAdmin) return null;
  }

  final currentFarmer = await fetchCurrentFarmerProfile();
  final currentFarmerId = currentFarmer?.id.trim() ?? '';

  if (currentFarmerId.isNotEmpty &&
      (requestedFarmerId.isEmpty || requestedFarmerId == currentFarmerId)) {
    return currentFarmerId;
  }

  final isAdmin = await isCurrentUserAdminFromDatabase();
  if (isAdmin && requestedFarmerId.isNotEmpty) {
    return requestedFarmerId;
  }

  throw Exception('You do not have permission to view this farmer data.');
}

Future<List<FarmerOrderSummary>> fetchFarmerOrderSummaries(
    String farmerId) async {
  final cleanFarmerId = farmerId.trim();
  if (cleanFarmerId.isEmpty) return [];

  try {
    final scopedFarmerId = await _resolveFarmerReadScope(
      farmerId: cleanFarmerId,
    );
    if (scopedFarmerId == null || scopedFarmerId.isEmpty) return [];

    final response = await supabase
        .from('order_items')
        .select(
            'order_id, product_name, quantity, line_total, farmer_earning_amount, farmer_id')
        .eq('farmer_id', scopedFarmerId)
        .order('is_read', ascending: true)
        .order('created_at', ascending: false)
        .limit(200);
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

  // Farmer profile tables created during earlier HPJ phases may not yet have
  // every optional field. Read the richest shape first, then gracefully fall
  // back to the core profile instead of treating a missing optional column as
  // "no farmer profile".
  const fieldSets = <String>[
    'id, user_id, email, farm_name, farmer_name, phone, parish, address, bio, verification_status, payout_method, payout_details, created_at',
    'id, user_id, email, farm_name, farmer_name, phone, parish, address, bio, verification_status, created_at',
    'id, user_id, farm_name, farmer_name, phone, parish, verification_status, created_at',
    'id, user_id, farm_name, farmer_name, phone, parish',
  ];

  Object? lastError;

  for (final fields in fieldSets) {
    try {
      final response = await supabase
          .from('farmer_profiles')
          .select(fields)
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) return null;
      return FarmerProfile.fromSupabase(
        Map<String, dynamic>.from(response as Map),
      );
    } catch (error) {
      lastError = error;
    }
  }

  farmDebugLog(
      'Farmer profile unavailable after compatibility reads: $lastError');
  return null;
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

  if (user == null) {
    throw Exception(
      'Please sign in before submitting a farmer application.',
    );
  }

  final existing = await fetchCurrentFarmerProfile();
  final settings = await fetchMarketplaceProgramSettings();

  // Closing applications blocks only brand-new applications. Existing farmer
  // profiles can still be updated.
  if (existing == null && !settings.farmerApplicationsEnabled) {
    throw Exception(
      'Farmer applications are temporarily paused.',
    );
  }

  final cleanFarmName = farmName.trim();
  final cleanFarmerName = farmerName.trim();
  final cleanPhone = phone.trim();

  if (cleanFarmName.isEmpty ||
      cleanFarmerName.isEmpty ||
      cleanPhone.isEmpty ||
      parish.trim().isEmpty) {
    throw Exception(
      'Farm name, farmer name, phone, and parish are required.',
    );
  }

  final cleanParish = requireJamaicaParish(
    parish,
    fieldLabel: 'Farmer parish',
  );

  final params = <String, dynamic>{
    'p_farm_name': cleanFarmName,
    'p_farmer_name': cleanFarmerName,
    'p_phone': cleanPhone,
    'p_parish': cleanParish,
    'p_address': address.trim(),
    'p_bio': bio.trim(),
    'p_payout_method': payoutMethod.trim(),
    'p_payout_details': payoutDetails.trim(),
  };

  try {
    // Server-authoritative save. The migration supplied with this release
    // creates submit_farmer_application() as a SECURITY DEFINER function so a
    // legitimate signed-in user is not blocked by inconsistent legacy RLS
    // policies or optional-column drift.
    await supabase.rpc(
      'submit_farmer_application',
      params: params,
    );
  } catch (rpcError) {
    final text = rpcError.toString().toLowerCase();
    final rpcMissing = text.contains('pgrst202') ||
        text.contains('42883') ||
        text.contains('function') && text.contains('does not exist');

    if (!rpcMissing) {
      farmDebugLog('Farmer application RPC failed: $rpcError');
      rethrow;
    }

    // Compatibility fallback for a build launched before the migration has
    // been applied. Save only the core fields first; optional fields are then
    // best-effort so an older table cannot reject the whole application just
    // because payout/address columns are absent.
    farmDebugLog(
      'Farmer application RPC not installed yet; using compatibility save.',
    );

    final corePayload = <String, dynamic>{
      'user_id': user.id,
      'farm_name': cleanFarmName,
      'farmer_name': cleanFarmerName,
      'phone': cleanPhone,
      'parish': cleanParish,
    };

    if (existing == null || existing.id.isEmpty) {
      await supabase.from('farmer_profiles').insert(corePayload);
    } else {
      await supabase
          .from('farmer_profiles')
          .update(corePayload)
          .eq('id', existing.id);
    }

    final optionalPayload = <String, dynamic>{
      'email': user.email,
      'address': address.trim(),
      'bio': bio.trim(),
      'payout_method': payoutMethod.trim(),
      'payout_details': payoutDetails.trim(),
      if (existing == null || existing.id.isEmpty)
        'verification_status': 'pending',
    };

    try {
      if (existing == null || existing.id.isEmpty) {
        await supabase
            .from('farmer_profiles')
            .update(optionalPayload)
            .eq('user_id', user.id);
      } else {
        await supabase
            .from('farmer_profiles')
            .update(optionalPayload)
            .eq('id', existing.id);
      }
    } catch (optionalError) {
      farmDebugLog(
        'Farmer optional profile fields were skipped safely: $optionalError',
      );
    }
  }

  // Notification delivery is intentionally non-blocking. A successfully saved
  // farmer application must never be reported to the user as failed just
  // because an admin notification could not be created.
  final savedFarmerProfile = await fetchCurrentFarmerProfile();

  await createAdminNotification(
    title:
        existing == null ? 'New farmer application' : 'Farmer profile updated',
    message: existing == null
        ? '$cleanFarmName submitted a farmer partner application.'
        : '$cleanFarmName updated their farmer profile.',
    type: 'farmer',
    actionType: 'admin_farmer_application',
    actionId: savedFarmerProfile?.id,
    dedupeKey: savedFarmerProfile?.id == null
        ? null
        : 'admin-farmer-profile:${savedFarmerProfile!.id}:'
            '${existing == null ? 'new' : 'updated'}',
  );
}

Future<void> updateFarmerVerification(
  String farmerId,
  String status,
) async {
  await requireAdminAccess();

  await supabase.from('farmer_profiles').update({
    'verification_status': status,
  }).eq('id', farmerId);
}
// =====================================================
// HPJ FARMER SUPPLY NETWORK
// =====================================================

const String _farmerSupplyForecastFields =
    'id, farmer_id, crop_name, category, '
    'quantity_growing, expected_quantity, '
    'harvested_quantity, hpj_confirmed_quantity, '
    'unit, expected_harvest_date, harvested_at, '
    'status, notes, created_at, updated_at';

const Set<String> _farmerEditableSupplyStatuses = {
  'planning',
  'growing',
  'expected',
  'harvest_ready',
  'harvested',
  'cancelled',
};
// =====================================================
// FETCH SUPPLY FOR ONE FARMER
// =====================================================

Future<List<FarmerSupplyForecast>> fetchFarmerSupplyForecasts(
  String farmerId,
) async {
  final cleanFarmerId = farmerId.trim();

  if (cleanFarmerId.isEmpty) {
    return const <FarmerSupplyForecast>[];
  }

  try {
    final scopedFarmerId = await _resolveFarmerReadScope(
      farmerId: cleanFarmerId,
    );
    if (scopedFarmerId == null || scopedFarmerId.isEmpty) {
      return const <FarmerSupplyForecast>[];
    }

    final response = await supabase
        .from('farmer_supply_forecasts')
        .select(_farmerSupplyForecastFields)
        .eq('farmer_id', scopedFarmerId)
        .order(
          'created_at',
          ascending: false,
        );

    return (response as List)
        .map(
          (item) => FarmerSupplyForecast.fromSupabase(
            Map<String, dynamic>.from(
              item as Map,
            ),
          ),
        )
        .toList();
  } catch (error) {
    farmDebugLog(
      'Farmer supply forecasts unavailable: $error',
    );

    return const <FarmerSupplyForecast>[];
  }
}

// =====================================================
// FETCH CURRENT SIGNED-IN FARMER SUPPLY
// =====================================================

Future<List<FarmerSupplyForecast>> fetchCurrentFarmerSupplyForecasts() async {
  final farmer = await fetchCurrentFarmerProfile();

  if (farmer == null || farmer.id.trim().isEmpty) {
    return const <FarmerSupplyForecast>[];
  }

  return fetchFarmerSupplyForecasts(
    farmer.id,
  );
}
// =====================================================
// UPDATE FARMER SUPPLY FORECAST
// =====================================================

Future<FarmerSupplyForecast> updateFarmerSupplyForecast({
  required String forecastId,
  String? cropName,
  String? category,
  double? quantityGrowing,
  double? expectedQuantity,
  double? harvestedQuantity,
  String? unit,
  DateTime? expectedHarvestDate,
  DateTime? harvestedAt,
  String? status,
  String? notes,
}) async {
  final operationBoundary =
      captureHpjPrivateOperationBoundary();

  final farmer = await fetchCurrentFarmerProfile();

  if (!isHpjPrivateOperationBoundaryCurrent(operationBoundary)) {
    throw const HpjPrivateMutationInterruptedException();
  }

  if (farmer == null) {
    throw Exception(
      'Farmer profile not found.',
    );
  }

  if (!farmer.isApproved) {
    throw Exception(
      'Your farmer profile must be approved.',
    );
  }

  final cleanForecastId = forecastId.trim();

  if (cleanForecastId.isEmpty) {
    throw Exception(
      'Supply report ID is required.',
    );
  }

  if (quantityGrowing != null && quantityGrowing < 0) {
    throw Exception(
      'Quantity growing cannot be negative.',
    );
  }

  if (expectedQuantity != null && expectedQuantity < 0) {
    throw Exception(
      'Expected quantity cannot be negative.',
    );
  }

  if (harvestedQuantity != null && harvestedQuantity < 0) {
    throw Exception(
      'Harvested quantity cannot be negative.',
    );
  }

  final patch = <String, dynamic>{};

  if (cropName != null) {
    final cleanCrop = cropName.trim();

    if (cleanCrop.isEmpty) {
      throw Exception(
        'Crop name cannot be empty.',
      );
    }

    patch['crop_name'] = cleanCrop;
  }

  if (category != null) {
    patch['category'] =
        category.trim().isEmpty ? null : category.trim();
  }

  if (quantityGrowing != null) {
    patch['quantity_growing'] = quantityGrowing;
  }

  if (expectedQuantity != null) {
    patch['expected_quantity'] = expectedQuantity;
  }

  if (harvestedQuantity != null) {
    patch['harvested_quantity'] = harvestedQuantity;
  }

  if (unit != null) {
    final cleanUnit = unit.trim();

    if (cleanUnit.isEmpty) {
      throw Exception(
        'Unit cannot be empty.',
      );
    }

    patch['unit'] = cleanUnit;
  }

  if (expectedHarvestDate != null) {
    patch['expected_harvest_date'] =
        expectedHarvestDate.toIso8601String().split('T').first;
  }

  if (notes != null) {
    patch['notes'] =
        notes.trim().isEmpty ? null : notes.trim();
  }

  if (status != null) {
    final cleanStatus = status.trim().toLowerCase();

    if (!_farmerEditableSupplyStatuses.contains(cleanStatus)) {
      throw Exception(
        'Farmers cannot use this supply status.',
      );
    }

    patch['status'] = cleanStatus;

    if (cleanStatus == 'harvested') {
      patch['harvested_at'] =
          (harvestedAt ?? DateTime.now())
              .toUtc()
              .toIso8601String();
    }
  } else if (harvestedAt != null) {
    patch['harvested_at'] =
        harvestedAt.toUtc().toIso8601String();
  }

  if (patch.isEmpty) {
    throw Exception(
      'No supply changes were provided.',
    );
  }

  final mutationLease = acquireHpjPrivateMutation(
    'farmer-supply-update:$cleanForecastId',
    expectedBoundary: operationBoundary,
  );

  try {
    mutationLease.ensureCurrent();

    final response = await supabase.rpc(
      'farmer_update_supply_forecast_secure',
      params: {
        'p_supply_id': cleanForecastId,
        'p_patch': patch,
      },
    );

    mutationLease.ensureCurrent();

    if (response is! Map) {
      throw Exception(
        'Supply report could not be updated.',
      );
    }

    return FarmerSupplyForecast.fromSupabase(
      Map<String, dynamic>.from(response),
    );
  } finally {
    mutationLease.release();
  }
}
// =====================================================
// CANCEL FARMER SUPPLY FORECAST
// =====================================================

Future<FarmerSupplyForecast> cancelFarmerSupplyForecast(
  String forecastId,
) {
  return updateFarmerSupplyForecast(
    forecastId: forecastId,
    status: 'cancelled',
  );
}
// =====================================================
// ADMIN — ALL FARMER SUPPLY FORECASTS
// Used for supply vs demand matching
// =====================================================

Future<List<FarmerSupplyForecast>> fetchAdminFarmerSupplyForecasts() async {
  await requireAdminAccess();

  try {
    final response = await supabase
        .from('farmer_supply_forecasts')
        .select(_farmerSupplyForecastFields)
        .not(
          'status',
          'in',
          '(completed,cancelled)',
        )
        .order(
          'expected_harvest_date',
          ascending: true,
        )
        .limit(500);

    return (response as List)
        .map(
          (item) => FarmerSupplyForecast.fromSupabase(
            Map<String, dynamic>.from(
              item as Map,
            ),
          ),
        )
        .toList();
  } catch (error) {
    farmDebugLog(
      'Admin farmer supply load failed: $error',
    );

    rethrow;
  }
}

// =====================================================
// ADMIN — VERIFY / CONFIRM FARMER SUPPLY
//
// Farmer reports remain planning signals until HPJ verifies
// a quantity. Only the confirmed quantity can be reserved
// against wholesale procurement requirements.
// =====================================================

Future<FarmerSupplyForecast> adminConfirmFarmerSupplyForecast({
  required FarmerSupplyForecast supply,
  required double confirmedQuantity,
}) async {
  await requireAdminAccess();

  if (confirmedQuantity <= 0 ||
      confirmedQuantity.isNaN ||
      confirmedQuantity.isInfinite) {
    throw Exception(
      'Enter a valid HPJ-confirmed quantity.',
    );
  }

  final maximumReported = <double>[
    supply.harvestedQuantity ?? 0,
    supply.expectedQuantity ?? 0,
    supply.quantityGrowing ?? 0,
  ].fold<double>(0, (best, value) => value > best ? value : best);

  if (maximumReported > 0 && confirmedQuantity > maximumReported) {
    throw Exception(
      'Confirmed quantity cannot be greater than the farmer-reported quantity.',
    );
  }

  final response = await supabase.rpc(
    'admin_confirm_farmer_supply_forecast',
    params: {
      'p_supply_id': supply.id,
      'p_confirmed_quantity': confirmedQuantity,
    },
  );

  if (response is! Map) {
    throw Exception(
      'Farmer supply could not be confirmed. Refresh and try again.',
    );
  }

  return FarmerSupplyForecast.fromSupabase(
    Map<String, dynamic>.from(response),
  );
}

// =====================================================
// CREATE FARMER SUPPLY FORECAST
// =====================================================

Future<FarmerSupplyForecast> createFarmerSupplyForecast({
  required String cropName,
  String? category,
  double? quantityGrowing,
  double? expectedQuantity,
  String unit = 'lb',
  DateTime? expectedHarvestDate,
  String status = 'growing',
  String? notes,
}) async {
  final operationBoundary =
      captureHpjPrivateOperationBoundary();

  final farmer = await fetchCurrentFarmerProfile();

  if (!isHpjPrivateOperationBoundaryCurrent(operationBoundary)) {
    throw const HpjPrivateMutationInterruptedException();
  }

  if (farmer == null) {
    throw Exception(
      'A farmer profile is required before reporting supply.',
    );
  }

  if (!farmer.isApproved) {
    throw Exception(
      'Your farmer profile must be approved before reporting supply.',
    );
  }

  final cleanCropName = cropName.trim();
  final cleanUnit = unit.trim();
  final cleanStatus = status.trim().toLowerCase();

  if (cleanCropName.isEmpty) {
    throw Exception('Crop name is required.');
  }

  if (cleanUnit.isEmpty) {
    throw Exception('Unit is required.');
  }

  if (!_farmerEditableSupplyStatuses.contains(cleanStatus)) {
    throw Exception('Invalid farmer supply status.');
  }

  if (quantityGrowing != null && quantityGrowing < 0) {
    throw Exception('Quantity growing cannot be negative.');
  }

  if (expectedQuantity != null && expectedQuantity < 0) {
    throw Exception('Expected quantity cannot be negative.');
  }

  final mutationLease = acquireHpjPrivateMutation(
    'farmer-supply:${farmer.id}:${cleanCropName.toLowerCase()}',
    expectedBoundary: operationBoundary,
  );

  try {
    mutationLease.ensureCurrent();

    final idempotencyKey =
        newHpjIdempotencyKey('farmer-supply-create');

    final response = await supabase.rpc(
      'farmer_create_supply_forecast_secure_idempotent',
      params: {
        'p_crop_name': cleanCropName,
        'p_category':
            category == null || category.trim().isEmpty
                ? null
                : category.trim(),
        'p_quantity_growing': quantityGrowing,
        'p_expected_quantity': expectedQuantity,
        'p_unit': cleanUnit,
        'p_expected_harvest_date':
            expectedHarvestDate == null
                ? null
                : expectedHarvestDate
                    .toIso8601String()
                    .split('T')
                    .first,
        'p_status': cleanStatus,
        'p_notes':
            notes == null || notes.trim().isEmpty
                ? null
                : notes.trim(),
        'p_idempotency_key': idempotencyKey,
      },
    );

    mutationLease.ensureCurrent();

    if (response is! Map) {
      throw Exception(
        'Farmer supply report could not be created.',
      );
    }

    return FarmerSupplyForecast.fromSupabase(
      Map<String, dynamic>.from(response),
    );
  } finally {
    mutationLease.release();
  }
}
Future<List<Product>> fetchFarmerProducts(String farmerId) async {
  if (farmerId.isEmpty) return [];
  try {
    final response = await supabase
        .from('products')
        .select(
            'id, name, description, price, unit, image_url, is_available, stock_quantity, created_at, category, is_organic, is_local, harvest_date, farmer_id, farmer_name, farm_name, parish, approval_status, platform_commission_percent, original_price, discount_price, discount_percent, discount_label, discount_starts_at, discount_ends_at, is_discount_active, product_status, ready_soon, estimated_ready_date, expected_stock_quantity, is_deal_of_day, deal_rank, subscribe_save_enabled, subscribe_save_discount_percent, nutrient_strong, nutrient_good, nutrient_contains, nutrition_notes, nutrition_source, nutrition_verified, usda_fdc_id, serving_size_g')
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
    'nutrient_strong': const <String>[],
    'nutrient_good': const <String>[],
    'nutrient_contains': const <String>[],
    'nutrition_verified': false,
    'serving_size_g': 100,
  };

  String submittedProductId = '';

  try {
    final inserted = await supabase
        .from('products')
        .insert(marketplacePayload)
        .select('id')
        .maybeSingle();

    submittedProductId =
        inserted == null ? '' : (inserted['id'] ?? '').toString().trim();
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

    // Do not call the admin-only createProduct() compatibility helper here.
    // A normal approved farmer must still be able to submit a pending product
    // when optional/newer marketplace columns are not yet available.
    final compatibleFarmerPayload = <String, dynamic>{
      'name': cleanName,
      'price': price,
      'stock_quantity': stockQuantity,
      'is_available': false,
      'category': normalizeProductCategory(category),
      'is_organic': isOrganic,
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
    };

    try {
      final inserted = await supabase
          .from('products')
          .insert(compatibleFarmerPayload)
          .select('id')
          .maybeSingle();

      submittedProductId =
          inserted == null ? '' : (inserted['id'] ?? '').toString().trim();
    } catch (fallbackError) {
      final fallbackText = fallbackError.toString().toLowerCase();
      final missingOptionalFarmerColumns = fallbackText.contains('column') ||
          fallbackText.contains('schema cache') ||
          fallbackText.contains('pgrst204');

      if (!missingOptionalFarmerColumns) {
        farmDebugLog(
          'Compatible farmer product insert failed: $fallbackError',
        );
        throw Exception(
          'Could not submit product. Please make sure your farmer profile is approved and linked to this account.',
        );
      }

      // Final compatibility shape keeps the two safety-critical fields:
      // farmer_id for ownership and approval_status=pending so a farmer cannot
      // accidentally publish directly to the customer marketplace.
      final minimalFarmerPayload = <String, dynamic>{
        'name': cleanName,
        'price': price,
        'stock_quantity': stockQuantity,
        'is_available': false,
        'category': normalizeProductCategory(category),
        'is_organic': isOrganic,
        'harvest_date': todayIsoDate(),
        'description':
            description?.trim().isEmpty == true ? null : description?.trim(),
        'unit': unit?.trim().isEmpty == true ? null : unit?.trim(),
        'image_url': imageUrl?.trim().isEmpty == true ? null : imageUrl?.trim(),
        'farmer_id': farmer.id,
        'approval_status': 'pending',
      };

      try {
        final inserted = await supabase
            .from('products')
            .insert(minimalFarmerPayload)
            .select('id')
            .maybeSingle();

        submittedProductId =
            inserted == null ? '' : (inserted['id'] ?? '').toString().trim();
      } catch (minimalError) {
        farmDebugLog(
          'Minimal farmer product insert failed: $minimalError',
        );
        throw Exception(
          'Could not submit product. Please make sure your farmer profile is approved and linked to this account.',
        );
      }
    }
  }

  if (submittedProductId.isEmpty) {
    try {
      final recovered = await supabase
          .from('products')
          .select('id')
          .eq('farmer_id', farmer.id)
          .eq('name', cleanName)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      submittedProductId =
          recovered == null ? '' : (recovered['id'] ?? '').toString().trim();
    } catch (error) {
      farmDebugLog(
        'Farmer product id recovery skipped after successful submission: $error',
      );
    }
  }

  await createAdminNotification(
    title: 'Product awaiting approval',
    message: '${farmer.farmName} submitted $cleanName for review.',
    type: 'admin',
    actionType: 'admin_product_approval',
    actionId: submittedProductId.isEmpty ? null : submittedProductId,
    dedupeKey: submittedProductId.isEmpty
        ? null
        : 'admin-product-approval:$submittedProductId',
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
// =====================================================
// WHOLESALE FARMER PAYOUT
// Creates one pending payout from a completed
// warehouse receiving batch.
// =====================================================

Future<String> createWholesaleFarmerPayout(
  String receivingBatchId,
) async {
  await requireAdminAccess();

  final cleanId = receivingBatchId.trim();

  if (cleanId.isEmpty) {
    throw Exception(
      'Receiving batch is required.',
    );
  }

  final response = await supabase.rpc(
    'create_wholesale_farmer_payout',
    params: {
      'p_receiving_batch_id': cleanId,
    },
  );

  final payoutId = response?.toString().trim() ?? '';

  if (payoutId.isEmpty) {
    throw Exception(
      'The farmer payout could not be prepared.',
    );
  }

  return payoutId;
}

Future<List<FarmerPayout>> fetchFarmerPayouts({String? farmerId}) async {
  try {
    final scopedFarmerId = await _resolveFarmerReadScope(
      farmerId: farmerId,
      allowAdminAll: true,
    );

    dynamic query = supabase.from('farmer_payouts').select(
          'id, farmer_id, order_id, '
          'gross_amount, commission_amount, net_amount, '
          'payout_status, payout_method, payout_reference, '
          'source_type, receiving_batch_id, wholesale_request_id, '
          'product_name, payout_quantity, payout_unit, '
          'farmer_unit_cost, notes, '
          'released_at, created_at',
        );

    // Admin may intentionally request the all-farmer view. Every non-admin
    // farmer request is resolved to that signed-in farmer's own profile ID.
    if (scopedFarmerId != null && scopedFarmerId.isNotEmpty) {
      query = query.eq('farmer_id', scopedFarmerId);
    }

    query = query.order(
      'created_at',
      ascending: false,
    );

    final response = await query;

    return (response as List)
        .map(
          (item) => FarmerPayout.fromSupabase(
            Map<String, dynamic>.from(item),
          ),
        )
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

Future<String> createSupportTicket({
  required String subject,
  required String message,
}) async {
  final cleanSubject = subject.trim();
  final cleanMessage = message.trim();
  if (cleanSubject.isEmpty || cleanMessage.isEmpty) {
    throw Exception('Please enter a subject and message.');
  }

  try {
    final response = await supabase.rpc(
      'hpj_create_support_conversation',
      params: {
        'p_subject': cleanSubject,
        'p_message': cleanMessage,
      },
    );

    final ticketId = response?.toString().trim() ?? '';
    if (ticketId.isEmpty) {
      throw Exception('HPJ Customer Care could not create the conversation.');
    }

    // Keep admin notifications generic so private message content never appears
    // outside the secured conversation itself.
    await createAdminNotification(
      title: 'New private Customer Care conversation',
      message:
          'A signed-in HPJ user started Customer Care conversation #${ticketId.length <= 6 ? ticketId.toUpperCase() : ticketId.substring(0, 6).toUpperCase()}.',
      type: 'support',
      actionType: 'admin_support_chat',
      actionId: ticketId,
    );

    return ticketId;
  } catch (error) {
    final lower = error.toString().toLowerCase();
    if (lower.contains('hpj_create_support_conversation') ||
        lower.contains('function') && lower.contains('does not exist')) {
      throw Exception(
        'Customer Care security update is not installed yet. Run the HPJ private chat Supabase migration.',
      );
    }
    rethrow;
  }
}

const String _supportTicketSelectFields =
    'id, user_id, email, subject, message, status, admin_reply, '
    'last_message_preview, last_sender_role, assigned_staff_id, priority, '
    'created_at, updated_at, last_message_at, customer_last_read_at, staff_last_read_at';

Future<List<SupportTicket>> fetchMySupportTickets() async {
  final user = supabase.auth.currentUser;
  if (user == null) return const <SupportTicket>[];

  try {
    final response = await supabase
        .from('support_tickets')
        .select(_supportTicketSelectFields)
        .eq('user_id', user.id)
        .order('last_message_at', ascending: false)
        .order('created_at', ascending: false)
        .limit(50);

    return (response as List)
        .map((item) =>
            SupportTicket.fromSupabase(Map<String, dynamic>.from(item as Map)))
        .toList();
  } catch (error) {
    farmDebugLog('Failed to fetch this user support conversations: $error');
    return const <SupportTicket>[];
  }
}

Future<SupportTicket?> fetchSupportTicket(String ticketId) async {
  final cleanId = ticketId.trim();
  if (cleanId.isEmpty) return null;

  try {
    final response = await supabase
        .from('support_tickets')
        .select(_supportTicketSelectFields)
        .eq('id', cleanId)
        .maybeSingle();
    if (response == null) return null;
    return SupportTicket.fromSupabase(Map<String, dynamic>.from(response));
  } catch (error) {
    farmDebugLog('Support conversation lookup skipped: $error');
    return null;
  }
}

Stream<SupportTicket?> watchSupportTicket(String ticketId) {
  final cleanId = ticketId.trim();
  if (cleanId.isEmpty) return Stream<SupportTicket?>.value(null);

  return supabase
      .from('support_tickets')
      .stream(primaryKey: const ['id'])
      .eq('id', cleanId)
      .map((rows) {
        if (rows.isEmpty) return null;
        return SupportTicket.fromSupabase(
          Map<String, dynamic>.from(rows.first),
        );
      });
}

Stream<List<SupportMessage>> watchSupportMessages(String ticketId) {
  final cleanId = ticketId.trim();
  if (cleanId.isEmpty) {
    return Stream<List<SupportMessage>>.value(const <SupportMessage>[]);
  }

  return supabase
      .from('support_messages')
      .stream(primaryKey: const ['id'])
      .eq('ticket_id', cleanId)
      .order('created_at', ascending: true)
      .map(
        (rows) => rows
            .map(
              (item) => SupportMessage.fromSupabase(
                Map<String, dynamic>.from(item),
              ),
            )
            .where((message) => !message.isInternal)
            .toList(),
      );
}

Future<void> sendSupportMessage({
  required String ticketId,
  required String message,
  bool internal = false,
}) async {
  final cleanId = ticketId.trim();
  final cleanMessage = message.trim();
  if (cleanId.isEmpty || cleanMessage.isEmpty) {
    throw Exception('Please enter a message.');
  }

  await supabase.rpc(
    'hpj_send_support_message',
    params: {
      'p_ticket_id': cleanId,
      'p_message': cleanMessage,
      'p_internal': internal,
    },
  );

  if (internal) return;

  // Create the recipient notification server-side. The RPC determines whether
  // the sender is the ticket owner or HPJ staff and writes the correct private
  // notification row(s) with exact action_type/action_id metadata.
  try {
    final response = await supabase.rpc(
      'hpj_create_support_message_notifications',
      params: {'p_ticket_id': cleanId},
    );

    final ids = <String>[];
    if (response is List) {
      for (final value in response) {
        final id = value?.toString().trim() ?? '';
        if (id.isNotEmpty) ids.add(id);
      }
    } else {
      final id = response?.toString().trim() ?? '';
      if (id.isNotEmpty) ids.add(id);
    }

    for (final id in ids.toSet()) {
      await dispatchStoredPushNotification(id);
    }
    return;
  } catch (error) {
    farmDebugLog(
      'Secure support notification RPC unavailable; using compatibility path: '
      '$error',
    );
  }

  // Compatibility path for a database that has not received migration 009
  // yet. Keep this narrow and private; the normal path above is preferred.
  final ticket = await fetchSupportTicket(cleanId);
  if (ticket == null) return;

  var senderIsStaff = false;
  try {
    final role = await fetchCurrentStaffRole();
    senderIsStaff = isStaffRoleActive(role);
    if (!senderIsStaff) {
      senderIsStaff = await isCurrentUserAdminFromDatabase();
    }
  } catch (_) {
    senderIsStaff = false;
  }

  if (senderIsStaff) {
    await createFarmNotification(
      title: 'HPJ Inbox reply',
      message: 'You have a new private reply from The Harvest Place Ja.',
      type: 'support',
      userId: ticket.userId.trim().isEmpty ? null : ticket.userId.trim(),
      userEmail: ticket.email.trim().isEmpty ? null : ticket.email.trim(),
      actionType: 'support_chat',
      actionId: cleanId,
    );
  } else {
    await createAdminNotification(
      title: 'New HPJ Inbox message',
      message: 'Conversation #${ticket.shortId} has a new private reply.',
      type: 'support',
      actionType: 'admin_support_chat',
      actionId: cleanId,
    );
  }
}

Future<void> markSupportConversationRead(String ticketId) async {
  final cleanId = ticketId.trim();
  if (cleanId.isEmpty) return;
  try {
    await supabase.rpc(
      'hpj_mark_support_read',
      params: {'p_ticket_id': cleanId},
    );
  } catch (error) {
    farmDebugLog('Support read receipt skipped: $error');
  }
}

Future<void> claimSupportConversation(String ticketId) async {
  final cleanId = ticketId.trim();
  if (cleanId.isEmpty) return;
  try {
    await supabase.rpc(
      'hpj_claim_support_conversation',
      params: {'p_ticket_id': cleanId},
    );
  } catch (error) {
    // Owner/manager supervisors do not need to claim tickets. Dedicated
    // Customer Care agents will receive a real error if another agent already
    // owns the private thread; the admin screen handles that on send/open.
    farmDebugLog('Support claim check: $error');
  }
}

Future<void> updateSupportTicket({
  required String ticketId,
  required String status,
  String? adminReply,
}) async {
  final cleanReply = adminReply?.trim() ?? '';
  if (cleanReply.isNotEmpty) {
    await sendSupportMessage(
      ticketId: ticketId,
      message: cleanReply,
    );
  }

  await supabase.rpc(
    'hpj_set_support_status',
    params: {
      'p_ticket_id': ticketId.trim(),
      'p_status': status.trim().toLowerCase(),
    },
  );
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

Future<List<Product>> fetchReviewEligibleProducts() async {
  final user = supabase.auth.currentUser;
  if (user == null) return const <Product>[];

  final operationBoundary =
      captureHpjPrivateOperationBoundary();

  try {
    final response = await supabase.rpc(
      'list_review_eligible_product_ids_secure',
    );

    if (!isHpjPrivateOperationBoundaryCurrent(operationBoundary)) {
      return const <Product>[];
    }

    final ids = <String>{};

    if (response is List) {
      for (final item in response) {
        final id = item?.toString().trim() ?? '';
        if (id.isNotEmpty) ids.add(id);
      }
    } else if (response != null) {
      final id = response.toString().trim();
      if (id.isNotEmpty) ids.add(id);
    }

    if (ids.isEmpty) return const <Product>[];

    final products = await fetchProducts();

    if (!isHpjPrivateOperationBoundaryCurrent(operationBoundary)) {
      return const <Product>[];
    }

    return products
        .where(
          (product) =>
              ids.contains(product.id.trim()) &&
              product.isCustomerVisible,
        )
        .toList();
  } catch (error) {
    farmDebugLog(
      'Verified review product eligibility load skipped: $error',
    );
    return const <Product>[];
  }
}

Future<void> createProductReview({
  required String productId,
  required String productName,
  required int rating,
  required String comment,
}) async {
  final user = supabase.auth.currentUser;
  if (user == null) {
    throw Exception('Please sign in before sharing a review.');
  }

  final cleanProductId = productId.trim();
  final cleanComment = comment.trim();

  if (cleanProductId.isEmpty) {
    throw Exception('Choose a product you purchased.');
  }

  if (rating < 1 || rating > 5) {
    throw Exception('Choose a rating from 1 to 5 stars.');
  }

  if (cleanComment.length < 8) {
    throw Exception(
      'Add a little more detail so your review is useful.',
    );
  }

  if (cleanComment.length > 1200) {
    throw Exception(
      'Keep your review under 1,200 characters.',
    );
  }

  final operationBoundary =
      captureHpjPrivateOperationBoundary();

  final mutationLease = acquireHpjPrivateMutation(
    'product-review:$cleanProductId',
    expectedBoundary: operationBoundary,
  );

  try {
    mutationLease.ensureCurrent();

    final response = await supabase.rpc(
      'submit_verified_product_review_secure',
      params: {
        'p_product_id': cleanProductId,
        'p_rating': rating,
        'p_comment': cleanComment,
      },
    );

    mutationLease.ensureCurrent();

    if (response is! Map) {
      throw Exception(
        'The review could not be verified and saved.',
      );
    }

    final row = Map<String, dynamic>.from(response);
    final serverProductName =
        (row['product_name'] ?? productName).toString().trim();
    final customerName =
        (row['customer_name'] ?? 'HPJ Customer').toString().trim();
    final created = row['created'] == true;

    await createAdminNotification(
      title: created
          ? 'New verified product review'
          : 'Verified product review updated',
      message:
          '${customerName.isEmpty ? 'An HPJ customer' : customerName} left a $rating-star review for ${serverProductName.isEmpty ? productName : serverProductName}.',
      type: 'review',
      actionType: 'admin_review',
      actionId: cleanProductId,
      dedupeKey: 'admin-review:${user.id}:$cleanProductId',
    );

    mutationLease.ensureCurrent();
  } finally {
    mutationLease.release();
  }
}

Future<List<ProductReview>> fetchProductReviews() async {
  Future<List<ProductReview>> parseReviews(dynamic response) async {
    if (response is! List) return const <ProductReview>[];

    return response
        .whereType<Map>()
        .map(
          (item) => ProductReview.fromSupabase(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  try {
    final isAdmin = await isCurrentUserAdminFromDatabase();

    if (isAdmin) {
      try {
        final response = await supabase
            .from('product_reviews')
            .select(
                'id, product_id, product_name, user_id, customer_name, email, rating, comment, created_at, verified_purchase, verified_order_id, products(name)')
            .order('created_at', ascending: false)
            .limit(100);

        final reviews = await parseReviews(response);
        return _attachCustomerProfileNames(reviews);
      } catch (adminCompatibilityError) {
        final response = await supabase
            .from('product_reviews')
            .select(
                'id, product_id, product_name, user_id, email, rating, comment, created_at, products(name)')
            .order('created_at', ascending: false)
            .limit(100);

        final reviews = await parseReviews(response);
        return _attachCustomerProfileNames(reviews);
      }
    }

    final response = await supabase.rpc(
      'fetch_public_verified_product_reviews_secure',
      params: {
        'p_limit': 100,
      },
    );

    return parseReviews(response);
  } catch (error) {
    // Safe compatibility fallback. RLS continues to limit direct table reads
    // to the current user/admin on older deployments; no write fallback exists.
    farmDebugLog(
      'Verified public reviews RPC unavailable; using safe read fallback: $error',
    );

    try {
      final response = await supabase
          .from('product_reviews')
          .select(
              'id, product_id, product_name, user_id, customer_name, email, rating, comment, created_at, products(name)')
          .order('created_at', ascending: false)
          .limit(100);

      final reviews = await parseReviews(response);
      return _attachCustomerProfileNames(reviews);
    } catch (fallbackError) {
      farmDebugLog('Failed to fetch product reviews: $fallbackError');
      return const <ProductReview>[];
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
  UserExperiencePreferences? preferences,
}) {
  final preference = preferences ?? UserExperiencePreferences.defaults;
  var visibleProducts = uniqueVisibleProducts(allProducts, limit: 500);

  if (preference.organicPreference == 'only') {
    visibleProducts = visibleProducts.where((product) => product.isOrganic).toList();
  }

  int preferenceScore(Product product) {
    var score = 0;

    if ((preference.organicPreference == 'prefer' ||
            preference.recommendationStyle == 'organic_first') &&
        product.isOrganic) {
      score += 10000;
    }

    if (preference.recommendationStyle == 'budget_first') {
      if (product.showAsDealOfDay) score += 9000;
      if (product.hasActiveDiscount) score += 7000;
      score += (100000 / (product.effectivePrice + 1))
          .round()
          .clamp(0, 2500)
          .toInt();
    }

    if (preference.recommendationStyle == 'healthy_variety') {
      score += product.allNutrientTags.length * 500;
      if (product.nutritionVerified) score += 1500;
    }

    return score;
  }

  if (preference.recommendationStyle == 'organic_first' ||
      preference.recommendationStyle == 'budget_first' ||
      preference.recommendationStyle == 'healthy_variety' ||
      preference.organicPreference == 'prefer') {
    visibleProducts = List<Product>.of(visibleProducts)
      ..sort((a, b) {
        final scoreCompare = preferenceScore(b).compareTo(preferenceScore(a));
        if (scoreCompare != 0) return scoreCompare;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
  }

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

  final allowPersonalSignals = preference.personalizationEnabled;

  final signalCategories = <String>{
    if (allowPersonalSignals)
      ...recentlyViewedProducts.map((product) => product.category.toLowerCase()),
    if (allowPersonalSignals)
      ...buyAgainProducts.map((product) => product.category.toLowerCase()),
    if (allowPersonalSignals && preference.recommendationStyle == 'favorites')
      ...favoriteProducts.map((product) => product.category.toLowerCase()),
  }..removeWhere((category) => category.trim().isEmpty);

  if (preference.recommendationStyle == 'favorites' && allowPersonalSignals) {
    final favoriteIds = favoriteProducts.map((product) => product.id).toSet();
    for (final product in visibleProducts) {
      if (favoriteIds.contains(product.id)) add(product);
    }
  }

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
                'Place one final review order, then verify order details, totals, and notifications.',
            icon: Icons.receipt_long_outlined,
          ),
    review(
      title: 'Notifications',
      detail:
          'After a review order, tap the admin notification and customer notification to confirm both open the correct order.',
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
          'Customer trust screens are present and ready for final phone review.',
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

// =====================================================
// HPJ SOCIAL UTILITY INTELLIGENCE
// Useful social mechanics only: Watch + New/Seen.
// No public profiles, follower counts, likes, comments,
// or public conversations are introduced here.
// =====================================================
String hpjWatchKeyPart(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll('|', '/');
}

String hpjFarmerDemandWatchKey(String productName, String unit) {
  return '${hpjWatchKeyPart(productName)}|${hpjWatchKeyPart(unit)}';
}

String hpjFarmerDemandFeedItemKey(FarmerMarketDemandOpportunity opportunity) {
  final needBy = opportunity.nextNeedBy;
  final dateKey = needBy == null
      ? 'open'
      : '${needBy.year.toString().padLeft(4, '0')}-${needBy.month.toString().padLeft(2, '0')}-${needBy.day.toString().padLeft(2, '0')}';
  final gapKey = opportunity.opportunityGap.toStringAsFixed(2);
  return 'demand:${hpjFarmerDemandWatchKey(opportunity.productName, opportunity.unit)}:$dateKey:$gapKey';
}

Future<Set<String>> fetchHpjActiveWatchKeys({
  required String workspace,
  required String watchType,
}) async {
  final user = supabase.auth.currentUser;
  if (user == null) return <String>{};

  try {
    final response = await supabase
        .from('hpj_watches')
        .select('entity_key')
        .eq('user_id', user.id)
        .eq('workspace', workspace)
        .eq('watch_type', watchType)
        .eq('is_active', true);

    return (response as List)
        .map((row) => (row['entity_key'] ?? '').toString().trim())
        .where((value) => value.isNotEmpty)
        .toSet();
  } catch (error) {
    farmDebugLog('HPJ Watch lookup skipped: $error');
    return <String>{};
  }
}

Future<bool> isHpjWatchActive({
  required String workspace,
  required String watchType,
  required String entityKey,
}) async {
  final user = supabase.auth.currentUser;
  if (user == null || entityKey.trim().isEmpty) return false;

  try {
    final row = await supabase
        .from('hpj_watches')
        .select('is_active')
        .eq('user_id', user.id)
        .eq('workspace', workspace)
        .eq('watch_type', watchType)
        .eq('entity_key', entityKey.trim())
        .maybeSingle();
    return row != null && row['is_active'] == true;
  } catch (error) {
    farmDebugLog('HPJ Watch status lookup skipped: $error');
    return false;
  }
}

Future<bool> setHpjWatchActive({
  required String workspace,
  required String watchType,
  required String entityKey,
  required String entityName,
  required bool active,
}) async {
  final user = supabase.auth.currentUser;
  if (user == null) {
    throw Exception('Please sign in to watch updates.');
  }

  final cleanKey = entityKey.trim();
  final cleanName = entityName.trim();
  if (cleanKey.isEmpty || cleanName.isEmpty) {
    throw Exception('This item cannot be watched yet.');
  }

  try {
    await supabase.from('hpj_watches').upsert({
      'user_id': user.id,
      'user_email': (user.email ?? '').trim().toLowerCase(),
      'workspace': workspace,
      'watch_type': watchType,
      'entity_key': cleanKey,
      'entity_name': cleanName,
      'is_active': active,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id,workspace,watch_type,entity_key');
    return active;
  } catch (error) {
    farmDebugLog('HPJ Watch update failed: $error');
    throw Exception(
      'Watch is not ready yet. Run the HPJ Social Utility SQL migration and try again.',
    );
  }
}

Future<bool> isHpjFeedItemSeen({
  required String workspace,
  required String itemKey,
}) async {
  final user = supabase.auth.currentUser;
  if (user == null || itemKey.trim().isEmpty) return true;

  try {
    final row = await supabase
        .from('hpj_feed_seen')
        .select('item_key')
        .eq('user_id', user.id)
        .eq('workspace', workspace)
        .eq('item_key', itemKey.trim())
        .maybeSingle();
    return row != null;
  } catch (error) {
    // If the migration has not been run, do not falsely badge every card NEW.
    farmDebugLog('HPJ Feed seen lookup skipped: $error');
    return true;
  }
}

Future<void> markHpjFeedItemSeen({
  required String workspace,
  required String itemKey,
}) async {
  final user = supabase.auth.currentUser;
  if (user == null || itemKey.trim().isEmpty) return;

  try {
    await supabase.from('hpj_feed_seen').upsert({
      'user_id': user.id,
      'workspace': workspace,
      'item_key': itemKey.trim(),
      'seen_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id,workspace,item_key');
  } catch (error) {
    farmDebugLog('HPJ Feed seen save skipped: $error');
  }
}

Future<void> syncHpjFarmerDemandWatchNotifications(
  List<FarmerMarketDemandOpportunity> opportunities,
) async {
  final user = supabase.auth.currentUser;
  if (user == null || opportunities.isEmpty) return;

  final watched = await fetchHpjActiveWatchKeys(
    workspace: 'farmer',
    watchType: 'farmer_demand',
  );
  if (watched.isEmpty) return;

  for (final opportunity in opportunities) {
    if (opportunity.opportunityGap <= 0.0001) continue;
    final watchKey = hpjFarmerDemandWatchKey(
      opportunity.productName,
      opportunity.unit,
    );
    if (!watched.contains(watchKey)) continue;

    final needBy = opportunity.nextNeedBy;
    final dateKey = needBy == null
        ? 'open'
        : '${needBy.year.toString().padLeft(4, '0')}-${needBy.month.toString().padLeft(2, '0')}-${needBy.day.toString().padLeft(2, '0')}';
    final quantityKey = opportunity.opportunityGap.toStringAsFixed(2);

    await createFarmNotification(
      title: '${opportunity.productName} buyer demand',
      message:
          '${_farmerPartnerNumber(opportunity.opportunityGap)} ${opportunity.unit} is currently needed${needBy == null ? '' : ' by ${_farmerPartnerDate(needBy)}'}.',
      type: 'farmer_demand',
      userId: user.id,
      userEmail: user.email,
      actionType: 'farmer_demand',
      actionId: watchKey,
      dedupeKey: 'farmer-demand:$watchKey:$dateKey:$quantityKey',
    );
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
    case 'watch':
      return 'Watching';
    case 'price_drop':
      return 'Price drop';
    case 'farmer_demand':
      return 'Buyer demand';
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
    case 'watch':
      return FarmColors.primary;
    case 'price_drop':
      return FarmColors.success;
    case 'farmer_demand':
      return FarmColors.warning;
    case 'support':
      return FarmColors.primaryDark;
    case 'review':
      return FarmColors.accent;
    default:
      return FarmColors.green;
  }
}

// =====================================================
// HPJ NAVIGATION MEMORY
// Supabase already persists the authenticated session.
// These helpers remember only safe workspace/tab choices
// so users resume naturally without reopening transient
// forms, sheets, checkout, or admin tools.
// =====================================================
Future<HpjNavigationPreference?> fetchHpjNavigationPreference() async {
  final user = supabase.auth.currentUser;
  if (user == null) return null;

  try {
    final row = await supabase
        .from('user_navigation_preferences')
        .select(
          'last_workspace, customer_tab, farmer_tab, wholesale_tab',
        )
        .eq('user_id', user.id)
        .maybeSingle();

    if (row == null) return null;

    return HpjNavigationPreference.fromSupabase(
      Map<String, dynamic>.from(row),
    );
  } catch (error) {
    // Navigation memory should never stop the user reaching HPJ.
    farmDebugLog('Navigation preference load skipped: $error');
    return null;
  }
}

Future<void> saveHpjNavigationPreference({
  required String workspace,
  required int tab,
}) async {
  final user = supabase.auth.currentUser;
  if (user == null) return;

  final cleanWorkspace = workspace.trim().toLowerCase();

  // Staff/admin is deliberately excluded from startup memory. HPJ never
  // auto-opens administration after login or app restart.
  if (!const {'customer', 'farmer', 'wholesale'}.contains(cleanWorkspace)) {
    return;
  }

  final safeTab = tab.clamp(0, 4);

  try {
    await supabase.rpc(
      'hpj_save_navigation_preference',
      params: {
        'p_workspace': cleanWorkspace,
        'p_tab': safeTab,
      },
    );
  } catch (error) {
    // Memory is convenience only. Never block navigation because it failed.
    farmDebugLog('Navigation preference save skipped: $error');
  }
}

// =====================================================
// HPJ AGRICULTURE INTELLIGENCE FEED SERVICES
// =====================================================
const String _agricultureFeedSelectFields =
    'id, title, summary, image_url, category, audiences, priority, '
    'source_name, source_url, action_label, action_type, action_id, '
    'is_active, publish_at, expires_at, created_by, created_at, updated_at';

const Set<String> _agricultureFeedCategories = <String>{
  'agriculture_news',
  'official_notice',
  'market_intelligence',
  'hpj_update',
  'opportunity',
  'education',
  'weather_alert',
};

const Set<String> _agricultureFeedAudiences = <String>{
  'customer',
  'farmer',
  'wholesale',
};

const Set<String> _agricultureFeedPriorities = <String>{
  'normal',
  'important',
  'urgent',
};

const Set<String> _agricultureFeedActionTypes = <String>{
  'none',
  'external',
  'customer_shop',
  'customer_care',
  'farmer_demand',
  'farmer_supply',
  'wholesale_shop',
  'wholesale_plan',
};

Future<List<AgricultureFeedUpdate>> fetchAgricultureFeedUpdates({
  required String audience,
  int limit = 5,
}) async {
  final cleanAudience = audience.trim().toLowerCase();
  if (!_agricultureFeedAudiences.contains(cleanAudience)) {
    return const <AgricultureFeedUpdate>[];
  }

  try {
    final response = await supabase
        .from('agriculture_feed_updates')
        .select(_agricultureFeedSelectFields)
        .eq('is_active', true)
        .order('publish_at', ascending: false)
        .limit(100);

    final now = DateTime.now();
    final rows = (response as List)
        .map(
      (item) => AgricultureFeedUpdate.fromSupabase(
        Map<String, dynamic>.from(item as Map),
      ),
    )
        .where((item) {
      if (!item.isForAudience(cleanAudience)) return false;
      if (item.publishAt.isAfter(now)) return false;
      if (item.expiresAt != null && !item.expiresAt!.isAfter(now)) {
        return false;
      }
      return true;
    }).toList();

    rows.sort((a, b) {
      int priorityScore(AgricultureFeedUpdate item) {
        if (item.priority == 'urgent') return 3;
        if (item.priority == 'important') return 2;
        return 1;
      }

      final priorityCompare = priorityScore(b).compareTo(priorityScore(a));
      if (priorityCompare != 0) return priorityCompare;
      return b.publishAt.compareTo(a.publishAt);
    });

    return rows.take(limit.clamp(1, 20).toInt()).toList(growable: false);
  } catch (error) {
    farmDebugLog('Agriculture feed unavailable: $error');
    return const <AgricultureFeedUpdate>[];
  }
}

Future<List<AgricultureFeedUpdate>> fetchAdminAgricultureFeedUpdates() async {
  await requireAdminAccess();

  final response = await supabase
      .from('agriculture_feed_updates')
      .select(_agricultureFeedSelectFields)
      .order('publish_at', ascending: false)
      .limit(200);

  return (response as List)
      .map(
        (item) => AgricultureFeedUpdate.fromSupabase(
          Map<String, dynamic>.from(item as Map),
        ),
      )
      .toList(growable: false);
}

String? _cleanAgricultureFeedHttpUrl(String? value) {
  final clean = value?.trim() ?? '';
  if (clean.isEmpty) return null;
  final uri = Uri.tryParse(clean);
  if (uri == null || uri.host.trim().isEmpty) return null;
  if (uri.scheme != 'https' && uri.scheme != 'http') return null;
  return clean;
}

Future<String> uploadAgricultureFeedImageToStorage(
  PickedProductImage image,
) async {
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
  final path = 'agriculture-feed/$userId/$timestamp-$safeName';

  await supabase.storage.from(productImageStorageBucket).uploadBinary(
        path,
        image.bytes,
        fileOptions: FileOptions(
          contentType: _contentTypeForImage(image),
          upsert: true,
        ),
      );

  return supabase.storage.from(productImageStorageBucket).getPublicUrl(path);
}

Future<AgricultureFeedUpdate> saveAgricultureFeedUpdate({
  String? id,
  required String title,
  required String summary,
  String? imageUrl,
  required String category,
  required List<String> audiences,
  required String priority,
  String? sourceName,
  String? sourceUrl,
  String? actionLabel,
  String actionType = 'none',
  String? actionId,
  bool isActive = true,
  required DateTime publishAt,
  DateTime? expiresAt,
}) async {
  await requireAdminAccess();

  final cleanTitle = title.trim();
  final cleanSummary = summary.trim();
  final cleanCategory = category.trim().toLowerCase();
  final cleanPriority = priority.trim().toLowerCase();
  final cleanActionType = actionType.trim().toLowerCase();
  final cleanAudiences = audiences
      .map((item) => item.trim().toLowerCase())
      .where((item) => _agricultureFeedAudiences.contains(item))
      .toSet()
      .toList(growable: false);

  if (cleanTitle.length < 3 || cleanTitle.length > 120) {
    throw Exception('Use a headline between 3 and 120 characters.');
  }
  if (cleanSummary.length < 8 || cleanSummary.length > 800) {
    throw Exception('Use a useful summary between 8 and 800 characters.');
  }
  if (!_agricultureFeedCategories.contains(cleanCategory)) {
    throw Exception('Choose a valid update category.');
  }
  if (cleanAudiences.isEmpty) {
    throw Exception('Choose at least one audience.');
  }
  if (!_agricultureFeedPriorities.contains(cleanPriority)) {
    throw Exception('Choose a valid priority.');
  }
  if (!_agricultureFeedActionTypes.contains(cleanActionType)) {
    throw Exception('Choose a valid action.');
  }
  if (expiresAt != null && !expiresAt.isAfter(publishAt)) {
    throw Exception('Expiry must be after the publish date.');
  }

  final cleanImageUrl = cleanHostedImageUrl(imageUrl);
  final cleanSourceUrl = _cleanAgricultureFeedHttpUrl(sourceUrl);
  if ((sourceUrl ?? '').trim().isNotEmpty && cleanSourceUrl == null) {
    throw Exception('Enter a valid http or https source link.');
  }

  final row = <String, dynamic>{
    'title': cleanTitle,
    'summary': cleanSummary,
    'image_url': cleanImageUrl,
    'category': cleanCategory,
    'audiences': cleanAudiences,
    'priority': cleanPriority,
    'source_name':
        (sourceName ?? '').trim().isEmpty ? null : sourceName!.trim(),
    'source_url': cleanSourceUrl,
    'action_label':
        (actionLabel ?? '').trim().isEmpty ? null : actionLabel!.trim(),
    'action_type': cleanActionType,
    'action_id': (actionId ?? '').trim().isEmpty ? null : actionId!.trim(),
    'is_active': isActive,
    'publish_at': publishAt.toUtc().toIso8601String(),
    'expires_at': expiresAt?.toUtc().toIso8601String(),
  };

  final cleanId = id?.trim() ?? '';
  dynamic response;
  if (cleanId.isEmpty) {
    row['created_by'] = supabase.auth.currentUser?.id;
    response = await supabase
        .from('agriculture_feed_updates')
        .insert(row)
        .select(_agricultureFeedSelectFields)
        .single();
  } else {
    response = await supabase
        .from('agriculture_feed_updates')
        .update(row)
        .eq('id', cleanId)
        .select(_agricultureFeedSelectFields)
        .single();
  }

  return AgricultureFeedUpdate.fromSupabase(
    Map<String, dynamic>.from(response as Map),
  );
}

Future<void> setAgricultureFeedUpdateActive({
  required String id,
  required bool isActive,
}) async {
  await requireAdminAccess();
  final cleanId = id.trim();
  if (cleanId.isEmpty) return;

  await supabase
      .from('agriculture_feed_updates')
      .update({'is_active': isActive}).eq('id', cleanId);
}

Future<void> deleteAgricultureFeedUpdate(String id) async {
  await requireAdminAccess();
  final cleanId = id.trim();
  if (cleanId.isEmpty) return;
  await supabase.from('agriculture_feed_updates').delete().eq('id', cleanId);
}

// =====================================================
// HPJ JAMAICA SUPPLY–DEMAND INTELLIGENCE
// Reads aggregated national signals only. The Supabase RPC
// deliberately returns no farmer or buyer identities.
// =====================================================
Future<List<JamaicaSupplyDemandInsight>> fetchJamaicaSupplyDemandIntelligence({
  int limit = 12,
}) async {
  if (!isLoggedIn) return const <JamaicaSupplyDemandInsight>[];

  final safeLimit = limit.clamp(1, 50).toInt();

  try {
    final response = await supabase.rpc(
      'get_jamaica_supply_demand_intelligence',
      params: <String, dynamic>{
        'p_limit': safeLimit,
      },
    );

    if (response is! List) {
      return const <JamaicaSupplyDemandInsight>[];
    }

    return response
        .map(
          (item) => JamaicaSupplyDemandInsight.fromSupabase(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList(growable: false);
  } catch (error) {
    farmDebugLog(
      'Jamaica supply-demand intelligence unavailable: $error',
    );
    return const <JamaicaSupplyDemandInsight>[];
  }
}
