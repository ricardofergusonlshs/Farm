part of harvest_place_app;

class HomeHeroSlide {
  final String id;
  final int position;
  final String imageUrl;
  final String? title;
  final String? subtitle;
  final bool isActive;
  final DateTime? updatedAt;

  const HomeHeroSlide({
    required this.id,
    required this.position,
    required this.imageUrl,
    this.title,
    this.subtitle,
    this.isActive = true,
    this.updatedAt,
  });

  factory HomeHeroSlide.fromSupabase(Map<String, dynamic> data) {
    return HomeHeroSlide(
      id: (data['id'] ?? '').toString(),
      position: Product._toInt(data['position'] ?? 1),
      imageUrl: (data['image_url'] ?? '').toString(),
      title: data['title']?.toString(),
      subtitle: data['subtitle']?.toString(),
      isActive: data['is_active'] == null ? true : data['is_active'] == true,
      updatedAt: parseProductDate(data['updated_at']),
    );
  }
}

class DeliveryZone {
  final String id;
  final String parish;
  final String? zoneName;
  final double deliveryFee;
  final bool isActive;
  final int sortOrder;
  final String? notes;
  final DateTime? updatedAt;

  const DeliveryZone({
    required this.id,
    required this.parish,
    this.zoneName,
    required this.deliveryFee,
    this.isActive = true,
    this.sortOrder = 0,
    this.notes,
    this.updatedAt,
  });

  factory DeliveryZone.fromSupabase(Map<String, dynamic> data) {
    return DeliveryZone(
      id: (data['id'] ?? '').toString(),
      parish: (data['parish'] ?? '').toString(),
      zoneName: data['zone_name']?.toString(),
      deliveryFee: Product._toDouble(data['delivery_fee']),
      isActive: data['is_active'] == null ? true : data['is_active'] == true,
      sortOrder: Product._toInt(data['sort_order']),
      notes: data['notes']?.toString(),
      updatedAt: parseProductDate(data['updated_at']),
    );
  }

  String get displayName {
    final parishText = parish.trim();
    final zoneText = zoneName?.trim() ?? '';
    if (zoneText.isEmpty) return parishText;
    if (zoneText.toLowerCase() == parishText.toLowerCase()) return parishText;
    return '$parishText / $zoneText';
  }

  DeliveryZone copyWith({
    String? id,
    String? parish,
    String? zoneName,
    double? deliveryFee,
    bool? isActive,
    int? sortOrder,
    String? notes,
    DateTime? updatedAt,
  }) {
    return DeliveryZone(
      id: id ?? this.id,
      parish: parish ?? this.parish,
      zoneName: zoneName ?? this.zoneName,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder ?? this.sortOrder,
      notes: notes ?? this.notes,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class SecureCartLineQuote {
  final Product product;
  final int quantity;
  final double unitPrice;
  final int availableStock;
  final bool isAvailable;

  const SecureCartLineQuote({
    required this.product,
    required this.quantity,
    required this.unitPrice,
    required this.availableStock,
    required this.isAvailable,
  });

  double get lineTotal => unitPrice * quantity;
}

class SecureCartQuote {
  final List<SecureCartLineQuote> lines;

  const SecureCartQuote({required this.lines});

  double get subtotal {
    return lines.fold<double>(0, (sum, line) => sum + line.lineTotal);
  }

  SecureCartLineQuote? lineForProduct(String productId) {
    try {
      return lines.firstWhere((line) => line.product.id == productId);
    } catch (_) {
      return null;
    }
  }
}

class LoyaltySummary {
  final int points;
  final int lifetimePoints;
  final String tier;

  const LoyaltySummary({
    required this.points,
    required this.lifetimePoints,
    required this.tier,
  });

  String get nextTierLabel {
    if (tier == 'Platinum') return 'Top tier unlocked';
    if (lifetimePoints >= 1000) return 'Platinum unlocked';
    if (lifetimePoints >= 500)
      return '${1000 - lifetimePoints} points to Platinum';
    return '${500 - lifetimePoints} points to Gold';
  }
}

class CustomerReferralSummary {
  final int pendingCount;
  final int completedCount;
  final int pointsEarned;

  const CustomerReferralSummary({
    this.pendingCount = 0,
    this.completedCount = 0,
    this.pointsEarned = 0,
  });

  int get totalInvites => pendingCount + completedCount;

  bool get hasActivity => totalInvites > 0 || pointsEarned > 0;
}

class ReferralShareSnapshot {
  final String referralCode;
  final String referralLink;
  final String inviteMessage;
  final CustomerReferralSummary referralSummary;
  final LoyaltySummary loyaltySummary;

  const ReferralShareSnapshot({
    required this.referralCode,
    required this.referralLink,
    required this.inviteMessage,
    required this.referralSummary,
    required this.loyaltySummary,
  });
}

class ProductTraceRecord {
  final String id;
  final String traceCode;
  final String productName;
  final String farmLocation;
  final String harvestDate;
  final String harvestTime;
  final String farmerName;
  final String farmingMethod;
  final String batchNotes;
  final int qrScanCount;

  const ProductTraceRecord({
    required this.id,
    required this.traceCode,
    required this.productName,
    required this.farmLocation,
    required this.harvestDate,
    required this.harvestTime,
    required this.farmerName,
    required this.farmingMethod,
    required this.batchNotes,
    required this.qrScanCount,
  });

  factory ProductTraceRecord.fromSupabase(Map<String, dynamic> data) {
    return ProductTraceRecord(
      id: (data['id'] ?? '').toString(),
      traceCode: (data['trace_code'] ?? '').toString(),
      productName: (data['product_name'] ?? 'Product').toString(),
      farmLocation: (data['farm_location'] ?? '').toString(),
      harvestDate: (data['harvest_date'] ?? '').toString(),
      harvestTime: (data['harvest_time'] ?? '').toString(),
      farmerName: (data['farmer_name'] ?? '').toString(),
      farmingMethod: (data['farming_method'] ?? '100% Natural').toString(),
      batchNotes: (data['batch_notes'] ?? '').toString(),
      qrScanCount: Product._toInt(data['qr_scan_count']),
    );
  }
}

class ProductTraceOverviewItem {
  final Product product;
  final List<ProductTraceRecord> records;

  const ProductTraceOverviewItem({
    required this.product,
    required this.records,
  });
}

class Product {
  final String id;
  final String name;
  final double price;
  final String category;
  final String? description;
  final String? unit;
  final String? imageUrl;
  final int stockQuantity;
  final bool isAvailable;
  final bool isOrganic;
  final bool isLocal;
  final DateTime? harvestDate;
  final DateTime? createdAt;
  final String? farmerId;
  final String? farmerName;
  final String? farmName;
  final String? parish;
  final String approvalStatus;
  final double platformCommissionPercent;
  final double? originalPrice;
  final double? discountPrice;
  final double? discountPercent;
  final String? discountLabel;
  final DateTime? discountStartsAt;
  final DateTime? discountEndsAt;
  final bool isDiscountActive;
  final String productStatus;
  final bool readySoon;
  final DateTime? estimatedReadyDate;
  final int? expectedStockQuantity;
  final bool isDealOfDay;
  final int dealRank;
  final bool subscribeSaveEnabled;
  final double subscribeSaveDiscountPercent;
  final List<String> nutrientStrong;
  final List<String> nutrientGood;
  final List<String> nutrientContains;
  final String? nutritionNotes;
  final String? nutritionSource;
  final bool nutritionVerified;
  final String? usdaFdcId;
  final double servingSizeG;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    this.description,
    this.unit,
    this.imageUrl,
    this.stockQuantity = 0,
    this.isAvailable = true,
    this.isOrganic = false,
    this.isLocal = true,
    this.harvestDate,
    this.createdAt,
    this.farmerId,
    this.farmerName,
    this.farmName,
    this.parish,
    this.approvalStatus = 'approved',
    this.platformCommissionPercent = 10,
    this.originalPrice,
    this.discountPrice,
    this.discountPercent,
    this.discountLabel,
    this.discountStartsAt,
    this.discountEndsAt,
    this.isDiscountActive = false,
    this.productStatus = 'available',
    this.readySoon = false,
    this.estimatedReadyDate,
    this.expectedStockQuantity,
    this.isDealOfDay = false,
    this.dealRank = 999,
    this.subscribeSaveEnabled = false,
    this.subscribeSaveDiscountPercent = 5,
    this.nutrientStrong = const <String>[],
    this.nutrientGood = const <String>[],
    this.nutrientContains = const <String>[],
    this.nutritionNotes,
    this.nutritionSource,
    this.nutritionVerified = false,
    this.usdaFdcId,
    this.servingSizeG = 100,
  });

  double get originalPriceValue {
    final base =
        originalPrice == null || originalPrice! <= 0 ? price : originalPrice!;
    return base < 0 ? 0 : base;
  }

  bool get hasActiveDiscount {
    if (!isDiscountActive) return false;
    final now = DateTime.now();
    if (discountStartsAt != null && now.isBefore(discountStartsAt!))
      return false;
    if (discountEndsAt != null && now.isAfter(discountEndsAt!)) return false;
    return effectivePrice < originalPriceValue;
  }

  double get effectivePrice {
    final original = originalPriceValue;
    double candidate = price;

    if (discountPrice != null) {
      candidate = discountPrice!;
    } else if (discountPercent != null && discountPercent! > 0) {
      final percent = discountPercent!.clamp(0, 100).toDouble();
      candidate = original * (1 - (percent / 100));
    }

    if (!isDiscountActive) return price < 0 ? 0 : price;
    if (candidate < 0) return 0;
    if (candidate > original) return original;
    return candidate;
  }

  String get formattedPrice => formatJmd(effectivePrice);
  String get formattedEffectivePrice => formatJmd(effectivePrice);
  String get formattedOriginalPrice => formatJmd(originalPriceValue);
  String get originLabel => isLocal ? 'Local' : 'Not Local';

  int get discountPercentDisplay {
    if (!hasActiveDiscount || originalPriceValue <= 0) return 0;
    final percent =
        ((originalPriceValue - effectivePrice) / originalPriceValue * 100)
            .round();
    return percent.clamp(0, 100).toInt();
  }

  bool get isReadySoon =>
      readySoon || productStatus.trim().toLowerCase() == 'ready_soon';
  bool get isHidden => productStatus.trim().toLowerCase() == 'hidden';
  bool get isApproved => approvalStatus.trim().toLowerCase() == 'approved';
  bool get isCustomerVisible => isApproved && !isHidden && !isReadySoon;
  bool get isOutOfStock =>
      isCustomerVisible && (!isAvailable || stockQuantity <= 0);
  bool get canAddToCart =>
      isCustomerVisible && isAvailable && stockQuantity > 0;

  bool get isLowStock =>
      canAddToCart && stockQuantity > 0 && stockQuantity <= 5;

  String get lowStockLabel {
    if (!isLowStock) return '';
    if (stockQuantity == 1) return 'Only 1 left';
    return 'Only $stockQuantity left';
  }

  bool get hasSubscribeSave => subscribeSaveEnabled && canAddToCart;

  double get subscribeSavePercentValue {
    final value = subscribeSaveDiscountPercent <= 0
        ? 5.0
        : subscribeSaveDiscountPercent.clamp(0, 50).toDouble();
    return value;
  }

  double get subscribeSavePrice {
    final price = effectivePrice * (1 - subscribeSavePercentValue / 100);
    if (price < 0) return 0;
    return price;
  }

  String get formattedSubscribeSavePrice => formatJmd(subscribeSavePrice);

  static String _cleanNutrientKey(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  List<String> get allNutrientTags {
    final tags = <String>{
      ...nutrientStrong.map(_cleanNutrientKey),
      ...nutrientGood.map(_cleanNutrientKey),
      ...nutrientContains.map(_cleanNutrientKey),
    }..removeWhere((value) => value.isEmpty);

    return tags.toList()..sort();
  }

  bool get hasNutritionTags => allNutrientTags.isNotEmpty;

  int nutrientLevelRank(String nutrient) {
    final key = _cleanNutrientKey(nutrient);
    if (key.isEmpty) return 0;

    if (nutrientStrong.map(_cleanNutrientKey).contains(key)) return 3;
    if (nutrientGood.map(_cleanNutrientKey).contains(key)) return 2;
    if (nutrientContains.map(_cleanNutrientKey).contains(key)) return 1;
    return 0;
  }

  String nutrientLevelLabel(String nutrient) {
    switch (nutrientLevelRank(nutrient)) {
      case 3:
        return 'Strong source';
      case 2:
        return 'Good source';
      case 1:
        return 'Contains';
      default:
        return '';
    }
  }

  String nutrientBadgeLabel(String nutrient) {
    final clean = nutrient.trim();
    final level = nutrientLevelLabel(nutrient);
    if (clean.isEmpty || level.isEmpty) return '';
    return '$level of $clean';
  }

  bool get showAsDealOfDay {
    final label = (discountLabel ?? '').toLowerCase();
    return isDealOfDay ||
        label.contains('deal of the day') ||
        label.contains('today');
  }

  String get readySoonLabel {
    if (estimatedReadyDate != null) {
      return 'Available from ${shortProductDate(estimatedReadyDate)}';
    }
    if (isReadySoon) return 'Harvesting soon';
    return 'Notify me when available';
  }

  factory Product.fromSupabase(Map<String, dynamic> data) {
    final name = (data['name'] ?? 'Product').toString();
    final categoryName = normalizeProductCategory(
      data['category'] ??
          data['product_category'] ??
          (data['categories'] is Map ? data['categories']['name'] : null) ??
          'Vegetables',
    );

    final cleanImageUrl = cleanHostedImageUrl(data['image_url']?.toString());

    final status = (data['product_status'] ?? 'available').toString();
    final readySoonValue = data['ready_soon'] == true || status == 'ready_soon';

    return Product(
      id: (data['id'] ?? '').toString(),
      name: name,
      price: _toDouble(data['price']),
      category: categoryName,
      description: data['description']?.toString(),
      unit: data['unit']?.toString(),
      imageUrl: cleanImageUrl,
      stockQuantity: _toInt(data['stock_quantity']),
      isAvailable:
          data['is_available'] == null ? true : data['is_available'] == true,
      isOrganic: data['is_organic'] == true || data['organic'] == true,
      isLocal: data['is_local'] == null ? true : data['is_local'] == true,
      harvestDate: parseProductDate(data['harvest_date']),
      createdAt: parseProductDate(data['created_at']),
      farmerId: data['farmer_id']?.toString(),
      farmerName: data['farmer_name']?.toString(),
      farmName: data['farm_name']?.toString(),
      parish: data['parish']?.toString(),
      approvalStatus: (data['approval_status'] ?? 'approved').toString(),
      platformCommissionPercent:
          _toDouble(data['platform_commission_percent'] ?? 10),
      originalPrice: parseNullableDouble(data['original_price']),
      discountPrice: parseNullableDouble(data['discount_price']),
      discountPercent: parseNullableDouble(data['discount_percent']),
      discountLabel: data['discount_label']?.toString(),
      discountStartsAt: parseProductDate(data['discount_starts_at']),
      discountEndsAt: parseProductDate(data['discount_ends_at']),
      isDiscountActive: data['is_discount_active'] == true,
      productStatus: status,
      readySoon: readySoonValue,
      estimatedReadyDate: parseProductDate(data['estimated_ready_date']),
      expectedStockQuantity: data['expected_stock_quantity'] == null
          ? null
          : _toInt(data['expected_stock_quantity']),
      isDealOfDay: data['is_deal_of_day'] == true,
      dealRank: _toInt(data['deal_rank'] ?? 999),
      subscribeSaveEnabled: data['subscribe_save_enabled'] == true,
      subscribeSaveDiscountPercent:
          parseNullableDouble(data['subscribe_save_discount_percent']) ?? 5,
      nutrientStrong: _toStringList(data['nutrient_strong']),
      nutrientGood: _toStringList(data['nutrient_good']),
      nutrientContains: _toStringList(data['nutrient_contains']),
      nutritionNotes: data['nutrition_notes']?.toString(),
      nutritionSource: data['nutrition_source']?.toString(),
      nutritionVerified: data['nutrition_verified'] == true,
      usdaFdcId: data['usda_fdc_id']?.toString(),
      servingSizeG: _toDouble(data['serving_size_g'] ?? 100),
    );
  }

  static List<String> _toStringList(dynamic value) {
    if (value == null) return const <String>[];

    Iterable<dynamic> rawItems;

    if (value is Iterable) {
      rawItems = value;
    } else {
      final raw = value.toString().trim();

      if (raw.isEmpty || raw == '{}') return const <String>[];

      rawItems = raw
          .replaceAll('{', '')
          .replaceAll('}', '')
          .replaceAll('[', '')
          .replaceAll(']', '')
          .split(',');
    }

    final clean = rawItems
        .map((item) => item.toString().trim().toLowerCase())
        .map((item) => item.replaceAll(RegExp(r'^"|"$'), ''))
        .map((item) => item.replaceAll(RegExp(r"^'|'$"), ''))
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    return clean;
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '0') ?? 0;
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '0') ?? 0;
  }
}

class FarmOrder {
  final String id;
  final String status;
  final String fulfillmentType;
  final double subtotal;
  final double deliveryFee;
  final double discountAmount;
  final double total;
  final String paymentStatus;
  final String paymentMethod;
  final DateTime? createdAt;

  const FarmOrder({
    required this.id,
    required this.status,
    required this.fulfillmentType,
    this.subtotal = 0,
    this.deliveryFee = 0,
    this.discountAmount = 0,
    required this.total,
    required this.paymentStatus,
    required this.paymentMethod,
    this.createdAt,
  });

  String get shortId => shortIdLabel(id);

  String get formattedTotal => formatJmd(total);

  String get formattedPaymentStatus => formatPaymentStatusForMethod(
        paymentMethod: paymentMethod,
        paymentStatus: paymentStatus,
      );

  String get formattedPaymentMethod => formatPaymentMethod(paymentMethod);

  String get formattedType => formatFulfillmentType(fulfillmentType);

  factory FarmOrder.fromSupabase(Map<String, dynamic> data) {
    final fulfillment = (data['fulfillment_type'] ?? 'pickup').toString();
    final notes = data['notes']?.toString();
    final subtotal = Product._toDouble(data['subtotal']);
    final deliveryFee = resolvedDeliveryFeeForOrder(
      fulfillmentType: fulfillment,
      rawDeliveryFee: Product._toDouble(data['delivery_fee']),
      notes: notes,
    );
    final discountAmount = Product._toDouble(data['discount_amount']) > 0
        ? Product._toDouble(data['discount_amount'])
        : moneyAmountFromText(notes, 'Discount');
    final total = resolvedOrderTotal(
      fulfillmentType: fulfillment,
      rawTotal: Product._toDouble(data['total']),
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      discountAmount: discountAmount,
    );

    return FarmOrder(
      id: (data['id'] ?? '').toString(),
      status: (data['order_status'] ?? 'pending').toString(),
      fulfillmentType: fulfillment,
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      discountAmount: discountAmount,
      total: total,
      paymentStatus: (data['payment_status'] ?? 'unpaid').toString(),
      paymentMethod: (data['payment_method'] ?? 'cash_on_pickup').toString(),
      createdAt: DateTime.tryParse((data['created_at'] ?? '').toString()),
    );
  }
}

class FarmNotification {
  final String id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime? createdAt;
  final String? orderId;

  const FarmNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    this.createdAt,
    this.orderId,
  });

  String get timeLabel => formatCustomerDateTime(createdAt);

  bool get hasOrderLink =>
      (orderId ?? '').trim().isNotEmpty ||
      notificationOrderShortId(this) != null;

  IconData get icon {
    switch (type) {
      case 'payment':
        return Icons.verified_outlined;
      case 'delivery':
        return Icons.local_shipping_outlined;
      case 'product_ready':
        return Icons.inventory_2_outlined;
      case 'stock':
        return Icons.warning_amber_outlined;
      case 'support':
        return Icons.support_agent_outlined;
      case 'review':
        return Icons.rate_review_outlined;
      case 'admin':
        return Icons.admin_panel_settings_outlined;
      default:
        return Icons.notifications_none;
    }
  }

  factory FarmNotification.fromSupabase(Map<String, dynamic> data) {
    return FarmNotification(
      id: (data['id'] ?? '').toString(),
      title: (data['title'] ?? 'Notification').toString(),
      message: (data['message'] ?? '').toString(),
      type: (data['type'] ?? 'order').toString(),
      isRead: data['is_read'] == true,
      createdAt: DateTime.tryParse((data['created_at'] ?? '').toString()),
      orderId: data['order_id']?.toString(),
    );
  }
}

class NotificationTarget {
  final String? userId;
  final String? userEmail;

  const NotificationTarget({this.userId, this.userEmail});

  bool get hasTarget {
    return (userId != null && userId!.trim().isNotEmpty) ||
        (userEmail != null && userEmail!.trim().isNotEmpty);
  }
}

class CustomerProductSubscription {
  final String id;
  final String userId;
  final String userEmail;
  final String productId;
  final String productName;
  final int intervalDays;
  final double discountPercent;
  final DateTime? nextOrderDate;
  final String status;
  final DateTime? createdAt;

  const CustomerProductSubscription({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.productId,
    required this.productName,
    required this.intervalDays,
    required this.discountPercent,
    required this.nextOrderDate,
    required this.status,
    this.createdAt,
  });

  bool get isActive => status.trim().toLowerCase() == 'active';
  bool get isPaused => status.trim().toLowerCase() == 'paused';
  String get repeatLabel => repeatIntervalLabel(intervalDays);
  String get savingsLabel => '${discountPercent.toStringAsFixed(0)}% savings';
  String get nextOrderLabel => formatPlanDate(nextOrderDate);

  factory CustomerProductSubscription.fromSupabase(Map<String, dynamic> data) {
    return CustomerProductSubscription(
      id: (data['id'] ?? '').toString(),
      userId: (data['user_id'] ?? '').toString(),
      userEmail: (data['user_email'] ?? '').toString(),
      productId: (data['product_id'] ?? '').toString(),
      productName: (data['product_name'] ?? 'Product').toString(),
      intervalDays: Product._toInt(data['interval_days'] ?? 7),
      discountPercent: parseNullableDouble(data['discount_percent']) ?? 0,
      nextOrderDate: parseProductDate(data['next_order_date']),
      status: (data['status'] ?? 'active').toString(),
      createdAt: parseProductDate(data['created_at']),
    );
  }
}

class OrderDetailsItem {
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double lineTotal;

  const OrderDetailsItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });

  factory OrderDetailsItem.fromSupabase(Map<String, dynamic> data) {
    return OrderDetailsItem(
      productId: (data['product_id'] ?? '').toString(),
      productName: (data['product_name'] ?? 'Product').toString(),
      quantity: Product._toInt(data['quantity']),
      unitPrice: Product._toDouble(data['unit_price']),
      lineTotal: Product._toDouble(data['line_total']),
    );
  }
}

class OrderDetails {
  final String id;
  final String status;
  final String fulfillmentType;
  final String paymentStatus;
  final String paymentMethod;
  final double subtotal;
  final double deliveryFee;
  final double discountAmount;
  final double total;
  final String? deliveryAddress;
  final String? deliveryZone;
  final String? scheduledDate;
  final String? scheduledTime;
  final String? notes;
  final DateTime? createdAt;
  final List<OrderDetailsItem> items;

  const OrderDetails({
    required this.id,
    required this.status,
    required this.fulfillmentType,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.subtotal,
    required this.deliveryFee,
    this.discountAmount = 0,
    required this.total,
    this.deliveryAddress,
    this.deliveryZone,
    this.scheduledDate,
    this.scheduledTime,
    this.notes,
    this.createdAt,
    required this.items,
  });

  String get shortId => shortIdLabel(id);
  String get formattedTotal => formatJmd(total);
  String get formattedSubtotal => formatJmd(subtotal);
  String get formattedDeliveryFee => formatJmd(deliveryFee);
  String get formattedDiscountAmount => formatJmd(discountAmount);

  String get formattedPaymentStatus => formatPaymentStatusForMethod(
        paymentMethod: paymentMethod,
        paymentStatus: paymentStatus,
      );

  String get formattedOrderStatus => friendlyLabel(status);

  String get formattedPaymentMethod => formatPaymentMethod(paymentMethod);

  String get formattedType => formatFulfillmentType(fulfillmentType);

  String get scheduleText => formatScheduleText(scheduledDate, scheduledTime);

  factory OrderDetails.fromSupabase(Map<String, dynamic> data) {
    final rawItems = data['order_items'];
    final parsedItems = rawItems is List
        ? rawItems
            .map((item) => OrderDetailsItem.fromSupabase(
                  Map<String, dynamic>.from(item as Map),
                ))
            .toList()
        : <OrderDetailsItem>[];

    final fulfillment = (data['fulfillment_type'] ?? 'pickup').toString();
    final notes = data['notes']?.toString();
    final itemSubtotal = parsedItems.fold<double>(
      0,
      (sum, item) => sum + item.lineTotal,
    );
    final rawSubtotal = Product._toDouble(data['subtotal']);
    final subtotal = rawSubtotal > 0 ? rawSubtotal : itemSubtotal;
    final deliveryFee = resolvedDeliveryFeeForOrder(
      fulfillmentType: fulfillment,
      rawDeliveryFee: Product._toDouble(data['delivery_fee']),
      notes: notes,
    );
    final rawDiscount = Product._toDouble(data['discount_amount']);
    final discountAmount =
        rawDiscount > 0 ? rawDiscount : moneyAmountFromText(notes, 'Discount');
    final total = resolvedOrderTotal(
      fulfillmentType: fulfillment,
      rawTotal: Product._toDouble(data['total']),
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      discountAmount: discountAmount,
    );

    return OrderDetails(
      id: (data['id'] ?? '').toString(),
      status: (data['order_status'] ?? 'pending').toString(),
      fulfillmentType: fulfillment,
      paymentStatus: (data['payment_status'] ?? 'unpaid').toString(),
      paymentMethod: (data['payment_method'] ?? 'cash_on_pickup').toString(),
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      discountAmount: discountAmount,
      total: total,
      deliveryAddress: data['delivery_address']?.toString(),
      deliveryZone: data['delivery_zone']?.toString(),
      scheduledDate: data['scheduled_date']?.toString(),
      scheduledTime: data['scheduled_time']?.toString(),
      notes: notes,
      createdAt: DateTime.tryParse((data['created_at'] ?? '').toString()),
      items: parsedItems,
    );
  }
}

class AuditLogEntry {
  final String id;
  final String actorUserId;
  final String action;
  final String tableName;
  final String recordId;
  final Map<String, dynamic> metadata;
  final DateTime? createdAt;

  const AuditLogEntry({
    required this.id,
    required this.actorUserId,
    required this.action,
    required this.tableName,
    required this.recordId,
    required this.metadata,
    required this.createdAt,
  });

  factory AuditLogEntry.fromMap(Map<String, dynamic> data) {
    return AuditLogEntry(
      id: (data['id'] ?? '').toString(),
      actorUserId: (data['actor_user_id'] ?? '').toString(),
      action: (data['action'] ?? '').toString(),
      tableName: (data['table_name'] ?? '').toString(),
      recordId: (data['record_id'] ?? '').toString(),
      metadata: data['metadata'] is Map
          ? Map<String, dynamic>.from(data['metadata'] as Map)
          : <String, dynamic>{},
      createdAt: DateTime.tryParse((data['created_at'] ?? '').toString()),
    );
  }

  String get formattedAction => friendlyLabel(action);
  String get shortRecordId =>
      recordId.trim().isEmpty ? 'N/A' : shortIdLabel(recordId);

  String get shortActorId => actorUserId.trim().isEmpty
      ? 'Unknown'
      : shortIdLabel(actorUserId, length: 8);
}

class AdminOrder {
  final String id;
  final String status;
  final String fulfillmentType;
  final double subtotal;
  final double deliveryFee;
  final double discountAmount;
  final double total;
  final String paymentStatus;
  final String paymentMethod;
  final DateTime? createdAt;
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final String? bankReference;
  final String? deliveryStatus;
  final String? deliveryAddress;
  final String? deliveryZone;
  final String? scheduledDate;
  final String? scheduledTime;
  final List<AdminOrderItem> items;

  const AdminOrder({
    required this.id,
    required this.status,
    required this.fulfillmentType,
    this.subtotal = 0,
    this.deliveryFee = 0,
    this.discountAmount = 0,
    required this.total,
    required this.paymentStatus,
    required this.paymentMethod,
    this.createdAt,
    required this.customerName,
    required this.customerPhone,
    required this.customerAddress,
    this.bankReference,
    this.deliveryStatus,
    this.deliveryAddress,
    this.deliveryZone,
    this.scheduledDate,
    this.scheduledTime,
    required this.items,
  });

  String get shortId => shortIdLabel(id);

  String get formattedTotal => formatJmd(total);
  String get formattedSubtotal => formatJmd(subtotal);
  String get formattedDeliveryFee => formatJmd(deliveryFee);
  String get formattedDiscountAmount => formatJmd(discountAmount);

  String get formattedPaymentStatus => formatPaymentStatusForMethod(
        paymentMethod: paymentMethod,
        paymentStatus: paymentStatus,
      );

  String get formattedPaymentMethod => formatPaymentMethod(paymentMethod);

  String get formattedType => formatFulfillmentType(fulfillmentType);

  String get formattedDeliveryStatus {
    return friendlyLabel(deliveryStatus ?? 'pending');
  }

  String get scheduleText => formatScheduleText(scheduledDate, scheduledTime);

  factory AdminOrder.fromSupabase(Map<String, dynamic> data) {
    final customerData = data['customers'];
    final customer = customerData is Map<String, dynamic>
        ? customerData
        : customerData is Map
            ? Map<String, dynamic>.from(customerData)
            : <String, dynamic>{};

    final rawItems = data['order_items'];
    final parsedItems = rawItems is List
        ? rawItems
            .map((item) => AdminOrderItem.fromSupabase(
                  Map<String, dynamic>.from(item as Map),
                ))
            .toList()
        : <AdminOrderItem>[];

    final fulfillment = (data['fulfillment_type'] ?? 'pickup').toString();
    final notes = data['notes']?.toString();
    final itemSubtotal = parsedItems.fold<double>(
      0,
      (sum, item) => sum + item.lineTotal,
    );
    final rawSubtotal = Product._toDouble(data['subtotal']);
    final subtotal = rawSubtotal > 0 ? rawSubtotal : itemSubtotal;
    final deliveryFee = resolvedDeliveryFeeForOrder(
      fulfillmentType: fulfillment,
      rawDeliveryFee: Product._toDouble(data['delivery_fee']),
      notes: notes,
    );
    final rawDiscount = Product._toDouble(data['discount_amount']);
    final discountAmount =
        rawDiscount > 0 ? rawDiscount : moneyAmountFromText(notes, 'Discount');
    final total = resolvedOrderTotal(
      fulfillmentType: fulfillment,
      rawTotal: Product._toDouble(data['total']),
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      discountAmount: discountAmount,
    );

    return AdminOrder(
      id: (data['id'] ?? '').toString(),
      status: (data['order_status'] ?? 'pending').toString(),
      fulfillmentType: fulfillment,
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      discountAmount: discountAmount,
      total: total,
      paymentStatus: (data['payment_status'] ?? 'unpaid').toString(),
      paymentMethod: (data['payment_method'] ?? 'cash_on_pickup').toString(),
      createdAt: DateTime.tryParse((data['created_at'] ?? '').toString()),
      customerName: (customer['full_name'] ?? 'Customer').toString(),
      customerPhone: (customer['phone'] ?? '').toString(),
      customerAddress: (customer['address'] ?? '').toString(),
      bankReference: data['bank_reference']?.toString(),
      deliveryStatus: data['delivery_status']?.toString(),
      deliveryAddress: data['delivery_address']?.toString(),
      deliveryZone: data['delivery_zone']?.toString(),
      scheduledDate: data['scheduled_date']?.toString(),
      scheduledTime: data['scheduled_time']?.toString(),
      items: parsedItems,
    );
  }
}

class AdminOrderItem {
  final String productName;
  final int quantity;
  final double lineTotal;

  const AdminOrderItem({
    required this.productName,
    required this.quantity,
    required this.lineTotal,
  });

  factory AdminOrderItem.fromSupabase(Map<String, dynamic> data) {
    return AdminOrderItem(
      productName: (data['product_name'] ?? 'Product').toString(),
      quantity: Product._toInt(data['quantity']),
      lineTotal: Product._toDouble(data['line_total']),
    );
  }
}

class CustomerProfile {
  final String? id;
  final String fullName;
  final String phone;
  final String address;

  const CustomerProfile({
    this.id,
    required this.fullName,
    required this.phone,
    required this.address,
  });

  factory CustomerProfile.fromSupabase(Map<String, dynamic> data) {
    return CustomerProfile(
      id: data['id']?.toString(),
      fullName: (data['full_name'] ?? '').toString(),
      phone: (data['phone'] ?? '').toString(),
      address: (data['address'] ?? '').toString(),
    );
  }
}

/*
Suggested Supabase marketplace tables:

farmer_profiles:
- id uuid primary key
- user_id uuid
- email text
- farm_name text
- farmer_name text
- phone text
- parish text
- address text
- bio text
- verification_status text default 'pending'
- payout_method text
- payout_details text
- created_at timestamp

farmer_payouts:
- id uuid primary key
- farmer_id uuid
- order_id uuid
- gross_amount numeric
- commission_amount numeric
- net_amount numeric
- payout_status text default 'pending'
- payout_method text
- payout_reference text
- released_at timestamp
- created_at timestamp

products additional columns:
- farmer_id uuid
- farmer_name text
- farm_name text
- parish text
- approval_status text default 'approved'
- platform_commission_percent numeric default 10

order_items additional columns:
- farmer_id uuid
- farmer_name text
- farm_name text
- commission_amount numeric
- farmer_earning_amount numeric
*/

class FarmerProfile {
  final String id;
  final String userId;
  final String email;
  final String farmName;
  final String farmerName;
  final String phone;
  final String parish;
  final String address;
  final String bio;
  final String verificationStatus;
  final String payoutMethod;
  final String payoutDetails;
  final DateTime? createdAt;

  const FarmerProfile({
    required this.id,
    required this.userId,
    required this.email,
    required this.farmName,
    required this.farmerName,
    required this.phone,
    required this.parish,
    required this.address,
    required this.bio,
    required this.verificationStatus,
    required this.payoutMethod,
    required this.payoutDetails,
    this.createdAt,
  });

  bool get isApproved => verificationStatus == 'approved';
  String get statusLabel => _friendlyStatus(verificationStatus);

  factory FarmerProfile.fromSupabase(Map<String, dynamic> data) {
    return FarmerProfile(
      id: (data['id'] ?? '').toString(),
      userId: (data['user_id'] ?? '').toString(),
      email: (data['email'] ?? '').toString(),
      farmName: (data['farm_name'] ?? 'Farm').toString(),
      farmerName: (data['farmer_name'] ?? 'Farmer').toString(),
      phone: (data['phone'] ?? '').toString(),
      parish: (data['parish'] ?? '').toString(),
      address: (data['address'] ?? '').toString(),
      bio: (data['bio'] ?? '').toString(),
      verificationStatus: (data['verification_status'] ?? 'pending').toString(),
      payoutMethod: (data['payout_method'] ?? '').toString(),
      payoutDetails: (data['payout_details'] ?? '').toString(),
      createdAt: DateTime.tryParse((data['created_at'] ?? '').toString()),
    );
  }
}

class FarmerPayout {
  final String id;
  final String farmerId;
  final String orderId;
  final double grossAmount;
  final double commissionAmount;
  final double netAmount;
  final String payoutStatus;
  final String payoutMethod;
  final String payoutReference;
  final DateTime? releasedAt;
  final DateTime? createdAt;

  const FarmerPayout({
    required this.id,
    required this.farmerId,
    required this.orderId,
    required this.grossAmount,
    required this.commissionAmount,
    required this.netAmount,
    required this.payoutStatus,
    required this.payoutMethod,
    required this.payoutReference,
    this.releasedAt,
    this.createdAt,
  });

  factory FarmerPayout.fromSupabase(Map<String, dynamic> data) {
    return FarmerPayout(
      id: (data['id'] ?? '').toString(),
      farmerId: (data['farmer_id'] ?? '').toString(),
      orderId: (data['order_id'] ?? '').toString(),
      grossAmount: Product._toDouble(data['gross_amount']),
      commissionAmount: Product._toDouble(data['commission_amount']),
      netAmount: Product._toDouble(data['net_amount']),
      payoutStatus: (data['payout_status'] ?? 'pending').toString(),
      payoutMethod: (data['payout_method'] ?? '').toString(),
      payoutReference: (data['payout_reference'] ?? '').toString(),
      releasedAt: DateTime.tryParse((data['released_at'] ?? '').toString()),
      createdAt: DateTime.tryParse((data['created_at'] ?? '').toString()),
    );
  }
}

class FarmerOrderSummary {
  final String orderId;
  final String productName;
  final int quantity;
  final double lineTotal;
  final double farmerEarningAmount;

  const FarmerOrderSummary({
    required this.orderId,
    required this.productName,
    required this.quantity,
    required this.lineTotal,
    required this.farmerEarningAmount,
  });

  String get shortOrderId =>
      orderId.length <= 6 ? orderId : orderId.substring(0, 6).toUpperCase();

  factory FarmerOrderSummary.fromSupabase(Map<String, dynamic> data) {
    return FarmerOrderSummary(
      orderId: (data['order_id'] ?? '').toString(),
      productName: (data['product_name'] ?? 'Product').toString(),
      quantity: Product._toInt(data['quantity']),
      lineTotal: Product._toDouble(data['line_total']),
      farmerEarningAmount: Product._toDouble(data['farmer_earning_amount']),
    );
  }
}

class Coupon {
  final String id;
  final String code;
  final String discountType;
  final double discountValue;
  final bool isActive;
  final double? minimumOrder;

  const Coupon({
    required this.id,
    required this.code,
    required this.discountType,
    required this.discountValue,
    required this.isActive,
    this.minimumOrder,
  });

  factory Coupon.fromSupabase(Map<String, dynamic> data) {
    return Coupon(
      id: (data['id'] ?? '').toString(),
      code: (data['code'] ?? '').toString(),
      discountType: (data['discount_type'] ?? 'fixed').toString(),
      discountValue: Product._toDouble(data['discount_value']),
      isActive: data['is_active'] == null ? true : data['is_active'] == true,
      minimumOrder: data['minimum_order'] == null
          ? null
          : Product._toDouble(data['minimum_order']),
    );
  }

  double discountFor(double subtotal) {
    if (!isActive) return 0;
    final minimum = minimumOrder ?? 0;
    if (minimum > 0 && subtotal < minimum) return 0;
    if (discountType == 'percent') {
      return subtotal * (discountValue / 100);
    }
    return discountValue > subtotal ? subtotal : discountValue;
  }

  String get label {
    if (discountType == 'percent') {
      return '${discountValue.toStringAsFixed(0)}% off';
    }
    return 'J\$${discountValue.toStringAsFixed(2)} off';
  }
}

class CouponValidationResult {
  final bool valid;
  final String message;
  final String? couponId;
  final String? code;
  final String discountType;
  final double discountValue;
  final double discountAmount;
  final double originalTotal;
  final double finalTotal;

  const CouponValidationResult({
    required this.valid,
    required this.message,
    this.couponId,
    this.code,
    required this.discountType,
    required this.discountValue,
    required this.discountAmount,
    required this.originalTotal,
    required this.finalTotal,
  });

  factory CouponValidationResult.fromMap(Map<String, dynamic> data) {
    return CouponValidationResult(
      valid: data['valid'] == true,
      message: (data['message'] ?? '').toString(),
      couponId: data['coupon_id']?.toString(),
      code: data['code']?.toString(),
      discountType: (data['discount_type'] ?? 'fixed').toString(),
      discountValue: Product._toDouble(data['discount_value']),
      discountAmount: Product._toDouble(data['discount_amount']),
      originalTotal: Product._toDouble(data['original_total']),
      finalTotal: Product._toDouble(data['final_total']),
    );
  }

  String get label {
    if (discountType == 'percent') {
      return '${discountValue.toStringAsFixed(0)}% off';
    }
    return 'J\$${discountAmount.toStringAsFixed(2)} off';
  }
}

class SupportTicket {
  final String id;
  final String email;
  final String subject;
  final String message;
  final String status;
  final String? adminReply;
  final DateTime? createdAt;

  const SupportTicket({
    required this.id,
    required this.email,
    required this.subject,
    required this.message,
    required this.status,
    this.adminReply,
    this.createdAt,
  });

  factory SupportTicket.fromSupabase(Map<String, dynamic> data) {
    return SupportTicket(
      id: (data['id'] ?? '').toString(),
      email: (data['email'] ?? '').toString(),
      subject: (data['subject'] ?? 'Support request').toString(),
      message: (data['message'] ?? '').toString(),
      status: (data['status'] ?? 'open').toString(),
      adminReply: data['admin_reply']?.toString(),
      createdAt: DateTime.tryParse((data['created_at'] ?? '').toString()),
    );
  }

  String get formattedStatus => _friendlyStatus(status);
  String get shortId => id.length <= 6 ? id : id.substring(0, 6).toUpperCase();
}

class ProductReview {
  final String id;
  final String productId;
  final String productName;
  final String userId;
  final String customerName;
  final String email;
  final int rating;
  final String comment;
  final DateTime? createdAt;

  const ProductReview({
    required this.id,
    required this.productId,
    required this.productName,
    required this.userId,
    required this.customerName,
    required this.email,
    required this.rating,
    required this.comment,
    this.createdAt,
  });

  factory ProductReview.fromSupabase(Map<String, dynamic> data) {
    final productData = data['products'];
    final product = productData is Map<String, dynamic>
        ? productData
        : productData is Map
            ? Map<String, dynamic>.from(productData)
            : <String, dynamic>{};

    return ProductReview(
      id: (data['id'] ?? '').toString(),
      productId: (data['product_id'] ?? '').toString(),
      productName:
          (product['name'] ?? data['product_name'] ?? 'Product').toString(),
      userId: (data['user_id'] ?? '').toString(),
      customerName: safeReviewDisplayName(
        reviewName: data['customer_name']?.toString(),
        email: data['email']?.toString(),
      ),
      email: (data['email'] ?? '').toString(),
      rating: Product._toInt(data['rating']).clamp(1, 5),
      comment: (data['comment'] ?? '').toString(),
      createdAt: DateTime.tryParse((data['created_at'] ?? '').toString()),
    );
  }

  ProductReview copyWith({String? customerName}) {
    return ProductReview(
      id: id,
      productId: productId,
      productName: productName,
      userId: userId,
      customerName: customerName ?? this.customerName,
      email: email,
      rating: rating,
      comment: comment,
      createdAt: createdAt,
    );
  }
}

class PopularCategorySummary {
  final String name;
  final int availableItemCount;
  final Product previewProduct;

  const PopularCategorySummary({
    required this.name,
    required this.availableItemCount,
    required this.previewProduct,
  });
}

class MiniProduct extends StatelessWidget {
  final Product product;

  const MiniProduct({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    final muted = product.isOutOfStock;

    return Opacity(
      opacity: muted ? 0.82 : 1,
      child: Container(
        width: 128,
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: muted ? FarmColors.cardSoft : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: muted
                ? FarmColors.danger.withOpacity(0.13)
                : FarmColors.line.withOpacity(0.80),
          ),
          boxShadow: [
            BoxShadow(
              color: FarmColors.shadow.withOpacity(muted ? 0.025 : 0.05),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 76,
              width: double.infinity,
              child: Center(
                child: ProductVisual(
                  product: product,
                  size: 60,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: FarmColors.ink,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              product.formattedPrice,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: FarmColors.green,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            ProductAvailabilityChip(
              product: product,
              compact: true,
            ),
          ],
        ),
      ),
    );
  }
}
