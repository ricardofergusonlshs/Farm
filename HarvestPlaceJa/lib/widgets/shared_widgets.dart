part of harvest_place_app;

class EliteGreenHeroCard extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final IconData? icon;
  final List<String> chips;
  final EdgeInsetsGeometry padding;

  const EliteGreenHeroCard({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    this.icon,
    this.chips = const [],
    this.padding = const EdgeInsets.all(17),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: FarmColors.primaryDark.withOpacity(0.18),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      FarmColors.primaryDark,
                      FarmColors.primary,
                      FarmColors.olive.withOpacity(0.90),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: -54,
              right: -42,
              child: Container(
                height: 142,
                width: 142,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.075),
                ),
              ),
            ),
            Positioned(
              bottom: -66,
              left: -46,
              child: Container(
                height: 150,
                width: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: FarmColors.accent.withOpacity(0.12),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: Colors.white.withOpacity(0.12)),
                  ),
                ),
              ),
            ),
            Padding(
              padding: padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 34,
                        height: 4,
                        decoration: BoxDecoration(
                          color: FarmColors.accent.withOpacity(0.90),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          eyebrow.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.74),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.15,
                          ),
                        ),
                      ),
                      if (icon != null) ...[
                        const SizedBox(width: 7),
                        Container(
                          height: 38,
                          width: 38,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.16),
                            ),
                          ),
                          child: Icon(icon, color: Colors.white, size: 21),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.65,
                      height: 1.04,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.84),
                      fontSize: 14.2,
                      fontWeight: FontWeight.w700,
                      height: 1.34,
                    ),
                  ),
                  if (chips.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: chips
                          .map((chip) => EliteGreenHeroPill(label: chip))
                          .toList(),
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

class EliteGreenHeroPill extends StatelessWidget {
  final String label;

  const EliteGreenHeroPill({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.16)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11.5,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

String _contentTypeForImage(PickedProductImage image) {
  final cleanType = image.mimeType.trim();
  if (cleanType.startsWith('image/')) return cleanType;

  final lowerName = image.fileName.toLowerCase();
  if (lowerName.endsWith('.png')) return 'image/png';
  if (lowerName.endsWith('.webp')) return 'image/webp';
  if (lowerName.endsWith('.gif')) return 'image/gif';
  return 'image/jpeg';
}

class ProductOriginBadge extends StatelessWidget {
  final Product product;
  final bool compact;
  final bool includeIcon;

  const ProductOriginBadge({
    super.key,
    required this.product,
    this.compact = true,
    this.includeIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = productOriginColor(product);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: productOriginBackground(product),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (includeIcon) ...[
            Icon(productOriginIcon(product),
                size: compact ? 12 : 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            product.originLabel,
            style: TextStyle(
              color: color,
              fontSize: compact ? 10.8 : 12,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class ProductUnitOriginChip extends StatelessWidget {
  final Product product;
  final bool compact;

  const ProductUnitOriginChip({
    super.key,
    required this.product,
    this.compact = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = productOriginColor(product);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: productOriginBackground(product),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(productOriginIcon(product),
              size: compact ? 12 : 14, color: color),
          const SizedBox(width: 4),
          Text(
            productUnitOriginLabel(product),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: compact ? 10.8 : 12,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class LocalProductSelector extends StatelessWidget {
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const LocalProductSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  Widget _option({
    required bool optionValue,
    required String label,
    required IconData icon,
  }) {
    final selected = value == optionValue;
    final color = optionValue ? FarmColors.green : FarmColors.warning;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: enabled ? () => onChanged(optionValue) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(0.13) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? color.withOpacity(0.42) : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16, color: selected ? color : FarmColors.mutedText),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? color : FarmColors.mutedText,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
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
    return Opacity(
      opacity: enabled ? 1 : 0.62,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 7),
            child: Text(
              'Origin',
              style: TextStyle(
                color: FarmColors.mutedText,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: FarmColors.cardSoft,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: FarmColors.line),
            ),
            child: Row(
              children: [
                _option(
                  optionValue: true,
                  label: 'Local',
                  icon: Icons.eco_outlined,
                ),
                _option(
                  optionValue: false,
                  label: 'Not Local',
                  icon: Icons.public_outlined,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProductTrustBadges extends StatelessWidget {
  final Product product;
  final bool compact;

  const ProductTrustBadges({
    super.key,
    required this.product,
    this.compact = false,
  });

  Widget badge({
    required IconData icon,
    required String label,
    Color color = FarmColors.green,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 5 : 7,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 13 : 15, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: compact ? 11.5 : 12.5,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final badges = <Widget>[
      if (product.isReadySoon)
        badge(
          icon: Icons.schedule_outlined,
          label: 'Harvesting Soon',
          color: FarmColors.warning,
        ),
      if (product.showAsDealOfDay)
        badge(
          icon: Icons.flash_on_outlined,
          label: 'Deal of the Day',
          color: FarmColors.warning,
        ),
      if (product.hasActiveDiscount)
        badge(
          icon: Icons.local_offer_outlined,
          label: '${product.discountPercentDisplay}% Off',
          color: FarmColors.warning,
        ),
      if (product.hasSubscribeSave)
        badge(
          icon: Icons.repeat_outlined,
          label: 'Fresh Box Plan',
          color: FarmColors.success,
        ),
      badge(
        icon: Icons.speed_outlined,
        label: productFreshnessLabel(product),
        color: productFreshnessColor(product),
      ),
    ];

    if (product.isOrganic) {
      badges.add(badge(icon: Icons.eco_outlined, label: 'Organic'));
    }

    badges.add(
      badge(
        icon: productOriginIcon(product),
        label: product.originLabel,
        color: productOriginColor(product),
      ),
    );

    if ((product.farmName ?? '').trim().isNotEmpty ||
        (product.farmerName ?? '').trim().isNotEmpty) {
      badges.add(
          badge(icon: Icons.storefront_outlined, label: 'Farmer Verified'));
    }

    if (product.stockQuantity > 0 && product.stockQuantity <= 5) {
      badges.add(
        badge(
          icon: Icons.local_fire_department_outlined,
          label: 'Limited Stock',
          color: FarmColors.gold,
        ),
      );
    }

    if (isProductHarvestedThisWeek(product)) {
      badges.add(
          badge(icon: Icons.agriculture_outlined, label: 'Recently Harvested'));
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: badges,
    );
  }
}

class FreshnessScoreCard extends StatelessWidget {
  final Product product;

  const FreshnessScoreCard({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    return FarmCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: FarmColors.primarySoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.kitchen_outlined,
              color: FarmColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'How to Store',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: FarmColors.text,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  productStorageTip(product),
                  style: const TextStyle(
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
    );
  }
}

class ProductTraceStoryCard extends StatelessWidget {
  final Product product;

  const ProductTraceStoryCard({super.key, required this.product});

  String get farmSource {
    final parts = <String>[
      if ((product.farmName ?? '').trim().isNotEmpty) product.farmName!.trim(),
      if ((product.parish ?? '').trim().isNotEmpty) product.parish!.trim(),
    ];
    return parts.isEmpty
        ? 'The Harvest Place Ja partner farm'
        : parts.join(' • ');
  }

  Widget _pill({
    required IconData icon,
    required String label,
    Color color = FarmColors.green,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _traceLine({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 32,
          width: 32,
          decoration: BoxDecoration(
            color: FarmColors.lightGreen,
            shape: BoxShape.circle,
            border: Border.all(color: FarmColors.green.withOpacity(0.12)),
          ),
          child: Icon(icon, size: 17, color: FarmColors.green),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: FarmColors.mutedText,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value.trim().isEmpty ? 'Not provided yet' : value.trim(),
                style: const TextStyle(
                  color: FarmColors.ink,
                  fontWeight: FontWeight.w900,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _fallbackStory() {
    return FarmCard(
      padding: const EdgeInsets.all(16),
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
                  color: FarmColors.lightGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.verified_user_outlined,
                    color: FarmColors.green),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'From the Farm',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Sourced through The Harvest Place Ja partner farm network.',
                      style: TextStyle(
                        color: FarmColors.mutedText,
                        height: 1.32,
                        fontWeight: FontWeight.w600,
                      ),
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
              _pill(icon: Icons.storefront_outlined, label: farmSource),
              _pill(icon: Icons.category_outlined, label: product.category),
              _pill(
                  icon: productOriginIcon(product), label: product.originLabel),
            ],
          ),
        ],
      ),
    );
  }

  Widget _verifiedStory(BuildContext context, ProductTraceRecord record) {
    final harvestText = [
      if (record.harvestDate.trim().isNotEmpty) record.harvestDate.trim(),
      if (record.harvestTime.trim().isNotEmpty) record.harvestTime.trim(),
    ].join(' • ');

    return FarmCard(
      padding: const EdgeInsets.all(16),
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
                  color: FarmColors.green,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: FarmColors.green.withOpacity(0.18),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(Icons.verified_outlined, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Verified Farm Trace',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      record.traceCode.trim().isEmpty
                          ? 'Source record verified for this harvest.'
                          : 'Batch ${record.traceCode.trim()} • source verified',
                      style: const TextStyle(
                        color: FarmColors.mutedText,
                        height: 1.28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: FarmColors.background,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: FarmColors.line),
            ),
            child: Column(
              children: [
                _traceLine(
                  icon: Icons.location_on_outlined,
                  title: 'Farm location',
                  value: record.farmLocation.isNotEmpty
                      ? record.farmLocation
                      : farmSource,
                ),
                const SizedBox(height: 12),
                _traceLine(
                  icon: Icons.calendar_month_outlined,
                  title: 'Harvested',
                  value: harvestText.isEmpty
                      ? 'Harvest details available soon'
                      : harvestText,
                ),
                const SizedBox(height: 12),
                _traceLine(
                  icon: Icons.eco_outlined,
                  title: 'Growing method',
                  value: record.farmingMethod,
                ),
                if (record.batchNotes.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _traceLine(
                    icon: Icons.notes_outlined,
                    title: 'Batch notes',
                    value: record.batchNotes,
                  ),
                ],
              ],
            ),
          ),
          if (record.traceCode.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _pill(
              icon: Icons.qr_code_2_outlined,
              label: 'Verified batch ${record.traceCode.trim()}',
              color: FarmColors.green,
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ProductTraceRecord>>(
      future: traceRecordsForProduct(product),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return FarmCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: const [
                SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Loading farm source...',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          );
        }

        final records = snapshot.data ?? const <ProductTraceRecord>[];
        if (records.isEmpty) return _fallbackStory();
        return _verifiedStory(context, records.first);
      },
    );
  }
}

final Set<String> _debugLogOnceKeys = <String>{};

void farmDebugLog(String? message, {int? wrapWidth}) {
  if (kDebugMode) {
    debugPrint(message, wrapWidth: wrapWidth);
  }
}

void debugPrintOnce(String key, String message) {
  if (_debugLogOnceKeys.add(key)) {
    farmDebugLog(message);
  }
}

class FarmDataCache {
  static const Duration productTtl = Duration(minutes: 4);
  static const Duration orderTtl = Duration(minutes: 2);
  static const Duration notificationTtl = Duration(seconds: 45);

  static List<Product>? _products;
  static DateTime? _productsAt;

  static List<Product>? _readySoonProducts;
  static DateTime? _readySoonAt;

  static List<Product>? _deals;
  static DateTime? _dealsAt;

  static List<FarmOrder>? _orders;
  static DateTime? _ordersAt;

  static List<Product>? _buyAgain;
  static DateTime? _buyAgainAt;

  static List<FarmNotification>? _notifications;
  static DateTime? _notificationsAt;

  static bool _fresh(DateTime? savedAt, Duration ttl) {
    if (savedAt == null) return false;
    return DateTime.now().difference(savedAt) < ttl;
  }

  static List<Product>? get products =>
      _fresh(_productsAt, productTtl) ? List<Product>.from(_products!) : null;

  static set products(List<Product>? value) {
    _products = value == null ? null : List<Product>.from(value);
    _productsAt = value == null ? null : DateTime.now();
  }

  static List<Product>? get readySoonProducts =>
      _fresh(_readySoonAt, productTtl)
          ? List<Product>.from(_readySoonProducts!)
          : null;

  static set readySoonProducts(List<Product>? value) {
    _readySoonProducts = value == null ? null : List<Product>.from(value);
    _readySoonAt = value == null ? null : DateTime.now();
  }

  static List<Product>? get deals =>
      _fresh(_dealsAt, productTtl) ? List<Product>.from(_deals!) : null;

  static set deals(List<Product>? value) {
    _deals = value == null ? null : List<Product>.from(value);
    _dealsAt = value == null ? null : DateTime.now();
  }

  static List<FarmOrder>? get orders =>
      _fresh(_ordersAt, orderTtl) ? List<FarmOrder>.from(_orders!) : null;

  static set orders(List<FarmOrder>? value) {
    _orders = value == null ? null : List<FarmOrder>.from(value);
    _ordersAt = value == null ? null : DateTime.now();
  }

  static List<Product>? get buyAgain =>
      _fresh(_buyAgainAt, orderTtl) ? List<Product>.from(_buyAgain!) : null;

  static set buyAgain(List<Product>? value) {
    _buyAgain = value == null ? null : List<Product>.from(value);
    _buyAgainAt = value == null ? null : DateTime.now();
  }

  static List<FarmNotification>? get notifications =>
      _fresh(_notificationsAt, notificationTtl)
          ? List<FarmNotification>.from(_notifications!)
          : null;

  static set notifications(List<FarmNotification>? value) {
    _notifications = value == null ? null : List<FarmNotification>.from(value);
    _notificationsAt = value == null ? null : DateTime.now();
  }

  static void clearProducts() {
    _products = null;
    _productsAt = null;
    _readySoonProducts = null;
    _readySoonAt = null;
    _deals = null;
    _dealsAt = null;
  }

  static void clearOrders() {
    _orders = null;
    _ordersAt = null;
    _buyAgain = null;
    _buyAgainAt = null;
    _notifications = null;
    _notificationsAt = null;
  }

  static void clearAll() {
    clearProducts();
    clearOrders();
  }
}

bool _metadataValueIsTrue(dynamic value) {
  final text = value?.toString().trim().toLowerCase() ?? '';
  return value == true || text == 'true' || text == '1' || text == 'yes';
}

void _clearSupabaseAuthStorageForGuestBrowsing() {
  // Direct browser localStorage/sessionStorage access requires dart:html.
  // Supabase signOut above clears the active session safely for Android builds.
}

String repeatIntervalLabel(int days) {
  if (days <= 7) return 'Every week';
  if (days <= 14) return 'Every 2 weeks';
  if (days <= 30) return 'Every month';
  return 'Every $days days';
}

String _friendlyStatus(String value) => friendlyLabel(value);

String? get currentUserId => isLoggedIn ? supabase.auth.currentUser?.id : null;

String? get currentUserEmail =>
    isLoggedIn ? supabase.auth.currentUser?.email?.trim().toLowerCase() : null;

String get currentUserRole {
  if (!isLoggedIn) return 'customer';

  final user = supabase.auth.currentUser;
  final data = user?.userMetadata ?? const {};
  final role = data['role']?.toString().toLowerCase();

  // Security note: protected access is never granted from user metadata or
  // hardcoded emails. Admin privileges are checked against the database by
  // isCurrentUserAdminFromDatabase(), and must also be enforced with backend security rules.
  if (role == 'farmer') return 'farmer';
  return 'customer';
}

bool _looksLikeEmailAddress(String value) {
  final clean = value.trim();
  if (clean.isEmpty) return false;
  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(clean) ||
      clean.contains('@');
}

class MarketplaceStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const MarketplaceStatCard(
      {super.key,
      required this.icon,
      required this.label,
      required this.value});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 145,
      child: FarmCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: FarmColors.green),
            const SizedBox(height: 10),
            Text(value,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class PayoutCard extends StatelessWidget {
  final FarmerPayout payout;
  final VoidCallback? onChanged;

  const PayoutCard({
    super.key,
    required this.payout,
    this.onChanged,
  });

  Color _statusColor() {
    switch (payout.payoutStatus.trim().toLowerCase()) {
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

  @override
  Widget build(BuildContext context) {
    final color = _statusColor();

    final isWholesale = payout.isWholesaleReceiving;

    final title = isWholesale
        ? payout.productName.trim().isEmpty
            ? 'Wholesale Produce'
            : payout.productName
        : payout.orderId.trim().isEmpty
            ? 'Retail Payout'
            : 'Order #${payout.shortSourceId}';

    final method = payout.payoutMethod.trim().isEmpty
        ? 'Payment method not set'
        : payout.payoutMethod;

    final reference = payout.payoutReference.trim().isEmpty
        ? 'No payment reference'
        : payout.payoutReference;

    return FarmCard(
      padding: const EdgeInsets.all(
        15,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // =============================================
          // HEADER
          // =============================================

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withOpacity(
                    0.10,
                  ),
                  borderRadius: BorderRadius.circular(
                    14,
                  ),
                ),
                child: Icon(
                  isWholesale
                      ? Icons.agriculture_outlined
                      : Icons.account_balance_wallet_outlined,
                  color: color,
                  size: 21,
                ),
              ),
              const SizedBox(
                width: 11,
              ),
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
                    const SizedBox(
                      height: 3,
                    ),
                    Text(
                      isWholesale
                          ? 'Wholesale farm supply'
                          : 'Retail marketplace',
                      style: const TextStyle(
                        color: FarmColors.mutedText,
                        fontSize: 10.5,
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
                  _friendlyStatus(
                    payout.payoutStatus,
                  ),
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
            height: 13,
          ),

          // =============================================
          // WHOLESALE DETAILS
          // =============================================

          if (isWholesale)
            Container(
              padding: const EdgeInsets.all(
                12,
              ),
              decoration: BoxDecoration(
                color: FarmColors.background,
                borderRadius: BorderRadius.circular(
                  15,
                ),
                border: Border.all(
                  color: FarmColors.line,
                ),
              ),
              child: Column(
                children: [
                  if (payout.quantityLabel.isNotEmpty)
                    TraceRow(
                      icon: Icons.scale_outlined,
                      title: 'Accepted quantity',
                      value: payout.quantityLabel,
                    ),
                  if (payout.farmerUnitCost != null)
                    TraceRow(
                      icon: Icons.sell_outlined,
                      title: 'Farmer price',
                      value:
                          '${formatJmd(payout.farmerUnitCost!)} / ${payout.payoutUnit}',
                    ),
                  TraceRow(
                    icon: Icons.payments_outlined,
                    title: 'Farmer payout',
                    value: formatJmd(
                      payout.netAmount,
                    ),
                  ),
                  if (payout.lotCode.isNotEmpty)
                    TraceRow(
                      icon: Icons.qr_code_2_outlined,
                      title: 'Receiving lot',
                      value: payout.lotCode,
                    ),
                ],
              ),
            )
          else

            // ===========================================
            // EXISTING RETAIL DETAILS
            // ===========================================

            Container(
              padding: const EdgeInsets.all(
                12,
              ),
              decoration: BoxDecoration(
                color: FarmColors.background,
                borderRadius: BorderRadius.circular(
                  15,
                ),
                border: Border.all(
                  color: FarmColors.line,
                ),
              ),
              child: Column(
                children: [
                  TraceRow(
                    icon: Icons.shopping_bag_outlined,
                    title: 'Gross sale',
                    value: formatJmd(
                      payout.grossAmount,
                    ),
                  ),
                  TraceRow(
                    icon: Icons.savings_outlined,
                    title: 'Platform share',
                    value: formatJmd(
                      payout.commissionAmount,
                    ),
                  ),
                  TraceRow(
                    icon: Icons.payments_outlined,
                    title: 'Farmer payout',
                    value: formatJmd(
                      payout.netAmount,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(
            height: 11,
          ),

          // =============================================
          // PAYMENT INFORMATION
          // =============================================

          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              Chip(
                avatar: const Icon(
                  Icons.account_balance_outlined,
                  size: 15,
                ),
                label: Text(method),
              ),
              if (payout.payoutReference.trim().isNotEmpty)
                Chip(
                  avatar: const Icon(
                    Icons.tag_outlined,
                    size: 15,
                  ),
                  label: Text(reference),
                ),
              if (isWholesale)
                const Chip(
                  avatar: Icon(
                    Icons.warehouse_outlined,
                    size: 15,
                  ),
                  label: Text(
                    'Wholesale',
                  ),
                ),
            ],
          ),

          // =============================================
          // ADMIN ACTIONS
          // =============================================

          if (onChanged != null) ...[
            const SizedBox(
              height: 12,
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: payout.payoutStatus == 'released'
                      ? null
                      : () async {
                          await updateFarmerPayoutStatus(
                            payoutId: payout.id,
                            status: 'released',
                          );

                          onChanged?.call();
                        },
                  icon: const Icon(
                    Icons.verified_outlined,
                    size: 17,
                  ),
                  label: const Text(
                    'Release',
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: payout.payoutStatus == 'held'
                      ? null
                      : () async {
                          await updateFarmerPayoutStatus(
                            payoutId: payout.id,
                            status: 'held',
                          );

                          onChanged?.call();
                        },
                  icon: const Icon(
                    Icons.pause_circle_outline,
                    size: 17,
                  ),
                  label: const Text(
                    'Hold',
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: payout.payoutStatus == 'disputed'
                      ? null
                      : () async {
                          await updateFarmerPayoutStatus(
                            payoutId: payout.id,
                            status: 'disputed',
                          );

                          onChanged?.call();
                        },
                  icon: const Icon(
                    Icons.report_problem_outlined,
                    size: 17,
                  ),
                  label: const Text(
                    'Dispute',
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

class FarmBottomOption {
  final Widget icon;
  final Widget selectedIcon;
  final String label;
  final int badgeCount;

  const FarmBottomOption({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.badgeCount = 0,
  });
}

class FarmBottomOptionsBar extends StatelessWidget {
  final int selectedIndex;
  final List<FarmBottomOption> destinations;
  final ValueChanged<int> onSelected;

  const FarmBottomOptionsBar({
    super.key,
    required this.selectedIndex,
    required this.destinations,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final safeIndex = destinations.isEmpty
        ? 0
        : selectedIndex.clamp(0, destinations.length - 1).toInt();

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 7, 8, 7),
        decoration: BoxDecoration(
          color: FarmColors.surface,
          border: const Border(
            top: BorderSide(color: FarmColors.line),
          ),
          boxShadow: [
            BoxShadow(
              color: FarmColors.shadow.withOpacity(0.07),
              blurRadius: 20,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Row(
          children: List.generate(destinations.length, (index) {
            final option = destinations[index];
            final selected = index == safeIndex;
            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (_) => _syncKeyboardStateSafely(),
                onTap: () => onSelected(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color:
                        selected ? FarmColors.lightGreen : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          IconTheme(
                            data: IconThemeData(
                              color: selected
                                  ? FarmColors.green
                                  : FarmColors.muted,
                              size: 21,
                            ),
                            child: selected ? option.selectedIcon : option.icon,
                          ),
                          if (option.badgeCount > 0)
                            Positioned(
                              top: -8,
                              right: -14,
                              child: Container(
                                constraints: const BoxConstraints(
                                  minWidth: 18,
                                  minHeight: 18,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: FarmColors.accent,
                                  borderRadius: BorderRadius.circular(999),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          FarmColors.shadow.withOpacity(0.12),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  option.badgeCount > 99
                                      ? '99+'
                                      : option.badgeCount.toString(),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: FarmColors.ink,
                                    fontSize: 10,
                                    height: 1,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        option.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10.2,
                          fontWeight:
                              selected ? FontWeight.w900 : FontWeight.w700,
                          color: selected ? FarmColors.green : FarmColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// =====================================================
// HPJ SMART LOCAL MEMORY
// Lightweight device-side memory for low-friction UX and
// poor-network recovery. No passwords or auth secrets are stored here.
// =====================================================
class HpjSmartLocalStore {
  static String _scopeKey(String key) {
    final userId = supabase.auth.currentUser?.id.trim();
    final scope = userId == null || userId.isEmpty ? 'guest' : userId;
    return 'hpj_smart_v1.$scope.$key';
  }

  static Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

  static Future<String?> readString(String key) async {
    try {
      return (await _prefs()).getString(_scopeKey(key));
    } catch (error) {
      farmDebugLog('Smart memory read skipped: $error');
      return null;
    }
  }

  static Future<void> writeString(String key, String? value) async {
    try {
      final prefs = await _prefs();
      final scoped = _scopeKey(key);
      final clean = value?.trim() ?? '';
      if (clean.isEmpty) {
        await prefs.remove(scoped);
      } else {
        await prefs.setString(scoped, clean);
      }
    } catch (error) {
      farmDebugLog('Smart memory write skipped: $error');
    }
  }

  static Future<double?> readDouble(String key) async {
    try {
      return (await _prefs()).getDouble(_scopeKey(key));
    } catch (error) {
      farmDebugLog('Smart memory read skipped: $error');
      return null;
    }
  }

  static Future<void> writeDouble(String key, double value) async {
    try {
      await (await _prefs()).setDouble(_scopeKey(key), value);
    } catch (error) {
      farmDebugLog('Smart memory write skipped: $error');
    }
  }

  static Future<int?> readInt(String key) async {
    try {
      return (await _prefs()).getInt(_scopeKey(key));
    } catch (error) {
      farmDebugLog('Smart memory read skipped: $error');
      return null;
    }
  }

  static Future<void> writeInt(String key, int value) async {
    try {
      await (await _prefs()).setInt(_scopeKey(key), value);
    } catch (error) {
      farmDebugLog('Smart memory write skipped: $error');
    }
  }

  static Future<bool?> readBool(String key) async {
    try {
      return (await _prefs()).getBool(_scopeKey(key));
    } catch (error) {
      farmDebugLog('Smart memory read skipped: $error');
      return null;
    }
  }

  static Future<void> writeBool(String key, bool value) async {
    try {
      await (await _prefs()).setBool(_scopeKey(key), value);
    } catch (error) {
      farmDebugLog('Smart memory write skipped: $error');
    }
  }

  static Future<List<String>> readStringList(String key) async {
    try {
      return (await _prefs()).getStringList(_scopeKey(key)) ?? <String>[];
    } catch (error) {
      farmDebugLog('Smart memory read skipped: $error');
      return <String>[];
    }
  }

  static Future<void> writeStringList(String key, List<String> values) async {
    try {
      final clean = values
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toList();
      await (await _prefs()).setStringList(_scopeKey(key), clean);
    } catch (error) {
      farmDebugLog('Smart memory write skipped: $error');
    }
  }

  static Future<void> remove(String key) async {
    try {
      await (await _prefs()).remove(_scopeKey(key));
    } catch (error) {
      farmDebugLog('Smart memory remove skipped: $error');
    }
  }

  static Future<void> rememberRecentSearch(String query) async {
    final clean = query.trim();
    if (clean.length < 2) return;
    final current = await readStringList('recent_searches');
    final next = <String>[
      clean,
      ...current.where((item) => item.toLowerCase() != clean.toLowerCase()),
    ].take(6).toList();
    await writeStringList('recent_searches', next);
  }
}

class OfflineCartStore {
  static const String _persistentCartKey = 'cart_product_ids';
  static final List<Product> _sessionCart = <Product>[];

  static List<Product> restore() => List<Product>.from(_sessionCart);

  static Future<List<String>> restorePersistentProductIds() async {
    return HpjSmartLocalStore.readStringList(_persistentCartKey);
  }

  static void save(List<Product> cart) {
    _sessionCart
      ..clear()
      ..addAll(cart);

    // Keep a lightweight product-id snapshot so a box survives an app restart.
    // The latest product/price/stock is always fetched again before checkout.
    unawaited(
      HpjSmartLocalStore.writeStringList(
        _persistentCartKey,
        cart.map((product) => product.id).toList(),
      ),
    );
  }

  static Future<void> clearPersistent() async {
    _sessionCart.clear();
    await HpjSmartLocalStore.remove(_persistentCartKey);
  }
}

String personalizedFirstName(CustomerProfile? profile) {
  if (!isLoggedIn) return 'Guest';

  final rawName = (profile?.fullName ?? '').trim();
  final cleanName = rawName.toLowerCase();
  final email = supabase.auth.currentUser?.email ?? '';
  final localPart = email.split('@').first.trim();

  String emailFirstName() {
    if (localPart.isEmpty) return 'there';

    // Prefer a friendly first name instead of showing the whole email handle.
    var cleaned = localPart
        .replaceAll(RegExp(r'[0-9]+'), ' ')
        .replaceAll(RegExp(r'[._-]+'), ' ')
        .trim();

    if (!cleaned.contains(' ') && cleaned.length > 12) {
      // Common school/business handles sometimes join first + last + org code.
      // This keeps the greeting human, e.g. ricardofergusonlshs -> Ricardo.
      final lower = cleaned.toLowerCase();
      if (lower.startsWith('ricardo')) cleaned = 'ricardo';
    }

    final readable = titleCaseWords(cleaned).trim();
    if (readable.isEmpty) return 'there';
    return readable.split(' ').first;
  }

  // Never use role/fallback labels as the customer's display name.
  if (rawName.isEmpty || cleanName == 'admin' || cleanName == 'administrator') {
    return emailFirstName();
  }

  return titleCaseWords(rawName).split(' ').first;
}

String personalizedGreeting(CustomerProfile? profile) {
  final firstName = personalizedFirstName(profile);
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good morning, $firstName';
  if (hour < 17) return 'Good afternoon, $firstName';
  return 'Good evening, $firstName';
}

String? mostCommonText(List<String> values) {
  if (values.isEmpty) return null;
  final counts = <String, int>{};
  final labels = <String, String>{};
  for (final value in values) {
    final clean = value.trim();
    if (clean.isEmpty) continue;
    final key = clean.toLowerCase();
    counts[key] = (counts[key] ?? 0) + 1;
    labels[key] = clean;
  }
  if (counts.isEmpty) return null;
  final best = counts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return labels[best.first.key];
}

class _PersonalizedHeroChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _PersonalizedHeroChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
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
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class PersonalizedLoyaltyCard extends StatelessWidget {
  final Future<LoyaltySummary> loyaltyFuture;

  const PersonalizedLoyaltyCard({
    super.key,
    required this.loyaltyFuture,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LoyaltySummary>(
      future: loyaltyFuture,
      builder: (context, snapshot) {
        final loyalty = snapshot.data ??
            const LoyaltySummary(points: 0, lifetimePoints: 0, tier: 'Green');
        final tier = loyalty.tier.trim().isEmpty ? 'Green' : loyalty.tier;

        return FarmCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      height: 34,
                      width: 34,
                      decoration: BoxDecoration(
                        color: FarmColors.primarySoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.eco_outlined,
                        color: FarmColors.green,
                        size: 19,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Member rewards',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: FarmColors.deepGreen,
                              fontSize: 15,
                              height: 1.1,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Enjoy rewards as you shop',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: FarmColors.mutedText,
                              fontSize: 10.2,
                              height: 1.0,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 38,
                color: FarmColors.line,
                margin: const EdgeInsets.symmetric(horizontal: 12),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${loyalty.points}',
                    style: const TextStyle(
                      color: FarmColors.deepGreen,
                      fontSize: 21,
                      height: 1.0,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rewards',
                    style: TextStyle(
                      color: FarmColors.mutedText,
                      fontSize: 10.2,
                      height: 1.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right_rounded,
                color: FarmColors.green,
                size: 24,
              ),
            ],
          ),
        );
      },
    );
  }
}

class PersonalizedInsightsLoader extends StatelessWidget {
  final Future<LoyaltySummary> loyaltyFuture;
  final List<Product> allProducts;
  final List<Product> buyAgainProducts;
  final List<Product> favoriteProducts;
  final List<Product> recentlyViewedProducts;

  const PersonalizedInsightsLoader({
    super.key,
    required this.loyaltyFuture,
    required this.allProducts,
    required this.buyAgainProducts,
    required this.favoriteProducts,
    required this.recentlyViewedProducts,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LoyaltySummary>(
      future: loyaltyFuture,
      builder: (context, snapshot) {
        final loyalty = snapshot.data ??
            const LoyaltySummary(
              points: 0,
              lifetimePoints: 0,
              tier: 'Green',
            );
        final farmers = <String>{
          ...buyAgainProducts.map((product) => product.farmName ?? ''),
          ...favoriteProducts.map((product) => product.farmName ?? ''),
          ...recentlyViewedProducts.map((product) => product.farmName ?? ''),
        }..removeWhere((value) => value.trim().isEmpty);
        final favoriteCategory = mostCommonText([
              ...buyAgainProducts.map((product) => product.category),
              ...favoriteProducts.map((product) => product.category),
              ...recentlyViewedProducts.map((product) => product.category),
            ]) ??
            'Fresh Produce';
        final favoriteProduct = buyAgainProducts.isNotEmpty
            ? buyAgainProducts.first.name
            : favoriteProducts.isNotEmpty
                ? favoriteProducts.first.name
                : recentlyViewedProducts.isNotEmpty
                    ? recentlyViewedProducts.first.name
                    : 'Explore today';

        return FarmCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your Harvest Snapshot',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _InsightPill(
                    icon: Icons.workspace_premium_outlined,
                    label: '${loyalty.points} points',
                  ),
                  _InsightPill(
                    icon: Icons.category_outlined,
                    label: favoriteCategory,
                  ),
                  _InsightPill(
                    icon: Icons.shopping_bag_outlined,
                    label: favoriteProduct,
                  ),
                  _InsightPill(
                    icon: Icons.storefront_outlined,
                    label: '${farmers.length} local farms',
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

class _InsightPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InsightPill({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: FarmColors.primarySoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FarmColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: FarmColors.green),
          const SizedBox(width: 7),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: FarmColors.green,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

IconData categoryIconForName(String category) {
  final lower = category.trim().toLowerCase();

  if (lower.contains('favorite') || lower.contains('favourite')) {
    return Icons.favorite_outline;
  }
  if (lower.contains('vegetable')) return Icons.eco_outlined;
  if (lower.contains('fruit')) return Icons.spa_outlined;
  if (lower.contains('ground')) return Icons.grass_outlined;
  if (lower.contains('herb')) return Icons.local_florist_outlined;
  if (lower.contains('egg')) return Icons.egg_alt_outlined;
  if (lower.contains('honey')) return Icons.water_drop_outlined;
  if (lower.contains('dairy')) return Icons.local_drink_outlined;
  if (lower.contains('drink')) return Icons.local_cafe_outlined;
  if (lower.contains('prepared')) return Icons.restaurant_menu_outlined;

  return Icons.category_outlined;
}

class VeganIngredient {
  final String name;
  final String emoji;
  final String category;
  final String description;
  final String benefits;
  final String cookingUses;
  final String storageTips;
  final List<String> keywords;

  const VeganIngredient({
    required this.name,
    required this.emoji,
    required this.category,
    required this.description,
    required this.benefits,
    required this.cookingUses,
    required this.storageTips,
    required this.keywords,
  });
}

const List<VeganIngredient> veganIngredients = [
  VeganIngredient(
    name: 'Callaloo',
    emoji: '',
    category: 'Leafy Greens',
    description:
        'A Jamaican leafy green that works beautifully in soups, sautés, patties, and breakfast bowls.',
    benefits:
        'Rich in plant-based iron, fiber, vitamin A, vitamin C, and minerals that support everyday wellness.',
    cookingUses:
        'Steam lightly, sauté with garlic and onion, add to rice bowls, or mix into vegan patties and wraps.',
    storageTips:
        'Keep leaves dry in a breathable bag in the refrigerator and use within 3–5 days for best freshness.',
    keywords: ['callaloo', 'greens', 'vegetables', 'leafy'],
  ),
  VeganIngredient(
    name: 'Lettuce',
    emoji: '',
    category: 'Salad Greens',
    description:
        'A crisp, hydrating base for salads, wraps, sandwiches, and light plant-based meals.',
    benefits:
        'Low calorie, hydrating, and useful for adding volume, crunch, and freshness to meals.',
    cookingUses:
        'Use raw in salads, wraps, tacos, veggie bowls, or as a fresh side with herbs and citrus.',
    storageTips:
        'Store chilled with a paper towel to absorb moisture and keep leaves crisp.',
    keywords: ['lettuce', 'salad', 'greens', 'vegetables'],
  ),
  VeganIngredient(
    name: 'Sweet Corn',
    emoji: '',
    category: 'Whole Food Carbs',
    description:
        'Naturally sweet, filling, and great for hearty vegan bowls, soups, and side dishes.',
    benefits:
        'Provides fiber, natural carbohydrates, and antioxidants that help make meals satisfying.',
    cookingUses:
        'Boil, grill, roast, add to soups, mix into salsa, or pair with beans and peppers.',
    storageTips:
        'Keep husks on until cooking and refrigerate for best sweetness.',
    keywords: ['corn', 'sweet corn', 'vegetables'],
  ),
  VeganIngredient(
    name: 'Okra',
    emoji: '',
    category: 'Vegetables',
    description:
        'A tender pod vegetable often used in stews, soups, and Caribbean-inspired vegan meals.',
    benefits:
        'Contains fiber and plant nutrients that support digestion and help thicken dishes naturally.',
    cookingUses:
        'Add to stews, roast with spices, sauté quickly, or use in soups and vegetable medleys.',
    storageTips:
        'Keep dry in the refrigerator and use within a few days to avoid softness.',
    keywords: ['okra', 'vegetables'],
  ),
  VeganIngredient(
    name: 'Pumpkin',
    emoji: '',
    category: 'Squash',
    description:
        'A hearty, naturally sweet ingredient for soups, stews, curries, and vegan baking.',
    benefits:
        'High in beta carotene, fiber, and slow-digesting carbohydrates for filling plant-based meals.',
    cookingUses:
        'Roast, boil into soup, mash into porridge, add to curry, or blend into sauces.',
    storageTips:
        'Store whole pumpkin in a cool dry place; refrigerate cut pieces in a sealed container.',
    keywords: ['pumpkin', 'squash', 'vegetables'],
  ),
  VeganIngredient(
    name: 'Bell Pepper',
    emoji: '',
    category: 'Color Vegetables',
    description:
        'A colorful vegetable that adds sweetness, crunch, and freshness to vegan dishes.',
    benefits:
        'Excellent source of vitamin C and antioxidants with bright flavor and natural color.',
    cookingUses:
        'Slice into salads, stir-fries, wraps, roasted trays, pasta, or stuffed pepper meals.',
    storageTips:
        'Refrigerate whole peppers and keep cut pieces sealed for freshness.',
    keywords: ['pepper', 'bell pepper', 'vegetables'],
  ),
  VeganIngredient(
    name: 'Fresh Herbs',
    emoji: '',
    category: 'Herbs',
    description:
        'Herbs add flavor without relying on heavy sauces, salt, or processed seasonings.',
    benefits:
        'Adds antioxidants, aroma, and depth to simple plant-based meals.',
    cookingUses:
        'Use in marinades, salads, soups, dressings, teas, sauces, and finishing oils.',
    storageTips:
        'Wrap gently in a damp towel or stand stems in water and refrigerate.',
    keywords: ['herbs', 'seasoning', 'fresh herbs'],
  ),
  VeganIngredient(
    name: 'Fruit',
    emoji: '',
    category: 'Fruit',
    description:
        'Fresh fruit is perfect for snacks, smoothies, breakfast bowls, and naturally sweet desserts.',
    benefits:
        'Provides fiber, hydration, vitamins, and natural sweetness for everyday energy.',
    cookingUses:
        'Eat fresh, blend into smoothies, add to oats, bake, or pair with nuts and seeds.',
    storageTips:
        'Store ripe fruit chilled and keep ethylene-producing fruit separate when needed.',
    keywords: ['fruit', 'fruits', 'apple', 'smoothie'],
  ),
];

class _VeganIngredientBookScreenState extends State<VeganIngredientBookScreen> {
  final searchController = TextEditingController();
  String selectedCategory = 'All';

  List<String> get categories {
    return ['All', ...veganIngredients.map((item) => item.category).toSet()];
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<VeganIngredient> get filteredIngredients {
    final query = searchController.text.trim().toLowerCase();
    return veganIngredients.where((item) {
      final matchesCategory =
          selectedCategory == 'All' || item.category == selectedCategory;
      final text =
          '${item.name} ${item.category} ${item.description} ${item.benefits} ${item.keywords.join(' ')}'
              .toLowerCase();
      final matchesSearch = query.isEmpty || text.contains(query);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = filteredIngredients;

    return Scaffold(
      backgroundColor: FarmColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 78),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                ),
                const Expanded(
                  child: Header(
                    title: 'Vegan Ingredient Book',
                    subtitle: 'Benefits, cooking ideas & farm-fresh guidance',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1F6B2A), Color(0xFF4B9B45)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: FarmColors.green.withOpacity(0.20),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.eco_outlined, size: 54, color: Colors.white),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Plant-powered learning',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Discover how to cook, store, and shop fresh vegan ingredients from the farm.',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            FarmCard(
              child: Column(
                children: [
                  TextField(
                    controller: searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search ingredients, benefits, or uses...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: searchController.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                searchController.clear();
                                setState(() {});
                              },
                            ),
                      filled: true,
                      fillColor: FarmColors.cream,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 42,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 7),
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        final selected = selectedCategory == category;
                        return ChoiceChip(
                          label: Text(category),
                          selected: selected,
                          onSelected: (_) =>
                              setState(() => selectedCategory = category),
                          selectedColor: FarmColors.green,
                          backgroundColor: FarmColors.lightGreen,
                          labelStyle: TextStyle(
                            color: selected ? Colors.white : FarmColors.green,
                            fontWeight: FontWeight.w700,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: selected
                                  ? FarmColors.green
                                  : Colors.transparent,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              const FarmEmptyState(
                icon: Icons.menu_book_outlined,
                title: 'No ingredients found',
                message: 'Try another search or category.',
              )
            else
              ...items.map((ingredient) {
                return VeganIngredientCard(
                  ingredient: ingredient,
                  onShopTap: widget.onShopTap,
                );
              }),
          ],
        ),
      ),
    );
  }
}

class VeganIngredientCard extends StatelessWidget {
  final VeganIngredient ingredient;
  final VoidCallback onShopTap;

  const VeganIngredientCard({
    super.key,
    required this.ingredient,
    required this.onShopTap,
  });

  @override
  Widget build(BuildContext context) {
    return FarmCard(
      margin: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 68,
                width: 68,
                decoration: BoxDecoration(
                  color: FarmColors.lightGreen,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: Icon(
                    Icons.local_florist_outlined,
                    size: 34,
                    color: FarmColors.green,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ingredient.name,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Chip(
                      label: Text(ingredient.category),
                      backgroundColor: FarmColors.lightGreen,
                      labelStyle: const TextStyle(color: FarmColors.green),
                    ),
                    const SizedBox(height: 4),
                    Text(ingredient.description),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          IngredientInfoRow(
            icon: Icons.favorite_outline,
            title: 'Fresh notes',
            body: ingredient.benefits,
          ),
          IngredientInfoRow(
            icon: Icons.restaurant_menu_outlined,
            title: 'Cooking uses',
            body: ingredient.cookingUses,
          ),
          IngredientInfoRow(
            icon: Icons.inventory_2_outlined,
            title: 'Storage tips',
            body: ingredient.storageTips,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ingredient.keywords.map((keyword) {
              return Chip(
                label: Text(keyword),
                backgroundColor: Colors.white,
                side: BorderSide(color: FarmColors.border),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                onShopTap();
              },
              icon: const Icon(Icons.storefront_outlined),
              label: Text('Shop related ${ingredient.name} products'),
              style: ElevatedButton.styleFrom(
                backgroundColor: FarmColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class IngredientInfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const IngredientInfoRow({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: FarmColors.green, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FreshnessChip extends StatelessWidget {
  const _FreshnessChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'Freshly sourced',
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class ProductAvailabilityChip extends StatelessWidget {
  final Product product;
  final bool compact;

  const ProductAvailabilityChip({
    super.key,
    required this.product,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    String? label;
    IconData icon = Icons.check_circle_outline;
    Color color = FarmColors.green;
    Color background = FarmColors.lightGreen;

    if (product.isOutOfStock) {
      label = 'Out of stock';
      icon = Icons.block_outlined;
      color = FarmColors.danger;
      background = FarmColors.dangerSoft;
    } else if (product.isLowStock) {
      label = product.lowStockLabel;
      icon = Icons.local_fire_department_outlined;
      color = FarmColors.warning;
      background = FarmColors.warningSoft;
    }

    if (label == null || label.trim().isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(top: compact ? 3 : 7),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 7 : 10,
          vertical: compact ? 4 : 6,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withOpacity(0.12)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: compact ? 11 : 13, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: compact ? 10.0 : 11.3,
                height: 1,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductUnitChip extends StatelessWidget {
  final Product product;
  final bool compact;

  const ProductUnitChip({
    super.key,
    required this.product,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final unit = (product.unit ?? '').trim();
    if (unit.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: FarmColors.lightGreen,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: FarmColors.green.withOpacity(0.12)),
      ),
      child: Text(
        unit,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: FarmColors.green,
          fontSize: compact ? 10.8 : 12,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

class ProductMiniRail extends StatelessWidget {
  final List<Product> products;
  final VoidCallback? onTap;
  final void Function(Product product)? onProductTap;

  const ProductMiniRail({
    super.key,
    required this.products,
    this.onTap,
    this.onProductTap,
  });

  @override
  Widget build(BuildContext context) {
    final visible = products.take(8).toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 156,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        cacheExtent: AppPerformanceConfig.productRailCacheExtent,
        itemCount: visible.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final product = visible[index];
          final muted = product.isOutOfStock;
          final showSale =
              (product.hasActiveDiscount || product.showAsDealOfDay) &&
                  !product.isOutOfStock;

          return SizedBox(
            width: 138,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () {
                  if (onProductTap != null) {
                    onProductTap!(product);
                  } else {
                    onTap?.call();
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.fromLTRB(9, 9, 9, 9),
                  decoration: BoxDecoration(
                    color: muted ? FarmColors.cardSoft : Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: muted
                          ? FarmColors.danger.withOpacity(0.13)
                          : FarmColors.line.withOpacity(0.88),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: FarmColors.shadow
                            .withOpacity(muted ? 0.025 : 0.058),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Opacity(
                    opacity: muted ? 0.82 : 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color:
                                        FarmColors.cardSoft.withOpacity(0.72),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Center(
                                    child: ProductVisual(
                                      product: product,
                                      size: 86,
                                    ),
                                  ),
                                ),
                              ),
                              if (showSale)
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: product.hasActiveDiscount
                                      ? DiscountBadge(
                                          product: product,
                                          compact: true,
                                        )
                                      : Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: FarmColors.warningSoft,
                                            borderRadius:
                                                BorderRadius.circular(999),
                                            border: Border.all(
                                              color: FarmColors.warning
                                                  .withOpacity(0.14),
                                            ),
                                          ),
                                          child: const Text(
                                            'Sale',
                                            style: TextStyle(
                                              color: FarmColors.warning,
                                              fontSize: 10.5,
                                              height: 1,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Flexible(
                              child: ProductOriginBadge(
                                product: product,
                                compact: true,
                              ),
                            ),
                          ],
                        ),
                      ],
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
}

class CartLine {
  final Product product;
  final int quantity;

  const CartLine({required this.product, required this.quantity});

  CartLine copyWith({Product? product, int? quantity}) {
    return CartLine(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}

class EliteOrderStatusCard extends StatelessWidget {
  final OrderDetails order;

  const EliteOrderStatusCard({super.key, required this.order});

  Color get _statusColor {
    final status = order.status.trim().toLowerCase();
    if (status == 'delivered' || status == 'completed') {
      return FarmColors.green;
    }
    if (status == 'cancelled' || status == 'canceled') {
      return FarmColors.danger;
    }
    if (status == 'ready' ||
        status == 'ready_for_pickup' ||
        status == 'out_for_delivery') {
      return FarmColors.warning;
    }
    return FarmColors.green;
  }

  IconData get _statusIcon {
    final status = order.status.trim().toLowerCase();
    if (status == 'delivered' || status == 'completed') {
      return Icons.check_circle_outline;
    }
    if (status == 'preparing') return Icons.shopping_basket_outlined;
    if (status == 'ready' || status == 'ready_for_pickup') {
      return Icons.storefront_outlined;
    }
    if (status == 'out_for_delivery') return Icons.local_shipping_outlined;
    if (status == 'cancelled' || status == 'canceled') {
      return Icons.cancel_outlined;
    }
    return Icons.receipt_long_outlined;
  }

  String get _friendlyMessage {
    final delivery = order.fulfillmentType == 'delivery';
    switch (order.status.trim().toLowerCase()) {
      case 'preparing':
        return 'The farm is preparing your fresh items.';
      case 'ready':
      case 'ready_for_pickup':
        return 'Your order is ready for pickup.';
      case 'out_for_delivery':
        return 'Your order is on the way.';
      case 'delivered':
      case 'completed':
        return delivery
            ? 'Your delivery is complete. Thank you for shopping local.'
            : 'Your pickup is complete. Thank you for shopping local.';
      case 'cancelled':
      case 'canceled':
        return 'This order was cancelled.';
      default:
        return 'Your order was received and is waiting for farm confirmation.';
    }
  }

  bool get _isPaid => order.paymentStatus.trim().toLowerCase() == 'paid';

  String get _paymentLabel => _isPaid ? 'Paid' : 'Payment pending';

  Color get _paymentColor =>
      _isPaid ? const Color(0xFF247545) : const Color(0xFFB66A00);

  Widget _statusPill({
    required IconData icon,
    required String label,
    required Color color,
    bool filled = false,
  }) {
    final foreground = filled ? Colors.white : color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: filled ? color : color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: filled ? color : color.withOpacity(0.20)),
        boxShadow: filled
            ? [
                BoxShadow(
                  color: color.withOpacity(0.22),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : const [],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foreground,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDelivery = order.fulfillmentType == 'delivery';
    final statusColor = _statusColor;

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
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: FarmColors.shadow.withOpacity(0.16),
            blurRadius: 20,
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
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(color: Colors.white.withOpacity(0.22)),
                ),
                child: Icon(_statusIcon, color: Colors.white, size: 25),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${order.shortId}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.78),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      order.formattedOrderStatus,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 24,
                        height: 1.05,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _friendlyMessage,
            style: TextStyle(
              color: Colors.white.withOpacity(0.86),
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _statusPill(
                icon: isDelivery
                    ? Icons.local_shipping_outlined
                    : Icons.storefront_outlined,
                label: order.formattedType,
                color: Colors.white,
              ),
              _statusPill(
                icon: Icons.event_available_outlined,
                label: order.scheduleText,
                color: Colors.white,
              ),
              _statusPill(
                icon: _isPaid ? Icons.verified_rounded : Icons.schedule_rounded,
                label: _paymentLabel,
                color: _paymentColor,
                filled: true,
              ),
            ],
          ),
          if (isDelivery &&
              ((order.deliveryZone ?? '').isNotEmpty ||
                  (order.deliveryAddress ?? '').isNotEmpty)) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.10),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.16)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if ((order.deliveryZone ?? '').isNotEmpty)
                    Text(
                      'Zone: ${order.deliveryZone}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  if ((order.deliveryAddress ?? '').isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      order.deliveryAddress!,
                      style: TextStyle(color: Colors.white.withOpacity(0.84)),
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

class EliteOrderQuickActions extends StatelessWidget {
  final OrderDetails order;
  final Future<void> Function() onRefresh;

  const EliteOrderQuickActions({
    super.key,
    required this.order,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return FarmCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                onRefresh();
              },
              icon: const Icon(Icons.restart_alt_rounded, size: 18),
              label: const Text('Refresh'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SupportScreen()),
                );
              },
              icon: const Icon(Icons.support_agent_rounded, size: 18),
              label: const Text('Need help'),
            ),
          ),
        ],
      ),
    );
  }
}

class PremiumOrderTracker extends StatelessWidget {
  final String status;
  final bool isDelivery;
  final String paymentStatus;

  const PremiumOrderTracker({
    super.key,
    required this.status,
    required this.isDelivery,
    required this.paymentStatus,
  });

  String get _cleanStatus => status.trim().toLowerCase();

  bool get _isCancelled =>
      _cleanStatus == 'cancelled' || _cleanStatus == 'rejected';

  bool get _isCompleted =>
      _cleanStatus == 'delivered' || _cleanStatus == 'completed';

  bool get _isPaid => paymentStatus.trim().toLowerCase() == 'paid';

  int get currentStep {
    switch (_cleanStatus) {
      case 'pending':
        return 0;
      case 'preparing':
        return 1;
      case 'ready':
      case 'ready_for_pickup':
      case 'out_for_delivery':
        return 2;
      case 'delivered':
      case 'completed':
        return 3;
      case 'cancelled':
      case 'rejected':
        return 1;
      default:
        return 0;
    }
  }

  List<String> get labels {
    if (_isCancelled) {
      return const [
        'Order received',
        'Cancelled',
      ];
    }

    return [
      'Order received',
      'Preparing fresh items',
      isDelivery ? 'Out for delivery' : 'Ready for pickup',
      isDelivery ? 'Delivered' : 'Completed',
    ];
  }

  List<IconData> get icons {
    if (_isCancelled) {
      return const [
        Icons.receipt_long_outlined,
        Icons.cancel_outlined,
      ];
    }

    return [
      Icons.receipt_long_outlined,
      Icons.shopping_basket_outlined,
      isDelivery ? Icons.local_shipping_outlined : Icons.storefront_outlined,
      Icons.check_circle_outline,
    ];
  }

  // High-contrast stage colors. These are intentionally darker than the
  // decorative farm palette so text remains readable on real phone screens.
  Color get stageColor {
    switch (_cleanStatus) {
      case 'pending':
        return const Color(0xFF9A5B00);
      case 'preparing':
        return const Color(0xFF9A5A10);
      case 'ready':
      case 'ready_for_pickup':
      case 'out_for_delivery':
        return const Color(0xFF126F7A);
      case 'delivered':
      case 'completed':
        return const Color(0xFF247545);
      case 'cancelled':
      case 'rejected':
        return const Color(0xFFA33A30);
      default:
        return const Color(0xFF9A5B00);
    }
  }

  Color get stageSoftColor {
    switch (_cleanStatus) {
      case 'pending':
        return const Color(0xFFFFF4D8);
      case 'preparing':
        return const Color(0xFFFFEBD2);
      case 'ready':
      case 'ready_for_pickup':
      case 'out_for_delivery':
        return const Color(0xFFE2F4F5);
      case 'delivered':
      case 'completed':
        return const Color(0xFFE7F5EB);
      case 'cancelled':
      case 'rejected':
        return const Color(0xFFFFECE8);
      default:
        return const Color(0xFFFFF4D8);
    }
  }

  String get stageLabel {
    switch (_cleanStatus) {
      case 'pending':
        return 'Order received';
      case 'preparing':
        return 'Preparing fresh items';
      case 'ready':
      case 'ready_for_pickup':
        return 'Ready for pickup';
      case 'out_for_delivery':
        return 'Out for delivery';
      case 'delivered':
      case 'completed':
        return isDelivery ? 'Delivered' : 'Completed';
      case 'cancelled':
      case 'rejected':
        return 'Cancelled';
      default:
        return 'Order received';
    }
  }

  double get progressValue {
    if (_isCancelled) return 0.5;
    final count = labels.length;
    if (count == 0) return 0;
    return ((currentStep + 1) / count).clamp(0.0, 1.0).toDouble();
  }

  String get progressLabel {
    if (_isCancelled) return 'Order cancelled';
    return '${(progressValue * 100).round()}% complete';
  }

  Widget _pill({
    required String label,
    required Color color,
    IconData? icon,
    bool filled = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: filled ? color : color.withOpacity(0.11),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: filled ? color : color.withOpacity(0.28),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 14,
              color: filled ? Colors.white : color,
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: filled ? Colors.white : color,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stepLabels = labels;
    final stepIcons = icons;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            stageSoftColor.withOpacity(0.92),
            Colors.white,
          ],
        ),
        border: Border.all(color: stageColor.withOpacity(0.26), width: 1.15),
        boxShadow: [
          BoxShadow(
            color: FarmColors.shadow.withOpacity(0.08),
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
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: stageColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Container(
                  height: 5,
                  decoration: BoxDecoration(
                    color: FarmColors.line.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Text(
                  'Live Order Tracker',
                  style: TextStyle(
                    fontSize: 20,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                    color: FarmColors.ink,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _pill(
                    label: _isCancelled ? 'Cancelled' : stageLabel,
                    color: stageColor,
                    icon: _isCancelled
                        ? Icons.cancel_outlined
                        : _isCompleted
                            ? Icons.check_circle_outline
                            : Icons.radio_button_checked_rounded,
                    filled: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _pill(
                label: _isPaid ? 'Paid' : 'Payment pending',
                color:
                    _isPaid ? const Color(0xFF247545) : const Color(0xFFB66A00),
                icon: _isPaid ? Icons.verified_rounded : Icons.schedule_rounded,
                filled: true,
              ),
              _pill(
                label: progressLabel,
                color: stageColor,
                icon: Icons.trending_up_rounded,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.82),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: stageColor.withOpacity(0.18)),
            ),
            child: Text(
              'Current stage: $stageLabel',
              style: TextStyle(
                color: stageColor,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                height: 1.25,
              ),
            ),
          ),
          const SizedBox(height: 10),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: progressValue),
            duration: const Duration(milliseconds: 650),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  height: 12,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E8DD),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: value,
                    child: Container(
                      decoration: BoxDecoration(
                        color: stageColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Text(
            _isCancelled
                ? 'This order is no longer active.'
                : 'Follow each step as your order moves through the farm.',
            style: const TextStyle(
              color: FarmColors.ink,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          ...List.generate(stepLabels.length, (index) {
            final complete = !_isCancelled && index < currentStep;
            final active = index == currentStep;
            final isLast = index == stepLabels.length - 1;

            return _PremiumTrackingStep(
              icon: stepIcons[index],
              title: stepLabels[index],
              subtitle: active
                  ? 'Current step'
                  : complete
                      ? 'Completed'
                      : 'Coming next',
              complete: complete,
              active: active,
              showLine: !isLast,
              stageColor: active || complete ? stageColor : FarmColors.muted,
              softColor: active ? stageSoftColor : FarmColors.lightGreen,
              lineColor: complete ? stageColor : FarmColors.line,
              cancelled: _isCancelled && active,
            );
          }),
        ],
      ),
    );
  }
}

class _PremiumTrackingStep extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool complete;
  final bool active;
  final bool showLine;
  final Color stageColor;
  final Color softColor;
  final Color lineColor;
  final bool cancelled;

  const _PremiumTrackingStep({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.complete,
    required this.active,
    required this.showLine,
    required this.stageColor,
    required this.softColor,
    required this.lineColor,
    this.cancelled = false,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = cancelled ? const Color(0xFFA33A30) : stageColor;
    final circleColor = complete
        ? const Color(0xFF247545)
        : active
            ? activeColor
            : const Color(0xFFF8FBF6);

    final iconColor = complete || active ? Colors.white : FarmColors.mutedText;

    final cardTint = active
        ? softColor.withOpacity(0.9)
        : complete
            ? const Color(0xFFEAF5E7)
            : Colors.white;

    final borderColor = active
        ? activeColor.withOpacity(0.36)
        : complete
            ? const Color(0xFF247545).withOpacity(0.25)
            : FarmColors.line.withOpacity(0.8);

    final titleColor = active
        ? FarmColors.ink
        : complete
            ? const Color(0xFF247545)
            : const Color(0xFF5B665F);

    final subtitleColor = active
        ? activeColor
        : complete
            ? const Color(0xFF247545)
            : const Color(0xFF747F78);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.92, end: active ? 1.0 : 0.96),
              duration: const Duration(milliseconds: 650),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: child,
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: active ? 52 : 44,
                width: active ? 52 : 44,
                decoration: BoxDecoration(
                  color: circleColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: active
                        ? Colors.white
                        : complete
                            ? const Color(0xFF247545)
                            : FarmColors.line,
                    width: active ? 3 : 1.2,
                  ),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: activeColor.withOpacity(0.22),
                            blurRadius: 18,
                            spreadRadius: 2,
                          ),
                        ]
                      : const [],
                ),
                child: Icon(
                  complete
                      ? Icons.check_rounded
                      : cancelled
                          ? Icons.close_rounded
                          : icon,
                  color: iconColor,
                  size: active ? 25 : 21,
                ),
              ),
            ),
            if (showLine)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 3,
                height: active ? 42 : 34,
                decoration: BoxDecoration(
                  color: lineColor.withOpacity(complete ? 0.9 : 0.5),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: EdgeInsets.only(
              top: active ? 0 : 2,
              bottom: showLine ? 12 : 0,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: active ? 14 : 12,
              vertical: active ? 13 : 11,
            ),
            decoration: BoxDecoration(
              color: cardTint,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 250),
              opacity: active || complete ? 1 : 0.86,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: active ? FontWeight.w900 : FontWeight.w800,
                      color: titleColor,
                      fontSize: active ? 16 : 15,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: subtitleColor,
                      fontWeight: active ? FontWeight.w900 : FontWeight.w700,
                      fontSize: 12.5,
                      height: 1.15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

String _titleCase(String value) {
  if (value.isEmpty) return value;
  return value[0].toUpperCase() + value.substring(1).toLowerCase();
}

class LaunchChecklistSnapshot {
  final List<LaunchCheckItem> checks;
  final int visibleProductCount;
  final int activeProductCount;
  final int productImageCount;
  final int heroSlideCount;
  final int orderCount;

  const LaunchChecklistSnapshot({
    required this.checks,
    required this.visibleProductCount,
    required this.activeProductCount,
    required this.productImageCount,
    required this.heroSlideCount,
    required this.orderCount,
  });

  int get readyCount => checks.where((check) => check.isReady).length;
  int get reviewCount => checks.where((check) => check.isReview).length;
  int get actionCount => checks.where((check) => check.needsAction).length;
  double get readinessScore {
    if (checks.isEmpty) return 0;
    final weighted = checks.fold<double>(0, (sum, check) {
      if (check.isReady) return sum + 1;
      if (check.isReview) return sum + 0.55;
      return sum;
    });
    return (weighted / checks.length).clamp(0, 1).toDouble();
  }
}

class LaunchCheckItem {
  final String title;
  final String status;
  final String detail;
  final IconData icon;
  final Color color;

  const LaunchCheckItem({
    required this.title,
    required this.status,
    required this.detail,
    required this.icon,
    required this.color,
  });

  bool get isReady => status == 'Ready';
  bool get isReview => status == 'Review';
  bool get needsAction => status == 'Action';
}

class LaunchPlaybookSection extends StatelessWidget {
  const LaunchPlaybookSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Header(
          title: 'Launch playbook',
          subtitle: 'Final checks for a smooth first customer day',
        ),
        SizedBox(height: 12),
        _LaunchPlaybookHero(),
        SizedBox(height: 12),
        _LaunchPlaybookGrid(),
      ],
    );
  }
}

class _LaunchPlaybookHero extends StatelessWidget {
  const _LaunchPlaybookHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: FarmColors.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: FarmColors.line),
        boxShadow: [
          BoxShadow(
            color: FarmColors.shadow.withOpacity(0.045),
            blurRadius: 18,
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
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: FarmColors.green.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.verified_user_outlined,
                  color: FarmColors.green,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ready to open confidently',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Use this short playbook right before sharing the app with customers.',
                      style: TextStyle(
                        color: FarmColors.mutedText,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                      ),
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
            children: const [
              _LaunchPill(
                  label: 'Test order', icon: Icons.receipt_long_outlined),
              _LaunchPill(
                  label: 'Stock verified', icon: Icons.inventory_2_outlined),
              _LaunchPill(
                  label: 'Admin only',
                  icon: Icons.admin_panel_settings_outlined),
              _LaunchPill(
                  label: 'Phone QA', icon: Icons.phone_android_outlined),
            ],
          ),
        ],
      ),
    );
  }
}

class _LaunchPill extends StatelessWidget {
  final String label;
  final IconData icon;

  const _LaunchPill({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: FarmColors.primarySoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: FarmColors.green.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: FarmColors.green),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: FarmColors.green,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _LaunchPlaybookGrid extends StatelessWidget {
  const _LaunchPlaybookGrid();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        _LaunchPlaybookCard(
          icon: Icons.shopping_bag_outlined,
          title: 'Run one real customer order',
          detail:
              'Add an item, checkout, confirm customer order details, then verify the admin order card.',
        ),
        _LaunchPlaybookCard(
          icon: Icons.notifications_active_outlined,
          title: 'Tap both notifications',
          detail:
              'Admin New order and customer Order placed alerts should open the exact order, not a blank page.',
        ),
        _LaunchPlaybookCard(
          icon: Icons.lock_outline,
          title: 'Protect protected access',
          detail:
              'Only approved admin accounts should keep protected access before public sharing.',
        ),
        _LaunchPlaybookCard(
          icon: Icons.speed_outlined,
          title: 'Real phone smoothness check',
          detail:
              'Open Home, Shop, Product Details, My Box, Checkout, Orders, and Account on an Android phone.',
        ),
      ],
    );
  }
}

class _LaunchPlaybookCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String detail;

  const _LaunchPlaybookCard({
    required this.icon,
    required this.title,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return FarmCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
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
            child: Icon(icon, color: FarmColors.warning, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  detail,
                  style: const TextStyle(
                    color: FarmColors.mutedText,
                    height: 1.25,
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
}

class _LaunchMetricChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _LaunchMetricChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: FarmColors.mutedText,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class LaunchCheckTile extends StatelessWidget {
  final LaunchCheckItem check;

  const LaunchCheckTile({super.key, required this.check});

  @override
  Widget build(BuildContext context) {
    return FarmCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: check.color.withOpacity(0.11),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(check.icon, color: check.color, size: 22),
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
                        check.title,
                        style: const TextStyle(
                          fontSize: 16,
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
                        color: check.color.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        check.status,
                        style: TextStyle(
                          color: check.color,
                          fontSize: 11,
                          height: 1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  check.detail,
                  style: const TextStyle(
                    color: FarmColors.mutedText,
                    height: 1.28,
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
}

class _FulfillmentMetricPill extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _FulfillmentMetricPill({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: FarmColors.cardSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FarmColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: FarmColors.green),
          const SizedBox(width: 7),
          Text(
            value,
            style: const TextStyle(
              color: FarmColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: FarmColors.mutedText,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _FulfillmentSectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _FulfillmentSectionHeader({
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
            fontSize: 19,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(
            color: FarmColors.mutedText,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _FulfillmentOrderCard extends StatelessWidget {
  final AdminOrder order;
  final String status;
  final Color statusColor;
  final Future<void> Function() onPreparing;
  final Future<void> Function() onReady;
  final Future<void> Function() onComplete;
  final Future<void> Function(String status) onStatusChanged;

  const _FulfillmentOrderCard({
    required this.order,
    required this.status,
    required this.statusColor,
    required this.onPreparing,
    required this.onReady,
    required this.onComplete,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDelivery = order.fulfillmentType == 'delivery';
    final address = (order.deliveryAddress ?? order.customerAddress).trim();
    final zone = (order.deliveryZone ?? '').trim();
    final readyLabel = isDelivery ? 'Out for delivery' : 'Ready pickup';

    return FarmCard(
      margin: const EdgeInsets.only(bottom: 14),
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
                  color: statusColor.withOpacity(0.11),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  isDelivery
                      ? Icons.local_shipping_outlined
                      : Icons.storefront_outlined,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${order.shortId}',
                      style: const TextStyle(
                        color: FarmColors.ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${order.customerName} • ${order.formattedTotal}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: FarmColors.mutedText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              _FulfillmentStatusChip(
                label: _friendlyStatus(status),
                color: statusColor,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoMiniChip(
                icon: Icons.shopping_basket_outlined,
                label:
                    '${order.items.length} item${order.items.length == 1 ? '' : 's'}',
              ),
              _InfoMiniChip(
                icon: Icons.calendar_today_outlined,
                label: order.scheduleText,
              ),
              _InfoMiniChip(
                icon: isDelivery
                    ? Icons.local_shipping_outlined
                    : Icons.storefront_outlined,
                label: order.formattedType,
              ),
              _InfoMiniChip(
                icon: Icons.payment_outlined,
                label: order.formattedPaymentStatus,
              ),
            ],
          ),
          if (zone.isNotEmpty || address.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: FarmColors.primarySoft.withOpacity(0.7),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: FarmColors.green.withOpacity(0.10)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (zone.isNotEmpty)
                    Text(
                      zone,
                      style: const TextStyle(
                        color: FarmColors.green,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  if (address.isNotEmpty) ...[
                    if (zone.isNotEmpty) const SizedBox(height: 3),
                    Text(
                      address,
                      style: const TextStyle(
                        color: FarmColors.ink,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _StageButton(
                  label: 'Preparing',
                  icon: Icons.restaurant_menu_rounded,
                  onTap: onPreparing,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _StageButton(
                  label: readyLabel,
                  icon: isDelivery
                      ? Icons.delivery_dining_rounded
                      : Icons.inventory_2_outlined,
                  onTap: onReady,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onComplete,
                  icon: const Icon(Icons.done_all_rounded, size: 18),
                  label: Text(isDelivery ? 'Delivered' : 'Completed'),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: AdminDeliveryTab.deliveryStatuses.contains(status)
                      ? status
                      : 'pending',
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  items: AdminDeliveryTab.deliveryStatuses
                      .map((item) => DropdownMenuItem(
                            value: item,
                            child: Text(_friendlyStatus(item)),
                          ))
                      .toList(),
                  onChanged: (value) async {
                    if (value == null) return;
                    await onStatusChanged(value);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FulfillmentStatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _FulfillmentStatusChip({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.18)),
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

class _InfoMiniChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoMiniChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final clean = label.trim().isEmpty ? 'Not set' : label.trim();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: FarmColors.cardSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: FarmColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: FarmColors.green),
          const SizedBox(width: 5),
          Text(
            clean,
            style: const TextStyle(
              color: FarmColors.ink,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StageButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Future<void> Function() onTap;

  const _StageButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_StageButton> createState() => _StageButtonState();
}

class _StageButtonState extends State<_StageButton> {
  bool busy = false;

  Future<void> run() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await widget.onTap();
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: busy ? null : run,
      icon: busy
          ? const SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(widget.icon, size: 18),
      label: Text(
        widget.label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _CompletedFulfillmentTile extends StatelessWidget {
  final AdminOrder order;

  const _CompletedFulfillmentTile({required this.order});

  @override
  Widget build(BuildContext context) {
    return FarmCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: FarmColors.successSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.check_circle_outline_rounded,
                color: FarmColors.success),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #${order.shortId}',
                  style: const TextStyle(
                    color: FarmColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${order.customerName} • ${order.formattedType}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: FarmColors.mutedText,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Text(
            order.formattedTotal,
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

class _MiniInfoPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _MiniInfoPill({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _FarmBoxHelperScreenState extends State<FarmBoxHelperScreen> {
  final messageController = TextEditingController();
  final List<String> messages = [
    'Hi! Ask me about fresh produce, vegan ingredients, recipes, delivery, checkout, storage, budget boxes, or what to add to your farm box.',
  ];

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  void sendMessage() {
    final text = messageController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      messages.add(text);
      messages.add(_localFarmHelperReply(text));
      messageController.clear();
    });
  }

  String _localFarmHelperReply(String text) {
    final lower = text.toLowerCase();

    if (lower.contains('delivery') || lower.contains('deliver')) {
      return 'For delivery, choose Home Delivery at checkout, select your parish/zone, add your address, date, and time, then place the order. Your delivery updates will appear in your Orders screen.';
    }

    if (lower.contains('pickup') || lower.contains('collect')) {
      return 'For pickup, choose Farm Pickup at checkout, select your preferred date and time, then bring your order number when collecting your farm box.';
    }

    if (lower.contains('payment') ||
        lower.contains('pay') ||
        lower.contains('cash') ||
        lower.contains('bank')) {
      return 'Payment options depend on your checkout choice. You can use cash on pickup, cash on delivery, or bank transfer if enabled. Bank transfer orders may show as pending until the farm confirms payment.';
    }

    if (lower.contains('order') ||
        lower.contains('status') ||
        lower.contains('track')) {
      return 'To track an order, open Orders and tap the order card. You will see status, delivery or pickup details, payment status, items, and schedule information.';
    }

    if (lower.contains('trace') ||
        lower.contains('qr') ||
        lower.contains('farm')) {
      return 'Use Trace to look up a product code or tap a product detail page when trace information is available. Trace records can show farm location, harvest date, farming method, and batch notes.';
    }

    if (lower.contains('favorite') || lower.contains('like')) {
      return 'Tap the heart on a product to save it as a favorite. You can find favorite items from your Account tools and use them to shop faster next time.';
    }

    if (lower.contains('vegan') ||
        lower.contains('ingredient') ||
        lower.contains('plant')) {
      return 'For vegan choices, start with callaloo, lettuce, okra, pumpkin, peppers, herbs, fruits, and honey alternatives if needed. The Vegan Ingredient Book can help with benefits, cooking uses, and storage tips.';
    }

    if (lower.contains('budget') ||
        lower.contains('cheap') ||
        lower.contains('affordable')) {
      return 'For a budget-friendly farm box, choose 2–3 vegetables first, then add one protein or pantry item only if needed. Callaloo, lettuce, pumpkin, corn, and okra are good value picks when available.';
    }

    if (lower.contains('recipe') ||
        lower.contains('meal') ||
        lower.contains('cook') ||
        lower.contains('dinner') ||
        lower.contains('breakfast')) {
      return 'Meal idea: make a harvest bowl with callaloo or lettuce, sweet corn, peppers, herbs, and eggs if you eat them. For vegan meals, use pumpkin, okra, greens, herbs, and a light citrus dressing.';
    }

    if (lower.contains('fresh') ||
        lower.contains('today') ||
        lower.contains('best')) {
      return 'For the freshest picks, check Recently Harvested, choose products with stock available, and use trace details when shown. Greens and herbs are best used first, while pumpkin and honey keep longer.';
    }

    if (lower.contains('store') ||
        lower.contains('storage') ||
        lower.contains('keep')) {
      return 'Storage tip: keep leafy greens dry and chilled, herbs wrapped lightly, eggs refrigerated, honey sealed at room temperature, and pumpkin in a cool dry place.';
    }

    if (lower.contains('box') ||
        lower.contains('cart') ||
        lower.contains('add')) {
      return 'Tap Add or the plus button to place items in My Box. Tapping the product card opens details instead of adding, so you can review description and trace information first.';
    }

    if (lower.contains('hello') ||
        lower.contains('hi') ||
        lower.contains('help')) {
      return 'This guide can help with what to buy, how delivery works, order tracking, recipes, and building a fresh farm box for your budget.';
    }

    return 'Farm-box suggestion: choose one leafy green, one cooking vegetable, one colorful item like pepper or corn, and one add-on such as eggs or honey if it fits your needs. You can ask about recipes, delivery, order status, or vegan ingredients.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: AppBar(
        title: const Text('Farm Shopping Guide'),
        backgroundColor: FarmColors.background,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
            child: FarmCard(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionChip(
                    avatar: const Icon(Icons.eco_outlined, size: 18),
                    label: const Text('Vegan ideas'),
                    onPressed: () {
                      messageController.text =
                          'What vegan ingredients should I buy?';
                      sendMessage();
                    },
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.local_shipping_outlined, size: 18),
                    label: const Text('Delivery help'),
                    onPressed: () {
                      messageController.text = 'How does delivery work?';
                      sendMessage();
                    },
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.restaurant_menu, size: 18),
                    label: const Text('Meal plan'),
                    onPressed: () {
                      messageController.text = 'Give me a meal idea';
                      sendMessage();
                    },
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.savings_outlined, size: 18),
                    label: const Text('Budget box'),
                    onPressed: () {
                      messageController.text =
                          'Help me build a budget farm box';
                      sendMessage();
                    },
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(18),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final isUser = index.isOdd;
                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    constraints: const BoxConstraints(maxWidth: 320),
                    decoration: BoxDecoration(
                      color: isUser ? FarmColors.green : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: isUser
                          ? []
                          : [
                              BoxShadow(
                                color: FarmColors.shadow.withOpacity(0.04),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                    ),
                    child: Text(
                      messages[index],
                      style: TextStyle(
                          color: isUser ? Colors.white : FarmColors.text),
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      onSubmitted: (_) => sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Ask about produce, delivery, recipes...',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 7),
                  IconButton.filled(
                    onPressed: sendMessage,
                    icon: const Icon(Icons.send),
                    style: IconButton.styleFrom(
                      backgroundColor: FarmColors.primary,
                      foregroundColor: Colors.white,
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

class LoyaltySummaryCard extends StatelessWidget {
  const LoyaltySummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LoyaltySummary>(
      future: fetchLoyaltySummary(),
      builder: (context, snapshot) {
        final summary = snapshot.data ??
            const LoyaltySummary(points: 0, lifetimePoints: 0, tier: 'Green');
        final progress = loyaltyProgressValue(summary);
        final pointsToNext = loyaltyPointsToNextTier(summary);
        final nextTier = loyaltyNextTierName(summary);
        final tierColor = loyaltyTierColor(summary.tier);

        return Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                FarmColors.primaryDark,
                FarmColors.primary,
                FarmColors.olive.withOpacity(0.96),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: FarmColors.primaryDark.withOpacity(0.22),
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
                  Container(
                    height: 46,
                    width: 46,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.20)),
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Harvest Rewards',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${summary.tier} member • Earn as you shop',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.82),
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white.withOpacity(0.18)),
                    ),
                    child: Text(
                      summary.tier,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                '${summary.points}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  height: 0.95,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.2,
                ),
              ),
              Text(
                'points available',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.82),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.white.withOpacity(0.18),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    tierColor == FarmColors.gold
                        ? FarmColors.gold
                        : Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 7),
              Text(
                pointsToNext <= 0
                    ? 'Top tier unlocked. Thank you for supporting the farm.'
                    : '$pointsToNext points to $nextTier',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RewardsHeroCard extends StatelessWidget {
  final LoyaltySummary summary;
  final double progress;
  final int pointsToNext;
  final String nextTier;

  const _RewardsHeroCard({
    required this.summary,
    required this.progress,
    required this.pointsToNext,
    required this.nextTier,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            FarmColors.primaryDark,
            FarmColors.primary,
            FarmColors.olive.withOpacity(0.95),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: FarmColors.primaryDark.withOpacity(0.24),
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
                width: 34,
                height: 4,
                decoration: BoxDecoration(
                  color: FarmColors.accent.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Harvest Rewards',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Earn fresh perks as you shop.',
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
          const SizedBox(height: 22),
          Text(
            '${summary.points}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 54,
              height: 0.92,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.8,
            ),
          ),
          Text(
            'available points',
            style: TextStyle(
              color: Colors.white.withOpacity(0.82),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              backgroundColor: Colors.white.withOpacity(0.18),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  pointsToNext <= 0
                      ? 'Platinum unlocked'
                      : '$pointsToNext points to $nextTier',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white.withOpacity(0.18)),
                ),
                child: Text(
                  summary.tier,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
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

class _RewardMetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String helper;

  const _RewardMetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.helper,
  });

  @override
  Widget build(BuildContext context) {
    return FarmCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: FarmColors.green),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: FarmColors.ink,
            ),
          ),
          Text(
            '$label • $helper',
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

class _RewardInfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final bool isLast;

  const _RewardInfoRow({
    required this.icon,
    required this.title,
    required this.message,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              color: FarmColors.lightGreen,
              borderRadius: BorderRadius.circular(13),
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
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: FarmColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: const TextStyle(
                    color: FarmColors.mutedText,
                    fontWeight: FontWeight.w600,
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

class _RewardMilestoneCard extends StatelessWidget {
  final int points;
  final String title;
  final String description;
  final int currentLifetimePoints;

  const _RewardMilestoneCard({
    required this.points,
    required this.title,
    required this.description,
    required this.currentLifetimePoints,
  });

  @override
  Widget build(BuildContext context) {
    final unlocked = currentLifetimePoints >= points;

    return FarmCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      color: unlocked ? FarmColors.lightGreen : FarmColors.surface,
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: unlocked ? FarmColors.green : FarmColors.cardSoft,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: unlocked ? FarmColors.green : FarmColors.line,
              ),
            ),
            child: Icon(
              unlocked ? Icons.check_rounded : Icons.lock_outline_rounded,
              color: unlocked ? Colors.white : FarmColors.mutedText,
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
                    fontWeight: FontWeight.w900,
                    fontSize: 15.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: FarmColors.mutedText,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 7),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: unlocked ? Colors.white : FarmColors.primarySoft,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$points pts',
              style: TextStyle(
                color: unlocked ? FarmColors.green : FarmColors.primaryDark,
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FarmHeaderInboxButton extends StatefulWidget {
  final double size;
  final bool showBadge;

  const FarmHeaderInboxButton({
    super.key,
    this.size = 42,
    this.showBadge = true,
  });

  @override
  State<FarmHeaderInboxButton> createState() => _FarmHeaderInboxButtonState();
}

class _FarmHeaderInboxButtonState extends State<FarmHeaderInboxButton> {
  late Future<int> unreadCountFuture;

  @override
  void initState() {
    super.initState();
    _reloadUnreadCount();
  }

  void _reloadUnreadCount() {
    unreadCountFuture = widget.showBadge
        ? fetchUnreadNotificationCount()
        : Future<int>.value(0);
  }

  Future<void> _openInbox() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const NotificationsScreen(),
      ),
    );

    if (!mounted) return;

    setState(() {
      _reloadUnreadCount();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: unreadCountFuture,
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;

        return Tooltip(
          message: 'Inbox',
          child: SizedBox(
            height: widget.size,
            width: widget.size,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: Material(
                    color: Colors.white,
                    shape: const CircleBorder(),
                    elevation: 0,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _openInbox,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: FarmColors.line,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: FarmColors.shadow.withOpacity(0.07),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.notifications_none_rounded,
                          color: FarmColors.deepGreen,
                          size: 23,
                        ),
                      ),
                    ),
                  ),
                ),
                if (widget.showBadge && unreadCount > 0)
                  Positioned(
                    right: -2,
                    top: -3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: FarmColors.danger,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white,
                          width: 1.6,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: FarmColors.danger.withOpacity(0.24),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                      ),
                      child: Text(
                        unreadCount > 99 ? '99+' : '$unreadCount',
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
          ),
        );
      },
    );
  }
}

class FarmHeaderCartButton extends StatelessWidget {
  final double size;
  final int itemCount;
  final VoidCallback onPressed;

  const FarmHeaderCartButton({
    super.key,
    this.size = 38,
    required this.itemCount,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
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
              tooltip: 'My Farm Box',
              onPressed: onPressed,
              icon: const Icon(
                Icons.shopping_bag_outlined,
                color: FarmColors.deepGreen,
                size: 20,
              ),
            ),
          ),
          if (itemCount > 0)
            Positioned(
              right: -1,
              top: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: FarmColors.accent,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
                constraints: const BoxConstraints(minWidth: 18),
                child: Text(
                  itemCount > 99 ? '99+' : '$itemCount',
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
  }
}

class Header extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool showBackButton;
  final VoidCallback? onBack;
  final String? backTooltip;
  final bool showNotifications;
  final Color? notificationBadgeColor;

  const Header({
    super.key,
    required this.title,
    required this.subtitle,
    this.showBackButton = false,
    this.onBack,
    this.backTooltip,
    this.showNotifications = true,
    this.notificationBadgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(2, 6, 2, 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showBackButton) ...[
            _HeaderBackButton(
              tooltip: backTooltip ?? 'Back',
              onPressed: onBack ??
                  () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).maybePop();
                    }
                  },
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 0.8,
                    color: FarmColors.mutedText,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 27,
                    height: 1.08,
                    fontWeight: FontWeight.w900,
                    color: FarmColors.ink,
                  ),
                ),
              ],
            ),
          ),
          if (showNotifications) ...[
            const SizedBox(width: 12),
            FarmNotificationButton(
              size: 42,
              badgeColor: notificationBadgeColor ?? FarmColors.danger,
            ),
          ],
        ],
      ),
    );
  }
}

class _HeaderBackButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String tooltip;

  const _HeaderBackButton({required this.onPressed, required this.tooltip});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: FarmColors.card,
        shape: const CircleBorder(),
        elevation: 0,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: FarmColors.line),
              boxShadow: [
                BoxShadow(
                  color: FarmColors.shadow.withOpacity(0.06),
                  blurRadius: 14,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: FarmColors.ink,
              size: 21,
            ),
          ),
        ),
      ),
    );
  }
}

class HeroCard extends StatelessWidget {
  const HeroCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      height: 188,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF173526),
            Color(0xFF315B43),
            Color(0xFF3F934C),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: FarmColors.shadow.withOpacity(0.18),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              top: -34,
              child: Container(
                height: 132,
                width: 132,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.075),
                ),
              ),
            ),
            Positioned(
              right: 20,
              bottom: 16,
              child: Icon(
                Icons.eco_outlined,
                size: 86,
                color: Colors.white.withOpacity(0.075),
              ),
            ),
            Positioned(
              left: 22,
              top: 22,
              right: 22,
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Fresh from\nour fields',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      height: 1.02,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.7,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Natural food. Local harvest. Better living.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.78),
                      fontSize: 14,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  const Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _HeroTrustChip(
                        icon: Icons.eco_outlined,
                        label: 'Farm fresh',
                      ),
                      _HeroTrustChip(
                        icon: Icons.storefront_outlined,
                        label: 'Local',
                      ),
                      _HeroTrustChip(
                        icon: Icons.local_shipping_outlined,
                        label: 'Delivery',
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

class _HeroTrustChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroTrustChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class FarmSkeletonCard extends StatefulWidget {
  final double height;

  const FarmSkeletonCard({super.key, this.height = 120});

  @override
  State<FarmSkeletonCard> createState() => _FarmSkeletonCardState();
}

class _FarmSkeletonCardState extends State<FarmSkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Widget _bar({double width = double.infinity, double height = 12}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: FarmColors.primarySoft.withOpacity(0.72),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTall = widget.height >= 140;
    final isCompact = widget.height < 126;
    final showDetailBars = widget.height >= 160;
    final padding = isCompact ? 10.0 : 12.0;
    final imageSize = isTall ? 52.0 : (isCompact ? 30.0 : 38.0);
    final bottomBarHeight = isCompact ? 12.0 : 16.0;

    return FadeTransition(
      opacity: Tween<double>(begin: 0.46, end: 1).animate(controller),
      child: Container(
        height: widget.height,
        margin: const EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: FarmColors.line.withOpacity(0.72)),
          boxShadow: [
            BoxShadow(
              color: FarmColors.shadow.withOpacity(0.045),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: imageSize,
                  width: imageSize,
                  decoration: BoxDecoration(
                    color: FarmColors.cardSoft,
                    borderRadius: BorderRadius.circular(isCompact ? 14 : 18),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _bar(width: 118, height: isCompact ? 10 : 13),
                      SizedBox(height: isCompact ? 6 : 9),
                      _bar(width: 82, height: isCompact ? 8 : 10),
                    ],
                  ),
                ),
              ],
            ),
            if (showDetailBars) ...[
              const SizedBox(height: 10),
              _bar(width: double.infinity, height: 8),
              const SizedBox(height: 6),
              _bar(width: 140, height: 8),
            ],
            const Spacer(),
            Row(
              children: [
                _bar(width: isCompact ? 66 : 82, height: bottomBarHeight),
                const Spacer(),
                _bar(width: isCompact ? 38 : 48, height: bottomBarHeight),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SkeletonList extends StatelessWidget {
  final int count;
  final double height;
  final EdgeInsetsGeometry padding;

  const SkeletonList({
    super.key,
    this.count = 4,
    this.height = 120,
    this.padding = const EdgeInsets.fromLTRB(18, 18, 18, 120),
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: padding,
      itemCount: count,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => FarmSkeletonCard(height: height),
    );
  }
}

class ProductRailSkeleton extends StatelessWidget {
  final int count;
  final double height;
  final double width;

  const ProductRailSkeleton({
    super.key,
    this.count = 3,
    this.height = 224,
    this.width = 166,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        cacheExtent: AppPerformanceConfig.productRailCacheExtent,
        itemCount: count,
        separatorBuilder: (_, __) => const SizedBox(width: 7),
        itemBuilder: (_, __) => SizedBox(
          width: width,
          child: FarmSkeletonCard(height: height),
        ),
      ),
    );
  }
}

class FarmErrorState extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const FarmErrorState({
    super.key,
    this.title = 'Something went wrong',
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return FarmCard(
      color: FarmColors.dangerSoft,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.wifi_off_rounded,
                  color: FarmColors.danger,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: FarmColors.danger,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: const TextStyle(
              color: FarmColors.danger,
              height: 1.3,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.restart_alt_rounded),
              label: const Text('Try again'),
            ),
          ],
        ],
      ),
    );
  }
}

class DiscountPriceText extends StatelessWidget {
  final Product product;
  final bool compact;

  const DiscountPriceText({
    super.key,
    required this.product,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final priceText = Text(
      product.formattedEffectivePrice,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: compact ? 14.8 : 26,
        fontWeight: FontWeight.w900,
        color: product.isOutOfStock ? FarmColors.mutedText : FarmColors.green,
      ),
    );

    final originalPriceText = Text(
      product.formattedOriginalPrice,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: FarmColors.mutedText,
        fontSize: compact ? 10.4 : 12.5,
        decoration: TextDecoration.lineThrough,
        fontWeight: FontWeight.w700,
      ),
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          priceText,
          if (product.hasActiveDiscount) ...[
            const SizedBox(height: 2),
            originalPriceText,
          ],
        ],
      );
    }

    if (!product.hasActiveDiscount) {
      return priceText;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Flexible(child: priceText),
            const SizedBox(width: 7),
            Flexible(child: DiscountBadge(product: product)),
          ],
        ),
        const SizedBox(height: 3),
        originalPriceText,
      ],
    );
  }
}

class DiscountBadge extends StatelessWidget {
  final Product product;
  final bool compact;

  const DiscountBadge({
    super.key,
    required this.product,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!product.hasActiveDiscount) return const SizedBox.shrink();

    final label = compact
        ? '${product.discountPercentDisplay}% OFF'
        : (product.discountLabel ?? '').trim().isEmpty
            ? '${product.discountPercentDisplay}% OFF'
            : '${product.discountPercentDisplay}% OFF • ${product.discountLabel!.trim()}';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 9,
        vertical: compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: FarmColors.warningSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: FarmColors.warning.withOpacity(0.12)),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: FarmColors.warning,
          fontSize: compact ? 9.4 : 10.8,
          height: 1,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class NotifyMeWhenReadyButton extends StatefulWidget {
  final Product product;
  final bool compact;

  const NotifyMeWhenReadyButton({
    super.key,
    required this.product,
    this.compact = false,
  });

  @override
  State<NotifyMeWhenReadyButton> createState() =>
      _NotifyMeWhenReadyButtonState();
}

class _NotifyMeWhenReadyButtonState extends State<NotifyMeWhenReadyButton> {
  bool loading = false;
  bool subscribed = false;

  @override
  void initState() {
    super.initState();
    isSubscribedToProductReadyAlert(widget.product).then((value) {
      if (mounted) setState(() => subscribed = value);
    });
  }

  Future<void> subscribe() async {
    if (loading) return;
    setState(() => loading = true);
    try {
      final created = await subscribeToProductReadyAlert(widget.product);
      if (!mounted) return;
      setState(() => subscribed = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(created
              ? 'Alert saved for ${widget.product.name}. Check your in-app alerts when it becomes available.'
              : 'Alert already saved for ${widget.product.name}.'),
        ),
      );
      await requestBrowserNotifications();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyAppError(error))),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = subscribed
        ? 'Alert Set'
        : widget.compact
            ? 'Notify Me'
            : widget.product.isReadySoon
                ? 'Notify Me When Ready'
                : 'Notify Me When Available';

    return SizedBox(
      height: widget.compact ? 34 : 52,
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: subscribed || loading ? null : subscribe,
        icon: loading
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                subscribed
                    ? Icons.notifications_active
                    : Icons.notifications_outlined,
                size: widget.compact ? 16 : 20),
        label:
            Text(label, style: TextStyle(fontSize: widget.compact ? 12 : 14)),
        style: OutlinedButton.styleFrom(
          foregroundColor: FarmColors.green,
          side: const BorderSide(color: FarmColors.lightGreen),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(widget.compact ? 14 : 18),
          ),
        ),
      ),
    );
  }
}

class HpjWatchButton extends StatefulWidget {
  final String workspace;
  final String watchType;
  final String entityKey;
  final String entityName;
  final bool compact;
  final ValueChanged<bool>? onChanged;

  const HpjWatchButton({
    super.key,
    required this.workspace,
    required this.watchType,
    required this.entityKey,
    required this.entityName,
    this.compact = false,
    this.onChanged,
  });

  @override
  State<HpjWatchButton> createState() => _HpjWatchButtonState();
}

class _HpjWatchButtonState extends State<HpjWatchButton> {
  bool loading = true;
  bool saving = false;
  bool watching = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant HpjWatchButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entityKey != widget.entityKey ||
        oldWidget.workspace != widget.workspace ||
        oldWidget.watchType != widget.watchType) {
      _load();
    }
  }

  Future<void> _load() async {
    if (mounted) setState(() => loading = true);
    final value = await isHpjWatchActive(
      workspace: widget.workspace,
      watchType: widget.watchType,
      entityKey: widget.entityKey,
    );
    if (!mounted) return;
    setState(() {
      watching = value;
      loading = false;
    });
  }

  Future<void> _toggle() async {
    if (saving || loading) return;
    if (!isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to watch updates.')),
      );
      return;
    }

    final next = !watching;
    setState(() => saving = true);
    try {
      await setHpjWatchActive(
        workspace: widget.workspace,
        watchType: widget.watchType,
        entityKey: widget.entityKey,
        entityName: widget.entityName,
        active: next,
      );
      if (!mounted) return;
      setState(() => watching = next);
      widget.onChanged?.call(next);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            next
                ? 'Watching ${widget.entityName}. HPJ will surface useful changes.'
                : 'Stopped watching ${widget.entityName}.',
          ),
        ),
      );
      if (next) {
        unawaited(requestBrowserNotifications());
      }
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
    final label = watching ? 'Watching' : 'Watch';
    final icon =
        watching ? Icons.visibility_rounded : Icons.visibility_outlined;

    return SizedBox(
      height: widget.compact ? 34 : 46,
      child: OutlinedButton.icon(
        onPressed: loading || saving ? null : _toggle,
        icon: loading || saving
            ? SizedBox(
                width: widget.compact ? 13 : 15,
                height: widget.compact ? 13 : 15,
                child: const CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon, size: widget.compact ? 16 : 19),
        label: Text(
          loading ? 'Checking' : label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: widget.compact ? 11.3 : 13.2,
            fontWeight: FontWeight.w900,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: watching ? FarmColors.primary : FarmColors.green,
          backgroundColor: watching ? FarmColors.primarySoft : Colors.white,
          side: BorderSide(
            color: watching
                ? FarmColors.primary.withOpacity(0.28)
                : FarmColors.line,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 9 : 13,
            vertical: widget.compact ? 7 : 10,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(widget.compact ? 14 : 16),
          ),
        ),
      ),
    );
  }
}

class ReadySoonRail extends StatelessWidget {
  final List<Product> products;
  final void Function(Product product) onViewed;

  const ReadySoonRail({
    super.key,
    required this.products,
    required this.onViewed,
  });

  void _openProduct(BuildContext context, Product product) {
    onViewed(product);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(
          product: product,
          quantity: 0,
          onAdd: () {},
          onRemove: () {},
          onViewed: onViewed,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visible = products
        .where((product) =>
            product.approvalStatus == 'approved' &&
            !product.isHidden &&
            product.isReadySoon)
        .toList();

    if (visible.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Harvesting Soon',
          subtitle: 'Get notified when the next harvest is ready',
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 172,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            cacheExtent: AppPerformanceConfig.productRailCacheExtent,
            itemCount: visible.length,
            separatorBuilder: (_, __) => const SizedBox(width: 7),
            itemBuilder: (context, index) {
              final product = visible[index];
              return ReadySoonProductTile(
                product: product,
                onOpen: () => _openProduct(context, product),
              );
            },
          ),
        ),
      ],
    );
  }
}

class ReadySoonProductTile extends StatelessWidget {
  final Product product;
  final VoidCallback onOpen;
  final double width;

  const ReadySoonProductTile({
    super.key,
    required this.product,
    required this.onOpen,
    this.width = 272,
  });

  @override
  Widget build(BuildContext context) {
    final farm = [product.farmName, product.farmerName, product.parish]
        .where((item) => (item ?? '').trim().isNotEmpty)
        .join(' • ');
    final expectedStock = product.expectedStockQuantity ?? 0;

    return SizedBox(
      width: width,
      height: 172,
      child: FarmCard(
        padding: EdgeInsets.zero,
        color: FarmColors.card,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onOpen,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                SizedBox(
                  height: 112,
                  width: 96,
                  child:
                      Center(child: ProductVisual(product: product, size: 74)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: FarmColors.warningSoft,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'Coming soon',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: FarmColors.warning,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          height: 1.08,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        farm.isEmpty ? product.readySoonLabel : farm,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: FarmColors.green,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                      if (expectedStock > 0) ...[
                        const SizedBox(height: 3),
                        Text(
                          '$expectedStock expected',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: FarmColors.mutedText,
                            fontSize: 10.2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 32,
                        child: NotifyMeWhenReadyButton(
                          product: product,
                          compact: true,
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

class DealOfTheDaySection extends StatefulWidget {
  final void Function(Product product) onViewed;
  final void Function(Product product)? onAddProduct;
  final VoidCallback? onViewMyBox;
  final VoidCallback? onCheckout;
  final bool compact;

  const DealOfTheDaySection({
    super.key,
    required this.onViewed,
    this.onAddProduct,
    this.onViewMyBox,
    this.onCheckout,
    this.compact = false,
  });

  @override
  State<DealOfTheDaySection> createState() => _DealOfTheDaySectionState();
}

class _DealOfTheDaySectionState extends State<DealOfTheDaySection> {
  late Future<List<Product>> dealsFuture;

  @override
  void initState() {
    super.initState();
    dealsFuture = fetchDealOfTheDayProducts();
  }

  void openProduct(BuildContext context, Product product) {
    widget.onViewed(product);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(
          product: product,
          quantity: 0,
          onAdd: () => widget.onAddProduct?.call(product),
          onRemove: () {},
          onAddProduct: widget.onAddProduct,
          onViewed: widget.onViewed,
          onViewMyBox: widget.onViewMyBox,
          onCheckout: widget.onCheckout,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Product>>(
      future: dealsFuture,
      builder: (context, snapshot) {
        final deals = snapshot.data ?? [];
        if (deals.isEmpty) return const SizedBox.shrink();
        final featured = deals.first;
        final remaining = deals.skip(1).take(6).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: const [
                Expanded(child: SectionTitle("Today's Deal")),
                Icon(Icons.local_offer_outlined, color: FarmColors.warning),
              ],
            ),
            const SizedBox(height: 8),
            InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () => openProduct(context, featured),
              child: FarmCard(
                color: FarmColors.warningSoft,
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      height: widget.compact ? 86 : 96,
                      width: widget.compact ? 112 : 128,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.82),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: FarmColors.warning.withOpacity(0.10),
                        ),
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: ProductVisual(
                              product: featured,
                              size: widget.compact ? 76 : 88,
                            ),
                          ),
                          if (featured.hasActiveDiscount &&
                              !featured.isOutOfStock)
                            Positioned(
                              top: 7,
                              right: 7,
                              child: DiscountBadge(
                                product: featured,
                                compact: true,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            featured.discountLabel?.trim().isNotEmpty == true
                                ? featured.discountLabel!.trim()
                                : 'Fresh market special',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: FarmColors.warning,
                              fontSize: 12,
                              height: 1.18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 7,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              ProductOriginBadge(
                                product: featured,
                                compact: true,
                              ),
                              if (featured.showAsDealOfDay)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.68),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color:
                                          FarmColors.warning.withOpacity(0.14),
                                    ),
                                  ),
                                  child: const Text(
                                    'Sale',
                                    style: TextStyle(
                                      color: FarmColors.warning,
                                      fontSize: 10.8,
                                      height: 1,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.72),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chevron_right,
                        color: FarmColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (remaining.isNotEmpty) ...[
              const SizedBox(height: 10),
              ProductMiniRail(
                products: remaining,
                onProductTap: (product) => openProduct(context, product),
              ),
            ],
          ],
        );
      },
    );
  }
}

class SubscribeSaveButton extends StatefulWidget {
  final Product product;
  final bool compact;

  const SubscribeSaveButton({
    super.key,
    required this.product,
    this.compact = false,
  });

  @override
  State<SubscribeSaveButton> createState() => _SubscribeSaveButtonState();
}

class _SubscribeSaveButtonState extends State<SubscribeSaveButton> {
  bool loading = false;
  bool checking = true;
  CustomerProductSubscription? plan;
  int intervalDays = 7;

  @override
  void initState() {
    super.initState();
    loadPlan();
  }

  Future<void> loadPlan() async {
    final existing = await fetchActiveSubscriptionForProduct(widget.product);
    if (!mounted) return;
    setState(() {
      plan = existing;
      intervalDays = existing?.intervalDays ?? 7;
      checking = false;
    });
  }

  Future<void> subscribe() async {
    if (loading) return;
    setState(() => loading = true);
    try {
      final created = await subscribeToSaveProduct(
        widget.product,
        intervalDays: intervalDays,
      );
      final freshPlan = await fetchActiveSubscriptionForProduct(widget.product);
      if (!mounted) return;
      setState(() => plan = freshPlan);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(created
              ? 'Fresh Box Plan started for ${widget.product.name}.'
              : 'You already have a Fresh Box Plan for ${widget.product.name}.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyAppError(error))),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> pausePlan() async {
    final current = plan;
    if (current == null || loading) return;
    setState(() => loading = true);
    try {
      await updateCustomerSubscriptionStatus(
        subscription: current,
        status: 'paused',
      );
      await loadPlan();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fresh Box Plan paused.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyAppError(error))),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.product.hasSubscribeSave) return const SizedBox.shrink();

    final activePlan = plan;
    final isActive = activePlan?.isActive == true;
    final isPaused = activePlan?.isPaused == true;
    final discount =
        widget.product.subscribeSavePercentValue.toStringAsFixed(0);

    return FarmCard(
      color: FarmColors.successSoft,
      padding: EdgeInsets.all(widget.compact ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.event_repeat_outlined,
                  color: FarmColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isActive
                          ? 'Fresh Box Plan active'
                          : isPaused
                              ? 'Fresh Box Plan paused'
                              : 'Fresh Box Plan',
                      style: const TextStyle(
                        color: FarmColors.success,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isActive || isPaused
                          ? '${activePlan!.repeatLabel} • ${activePlan.savingsLabel}'
                          : 'Never miss your fresh picks. Save $discount% and repeat this item on your schedule.',
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
          const SizedBox(height: 12),
          if (checking)
            const LinearProgressIndicator(minHeight: 3)
          else if (activePlan != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.72),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: FarmColors.success.withOpacity(0.12)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _PlanMetric(
                      label: 'Next reminder',
                      value: activePlan.nextOrderLabel,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: _PlanMetric(
                      label: 'Repeat',
                      value: activePlan.repeatLabel,
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
                    onPressed: loading || !isActive ? null : pausePlan,
                    icon: const Icon(Icons.pause_circle_outline),
                    label: const Text('Pause'),
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: loading
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const CustomerSubscriptionsScreen(),
                              ),
                            );
                          },
                    icon: const Icon(Icons.tune_outlined),
                    label: const Text('Manage'),
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: const [
                _FreshPlanBenefit(
                    icon: Icons.savings_outlined,
                    label: 'Save on repeat orders'),
                SizedBox(width: 8),
                _FreshPlanBenefit(
                    icon: Icons.pause_outlined, label: 'Pause anytime'),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${widget.product.formattedSubscribeSavePrice} per repeat order. You confirm before each order is placed.',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: intervalDays,
                    decoration:
                        const InputDecoration(labelText: 'Repeat every'),
                    items: const [
                      DropdownMenuItem(value: 7, child: Text('Week')),
                      DropdownMenuItem(value: 14, child: Text('2 weeks')),
                      DropdownMenuItem(value: 30, child: Text('Month')),
                    ],
                    onChanged: loading
                        ? null
                        : (value) => setState(() => intervalDays = value ?? 7),
                  ),
                ),
                const SizedBox(width: 7),
                ElevatedButton.icon(
                  onPressed: loading ? null : subscribe,
                  icon: loading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.event_repeat_outlined),
                  label: const Text('Start'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _FreshPlanBenefit extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FreshPlanBenefit({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.62),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: FarmColors.success, size: 15),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: FarmColors.success,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanMetric extends StatelessWidget {
  final String label;
  final String value;

  const _PlanMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: FarmColors.mutedText,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: FarmColors.ink,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class FrequentlyBoughtTogetherSection extends StatelessWidget {
  final Product product;
  final void Function(Product product)? onAddProduct;
  final void Function(Product product)? onViewed;
  final VoidCallback? onViewMyBox;
  final VoidCallback? onCheckout;

  const FrequentlyBoughtTogetherSection({
    super.key,
    required this.product,
    this.onAddProduct,
    this.onViewed,
    this.onViewMyBox,
    this.onCheckout,
  });

  void openProduct(BuildContext context, Product item) {
    onViewed?.call(item);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(
          product: item,
          quantity: 0,
          onAdd: () => onAddProduct?.call(item),
          onRemove: () {},
          onAddProduct: onAddProduct,
          onViewed: onViewed,
          onViewMyBox: onViewMyBox,
          onCheckout: onCheckout,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Product>>(
      future: fetchFrequentlyBoughtTogetherProducts(product),
      builder: (context, snapshot) {
        final related = snapshot.data ?? [];
        if (related.isEmpty) return const SizedBox.shrink();
        final bundle = related.take(3).toList();
        final bundleTotal = bundle.fold<double>(
          product.effectivePrice,
          (sum, item) => sum + item.effectivePrice,
        );

        final visibleBundle = bundle.take(2).toList();

        return FarmCard(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Frequently Bought Together',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                'Easy pairings for your farm box.',
                style: TextStyle(
                  color: FarmColors.mutedText,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              _BundleProductRow(product: product, label: 'This item'),
              ...visibleBundle.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => openProduct(context, item),
                    child: _BundleProductRow(product: item),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: FarmColors.primarySoft,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: FarmColors.line),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bundle total',
                            style: TextStyle(
                              color: FarmColors.mutedText,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            formatJmd(bundleTotal),
                            style: const TextStyle(
                              color: FarmColors.green,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (onAddProduct != null)
                      _AddBundleButton(
                        product: product,
                        bundle: visibleBundle,
                        onAddProduct: onAddProduct!,
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

class _AddBundleButton extends StatefulWidget {
  final Product product;
  final List<Product> bundle;
  final void Function(Product product) onAddProduct;

  const _AddBundleButton({
    required this.product,
    required this.bundle,
    required this.onAddProduct,
  });

  @override
  State<_AddBundleButton> createState() => _AddBundleButtonState();
}

class _AddBundleButtonState extends State<_AddBundleButton> {
  bool _isAdding = false;

  Future<void> _handleAddBundle() async {
    if (_isAdding) return;

    setState(() => _isAdding = true);

    try {
      widget.onAddProduct(widget.product);
      for (final item in widget.bundle) {
        widget.onAddProduct(item);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bundle added to your box')),
        );
      }

      await Future<void>.delayed(const Duration(milliseconds: 450));
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 110),
      scale: _isAdding ? 0.98 : 1,
      child: ElevatedButton.icon(
        onPressed: _isAdding ? null : _handleAddBundle,
        style: ElevatedButton.styleFrom(
          disabledBackgroundColor: FarmColors.green.withOpacity(0.78),
          disabledForegroundColor: Colors.white,
        ),
        icon: _isAdding
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.add_shopping_cart_outlined),
        label: AnimatedSwitcher(
          duration: const Duration(milliseconds: 160),
          child: Text(
            _isAdding ? 'Adding bundle...' : 'Add Bundle',
            key: ValueKey<bool>(_isAdding),
          ),
        ),
      ),
    );
  }
}

class _BundleProductRow extends StatelessWidget {
  final Product product;
  final String? label;

  const _BundleProductRow({required this.product, this.label});

  @override
  Widget build(BuildContext context) {
    final title = label ?? product.name;
    final subtitle = label == null ? product.category : product.name;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: FarmColors.cardSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FarmColors.line),
      ),
      child: Row(
        children: [
          ProductVisual(product: product, size: 46),
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
                    fontSize: 13,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: FarmColors.mutedText,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 7),
          Text(
            product.formattedEffectivePrice,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: FarmColors.green,
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class RecommendedForYouDetailSection extends StatelessWidget {
  final Product currentProduct;
  final void Function(Product product)? onAddProduct;
  final void Function(Product product)? onViewed;
  final VoidCallback? onViewMyBox;
  final VoidCallback? onCheckout;

  const RecommendedForYouDetailSection({
    super.key,
    required this.currentProduct,
    this.onAddProduct,
    this.onViewed,
    this.onViewMyBox,
    this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Product>>(
      future: fetchProducts(),
      builder: (context, snapshot) {
        final sourceProducts = snapshot.data ?? const <Product>[];
        final recommended = buildRecommendedForYouProducts(
          allProducts: sourceProducts,
          recentlyViewedProducts: const [],
          buyAgainProducts: const [],
          favoriteProducts: const [],
          selectedCategory: currentProduct.category,
          excludeIds: {currentProduct.id},
        );

        if (snapshot.connectionState == ConnectionState.waiting &&
            recommended.isEmpty) {
          return const FarmSkeletonCard(height: 150);
        }

        if (recommended.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              title: 'Recommended for You',
              subtitle: 'More fresh picks that pair well with this item',
            ),
            const SizedBox(height: 10),
            ProductMiniRail(
              products: recommended,
              onProductTap: (recommendedProduct) {
                onViewed?.call(recommendedProduct);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductDetailScreen(
                      product: recommendedProduct,
                      quantity: 0,
                      onAdd: () => onAddProduct?.call(recommendedProduct),
                      onRemove: () {},
                      onAddProduct: onAddProduct,
                      onViewed: onViewed,
                      onViewMyBox: onViewMyBox,
                      onCheckout: onCheckout,
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final VoidCallback? onIncrease;
  final VoidCallback? onDecrease;
  final VoidCallback? onFavorite;
  final VoidCallback? onViewed;
  final bool isFavorite;
  final int quantity;

  const ProductCard({
    super.key,
    required this.product,
    required this.onAdd,
    required this.onRemove,
    this.onIncrease,
    this.onDecrease,
    this.onFavorite,
    this.onViewed,
    this.isFavorite = false,
    this.quantity = 0,
  });

  @override
  Widget build(BuildContext context) {
    final inStock = product.canAddToCart;
    final muted = product.isOutOfStock;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          onViewed?.call();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(
                product: product,
                quantity: quantity,
                onAdd: onIncrease ?? onAdd,
                onRemove: onDecrease ?? onRemove,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: muted ? FarmColors.cardSoft : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: muted
                  ? FarmColors.danger.withOpacity(0.13)
                  : FarmColors.line.withOpacity(0.88),
            ),
            boxShadow: [
              BoxShadow(
                color: FarmColors.shadow.withOpacity(muted ? 0.025 : 0.055),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Opacity(
            opacity: muted ? 0.82 : 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: Center(
                          child: Hero(
                            tag: 'product-${product.id}',
                            child: ProductVisual(product: product, size: 76),
                          ),
                        ),
                      ),
                      if (product.hasActiveDiscount && !product.isOutOfStock)
                        Positioned(
                          top: 5,
                          left: 5,
                          child: DiscountBadge(product: product, compact: true),
                        ),
                      if (onFavorite != null)
                        Positioned(
                          top: 5,
                          right: 5,
                          child: SizedBox(
                            width: 34,
                            height: 34,
                            child: Material(
                              color: isFavorite
                                  ? FarmColors.dangerSoft
                                  : Colors.white.withOpacity(0.94),
                              shape: const CircleBorder(),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: onFavorite,
                                child: Icon(
                                  isFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  size: 18,
                                  color: isFavorite
                                      ? FarmColors.danger
                                      : FarmColors.green,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                _HomeProductName(product: product, compact: true),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 5,
                  children: [
                    ProductOriginBadge(
                      product: product,
                      compact: true,
                      includeIcon: false,
                    ),
                    ProductUnitChip(product: product, compact: true),
                  ],
                ),
                const SizedBox(height: 3),
                _HomePricePanel(product: product, compact: true),
                ProductAvailabilityChip(product: product, compact: true),
                const SizedBox(height: 8),
                if (quantity <= 0)
                  inStock
                      ? SizedBox(
                          height: 38,
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: onAdd,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: FarmColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                          ),
                        )
                      : NotifyMeWhenReadyButton(product: product, compact: true)
                else
                  Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: FarmColors.lightGreen,
                      borderRadius: BorderRadius.circular(15),
                      border:
                          Border.all(color: FarmColors.green.withOpacity(0.10)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            onPressed: onDecrease ?? onRemove,
                            icon: const Icon(Icons.remove, size: 18),
                            color: FarmColors.green,
                          ),
                        ),
                        Text(
                          '$quantity',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: FarmColors.green,
                          ),
                        ),
                        Expanded(
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            onPressed: inStock ? (onIncrease ?? onAdd) : null,
                            icon: const Icon(Icons.add, size: 18),
                            color: FarmColors.green,
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

class OrganicImageStamp extends StatelessWidget {
  final bool compact;

  const OrganicImageStamp({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final size = compact ? 22.0 : 26.0;

    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.97),
        shape: BoxShape.circle,
        border: Border.all(color: FarmColors.line, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        Icons.eco_outlined,
        size: compact ? 12 : 14,
        color: FarmColors.green,
      ),
    );
  }
}

class ProductVisual extends StatelessWidget {
  final Product product;
  final double size;
  final bool showOrganicBadge;

  const ProductVisual({
    super.key,
    required this.product,
    required this.size,
    this.showOrganicBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = cleanHostedImageUrl(product.imageUrl);
    final visualSize = size + (size >= 70 ? 24 : 18);

    Widget fallbackVisual() {
      return SizedBox(
        height: visualSize,
        width: visualSize,
        child: Icon(
          Icons.image_outlined,
          size: (size * 0.58).clamp(18.0, 44.0).toDouble(),
          color: FarmColors.mutedText.withOpacity(0.72),
        ),
      );
    }

    Widget visualContent;

    if (imageUrl == null) {
      visualContent = fallbackVisual();
    } else {
      visualContent = SizedBox(
        height: visualSize,
        width: visualSize,
        child: Center(
          child: Image.network(
            imageUrl,
            height: visualSize,
            width: visualSize,
            fit: BoxFit.contain,
            cacheWidth: visualSize.round() * 2,
            gaplessPlayback: true,
            filterQuality: FilterQuality.medium,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const Center(
                child: SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            },
            errorBuilder: (_, __, ___) => fallbackVisual(),
          ),
        ),
      );
    }

    if (product.isOutOfStock) {
      visualContent = Opacity(opacity: 0.58, child: visualContent);
    }

    if (!showOrganicBadge) return visualContent;

    return SizedBox(
      height: visualSize,
      width: visualSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          visualContent,
          if (product.isOrganic)
            const Positioned(
              top: 6,
              left: 6,
              child: OrganicImageStamp(),
            ),
        ],
      ),
    );
  }
}

class FarmCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final Color? color;

  const FarmCard({
    super.key,
    required this.child,
    this.margin,
    this.padding,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: margin,
        padding: padding ?? const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color ?? FarmColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: FarmColors.line,
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.035),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String text;

  const SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontSize: 20,
        height: 1.05,
        fontWeight: FontWeight.w900,
        color: FarmColors.ink,
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.actionLabel,
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
              SectionTitle(title),
              const SizedBox(height: 1),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: FarmColors.mutedText,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 30),
              padding: const EdgeInsets.symmetric(horizontal: 7),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: onAction,
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}

// ============================================================================
// VISUAL-FIRST PRODUCE IDENTIFICATION
// Reusable thumbnail for farmer/wholesale workflows where a product may be
// represented only by product id/name. The text label must remain visible too;
// the image is an accessibility aid, not the only identifier.
// ============================================================================

String _hpjProductVisualKey(String value) {
  return value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
}

final Map<String, Future<Product?>> _hpjProductVisualLookupCache =
    <String, Future<Product?>>{};

Future<Product?> _hpjLookupProductForVisual({
  String? productId,
  required String productName,
}) {
  final cleanId = productId?.trim() ?? '';
  final cleanName = productName.trim();
  final key = cleanId.isNotEmpty
      ? 'id:$cleanId'
      : 'name:${_hpjProductVisualKey(cleanName)}';

  return _hpjProductVisualLookupCache.putIfAbsent(
    key,
    () async {
      try {
        final products = await fetchProducts();

        if (cleanId.isNotEmpty) {
          for (final product in products) {
            if (product.id == cleanId) return product;
          }
        }

        final wanted = _hpjProductVisualKey(cleanName);
        if (wanted.isNotEmpty) {
          for (final product in products) {
            if (_hpjProductVisualKey(product.name) == wanted) {
              return product;
            }
          }
        }
      } catch (error) {
        farmDebugLog('Product visual lookup unavailable: $error');
      }

      return null;
    },
  );
}

class HpjProductThumb extends StatelessWidget {
  final Product? product;
  final String? productId;
  final String productName;
  final double size;
  final double radius;
  final IconData fallbackIcon;

  const HpjProductThumb({
    super.key,
    this.product,
    this.productId,
    required this.productName,
    this.size = 68,
    this.radius = 14,
    this.fallbackIcon = Icons.eco_outlined,
  });

  Widget _fallback() {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: FarmColors.primarySoft,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: FarmColors.line.withOpacity(.75)),
      ),
      child: Icon(
        fallbackIcon,
        color: FarmColors.primary,
        size: (size * .38).clamp(20.0, 34.0).toDouble(),
      ),
    );
  }

  Widget _buildProduct(Product resolved) {
    final imageUrl = cleanHostedImageUrl(resolved.imageUrl);
    if (imageUrl == null) return _fallback();

    return Semantics(
      image: true,
      label: '$productName produce',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: FarmColors.line.withOpacity(.75)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.network(
          imageUrl,
          width: size,
          height: size,
          fit: BoxFit.contain,
          cacheWidth: (size * 2).round(),
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: FarmColors.primary.withOpacity(.75),
                ),
              ),
            );
          },
          errorBuilder: (_, __, ___) => _fallback(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (product != null) {
      return _buildProduct(product!);
    }

    return FutureBuilder<Product?>(
      future: _hpjLookupProductForVisual(
        productId: productId,
        productName: productName,
      ),
      builder: (context, snapshot) {
        final resolved = snapshot.data;
        if (resolved == null) return _fallback();
        return _buildProduct(resolved);
      },
    );
  }
}

Future<Product?> showHpjProductPicturePicker(
  BuildContext context, {
  String title = 'Choose produce',
  List<Product>? products,
}) async {
  List<Product> available;

  try {
    available = products ?? await fetchProducts();
  } catch (error) {
    if (!context.mounted) return null;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(friendlyAppError(error))),
    );
    return null;
  }

  final eligible = available
      .where((product) => product.isApproved && !product.isHidden)
      .toList()
    ..sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );

  if (!context.mounted) return null;

  return showModalBottomSheet<Product>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _HpjProductPicturePickerSheet(
      title: title,
      products: eligible,
    ),
  );
}

class _HpjProductPicturePickerSheet extends StatefulWidget {
  final String title;
  final List<Product> products;

  const _HpjProductPicturePickerSheet({
    required this.title,
    required this.products,
  });

  @override
  State<_HpjProductPicturePickerSheet> createState() =>
      _HpjProductPicturePickerSheetState();
}

class _HpjProductPicturePickerSheetState
    extends State<_HpjProductPicturePickerSheet> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final wanted = query.trim().toLowerCase();
    final visible = wanted.isEmpty
        ? widget.products
        : widget.products
            .where(
              (product) =>
                  product.name.toLowerCase().contains(wanted) ||
                  product.category.toLowerCase().contains(wanted),
            )
            .toList();

    return FractionallySizedBox(
      heightFactor: .86,
      child: Container(
        decoration: const BoxDecoration(
          color: FarmColors.background,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(26),
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: FarmColors.line,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            color: FarmColors.ink,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'Tap the picture of the produce you want.',
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
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search (optional)',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
                onChanged: (value) {
                  setState(() {
                    query = value;
                  });
                },
              ),
            ),
            Expanded(
              child: visible.isEmpty
                  ? const Center(
                      child: FarmEmptyState(
                        icon: Icons.image_search_outlined,
                        title: 'No matching produce',
                        message: 'Try another name or clear the search.',
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 2, 16, 24),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1.12,
                      ),
                      itemCount: visible.length,
                      itemBuilder: (context, index) {
                        final product = visible[index];

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: () => Navigator.of(context).pop(product),
                            child: Ink(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: FarmColors.card,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: FarmColors.line),
                              ),
                              child: Row(
                                children: [
                                  HpjProductThumb(
                                    product: product,
                                    productName: product.name,
                                    size: 72,
                                    radius: 14,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      product.name,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: FarmColors.ink,
                                        fontSize: 12.5,
                                        height: 1.15,
                                        fontWeight: FontWeight.w900,
                                      ),
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
    );
  }
}

Color categoryAccentColorForName(String category) {
  final lower = category.trim().toLowerCase();

  if (lower.contains('fruit')) return FarmColors.danger;
  if (lower.contains('ground')) return FarmColors.warning;
  if (lower.contains('herb')) return FarmColors.olive;
  if (lower.contains('egg')) return FarmColors.gold;
  if (lower.contains('honey')) return FarmColors.warning;
  if (lower.contains('dairy')) return FarmColors.primaryDark;
  if (lower.contains('drink')) return FarmColors.primary;
  if (lower.contains('prepared')) return FarmColors.accent;

  return FarmColors.green;
}

class CategoryPill extends StatelessWidget {
  final Product? previewProduct;
  final IconData fallbackIcon;
  final String label;
  final int? count;
  final VoidCallback? onTap;

  const CategoryPill({
    super.key,
    this.previewProduct,
    this.fallbackIcon = Icons.category_outlined,
    required this.label,
    this.count,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cleanCount = count ?? 0;
    final countText = cleanCount == 1
        ? '1 item'
        : cleanCount > 1
            ? '$cleanCount items'
            : 'Browse items';
    final imageUrl = cleanHostedImageUrl(previewProduct?.imageUrl);
    final accent = categoryAccentColorForName(label);

    Widget preview() {
      final fallback = Icon(
        fallbackIcon,
        size: 24,
        color: accent,
      );

      if (imageUrl == null) return fallback;

      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          imageUrl,
          height: 34,
          width: 34,
          fit: BoxFit.contain,
          cacheWidth: 140,
          gaplessPlayback: true,
          errorBuilder: (_, __, ___) => fallback,
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.white,
                FarmColors.primarySoft.withOpacity(0.50),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: FarmColors.line.withOpacity(0.86)),
            boxShadow: [
              BoxShadow(
                color: FarmColors.shadow.withOpacity(0.045),
                blurRadius: 14,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.09),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: preview(),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      style: const TextStyle(
                        color: FarmColors.ink,
                        fontSize: 12.0,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                        letterSpacing: -0.08,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.86),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        countText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: FarmColors.mutedText,
                          fontSize: 9.8,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                height: 24,
                width: 24,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.90),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: accent,
                  size: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TraceRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const TraceRow({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: FarmColors.green),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(value),
    );
  }
}

class OrderCard extends StatelessWidget {
  final String order;
  final String status;
  final String type;
  final String total;
  final VoidCallback? onTap;

  const OrderCard({
    super.key,
    required this.order,
    required this.status,
    required this.type,
    required this.total,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: FarmCard(
        margin: const EdgeInsets.only(bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Order $order',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Chip(
                    label: Text(
                      status,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    backgroundColor: FarmColors.lightGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              type,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text('Tap to view receipt and tracking'),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Total'),
                const Spacer(),
                Flexible(
                  child: Text(
                    total,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
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

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  bool loading = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    final user = supabase.auth.currentUser;
    final profile = await fetchCurrentCustomerProfile();
    if (!mounted) return;
    setState(() {
      nameController.text = profile?.fullName ??
          user?.userMetadata?['full_name']?.toString() ??
          '';
      phoneController.text = profile?.phone ?? '';
      addressController.text = profile?.address ?? '';
      loading = false;
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    super.dispose();
  }

  bool get hasName => nameController.text.trim().isNotEmpty;
  bool get hasPhone => phoneController.text.trim().isNotEmpty;
  bool get hasAddress => addressController.text.trim().isNotEmpty;
  bool get isCheckoutReady => hasName && hasPhone;

  Future<void> saveProfile() async {
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();
    final address = addressController.text.trim();

    if (name.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and phone are required.')),
      );
      return;
    }

    setState(() => saving = true);
    try {
      await saveCurrentCustomerProfile(
        fullName: name,
        phone: phone,
        address: address,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved for faster checkout.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Could not save profile: ${friendlyAppError(error)}')),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> copyProfileSummary() async {
    final name = nameController.text.trim();
    final phone = phoneController.text.trim();
    final address = addressController.text.trim();
    final parts = <String>[
      if (name.isNotEmpty) 'Name: $name',
      if (phone.isNotEmpty) 'Phone: $phone',
      if (address.isNotEmpty) 'Address: $address',
    ];

    if (parts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add your details before copying.')),
      );
      return;
    }

    await Clipboard.setData(ClipboardData(text: parts.join('\n')));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile summary copied.')),
    );
  }

  Widget _readinessPill({
    required IconData icon,
    required String label,
    required bool ready,
  }) {
    final color = ready ? FarmColors.success : FarmColors.warning;
    final background = ready ? FarmColors.successSoft : FarmColors.warningSoft;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
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

  Widget _profileBenefit({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FarmColors.cardSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: FarmColors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: FarmColors.lightGreen,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: FarmColors.green, size: 20),
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
                    height: 1.25,
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

  @override
  Widget build(BuildContext context) {
    if (!isLoggedIn) {
      return const GuestProtectedScreen(
        title: 'Profile',
        subtitle: 'Saved customer details',
        message: 'Sign in to save and manage your customer profile.',
      );
    }

    final readyCount = [hasName, hasPhone, hasAddress].where((v) => v).length;
    final readinessText = isCheckoutReady
        ? 'Checkout ready'
        : 'Add name and phone to speed up checkout';

    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Profile'),
        backgroundColor: FarmColors.background,
      ),
      body: loading
          ? const SkeletonList(count: 3)
          : SafeArea(
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [FarmColors.deepGreen, FarmColors.green],
                      ),
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: FarmColors.green.withOpacity(0.22),
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
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.16),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.18),
                                ),
                              ),
                              child: const Icon(
                                Icons.person_outline,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 11, vertical: 7),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.14),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '$readyCount/3 saved',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Your checkout profile',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          readinessText,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.88),
                            fontSize: 14.5,
                            height: 1.35,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _readinessPill(
                              icon: Icons.badge_outlined,
                              label: hasName ? 'Name saved' : 'Name needed',
                              ready: hasName,
                            ),
                            _readinessPill(
                              icon: Icons.phone_outlined,
                              label: hasPhone ? 'Phone saved' : 'Phone needed',
                              ready: hasPhone,
                            ),
                            _readinessPill(
                              icon: Icons.location_on_outlined,
                              label: hasAddress
                                  ? 'Address saved'
                                  : 'Address optional',
                              ready: hasAddress,
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
                          title: 'Saved details',
                          subtitle:
                              'Used to prefill checkout and help the farm contact you about orders.',
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: nameController,
                          textCapitalization: TextCapitalization.words,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            labelText: 'Full name',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            labelText: 'Phone number',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: addressController,
                          maxLines: 3,
                          textCapitalization: TextCapitalization.sentences,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            labelText: 'Default delivery address',
                            alignLabelWithHint: true,
                            prefixIcon: Icon(Icons.location_on_outlined),
                          ),
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
                        const AccountSectionHeading(
                          title: 'Why save this?',
                          subtitle:
                              'Small details that make ordering smoother.',
                        ),
                        const SizedBox(height: 14),
                        _profileBenefit(
                          icon: Icons.flash_on_outlined,
                          title: 'Faster checkout',
                          subtitle:
                              'Your name, phone, and address can be reused when placing orders.',
                        ),
                        const SizedBox(height: 10),
                        _profileBenefit(
                          icon: Icons.support_agent_outlined,
                          title: 'Better order help',
                          subtitle:
                              'The farm can contact the right person if pickup or delivery details need confirming.',
                        ),
                        const SizedBox(height: 10),
                        _profileBenefit(
                          icon: Icons.privacy_tip_outlined,
                          title: 'Private to your account',
                          subtitle:
                              'Only signed-in account tools and protected checkout flows use these details.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  PrimaryFarmButton(
                    label: saving ? 'Saving...' : 'Save Profile',
                    busyLabel: 'Saving profile...',
                    icon: Icons.save_outlined,
                    onPressed: saving ? null : saveProfile,
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.copy_outlined),
                    label: const Text('Copy profile summary'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 15, horizontal: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: copyProfileSummary,
                  ),
                ],
              ),
            ),
    );
  }
}

class SecurityAuditItem {
  final String title;
  final String status;
  final String detail;
  final IconData icon;

  const SecurityAuditItem({
    required this.title,
    required this.status,
    required this.detail,
    required this.icon,
  });
}

class SecurityAuditTile extends StatelessWidget {
  final SecurityAuditItem item;

  const SecurityAuditTile({super.key, required this.item});

  Color get statusColor {
    switch (item.status.toLowerCase()) {
      case 'active':
        return FarmColors.green;
      case 'review':
        return FarmColors.warning;
      default:
        return FarmColors.gold;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FarmCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: FarmColors.lightGreen,
            foregroundColor: FarmColors.primary,
            child: Icon(item.icon),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        item.status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item.detail,
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

class TrustHeroPill extends StatelessWidget {
  final String label;

  const TrustHeroPill({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
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

class PrimaryFarmButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final String? busyLabel;

  const PrimaryFarmButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.busyLabel,
  });

  @override
  State<PrimaryFarmButton> createState() => _PrimaryFarmButtonState();
}

class _PrimaryFarmButtonState extends State<PrimaryFarmButton> {
  bool _tapLocked = false;

  void _handlePressed() {
    final action = widget.onPressed;
    if (action == null || _tapLocked) return;

    setState(() => _tapLocked = true);

    try {
      action();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyAppError(error))),
        );
      }
    } finally {
      Future.delayed(const Duration(milliseconds: 650), () {
        if (mounted) setState(() => _tapLocked = false);
      });
    }
  }

  String get _busyText {
    if (widget.busyLabel != null && widget.busyLabel!.trim().isNotEmpty) {
      return widget.busyLabel!.trim();
    }

    final lowerLabel = widget.label.trim().toLowerCase();
    if (lowerLabel.contains('bundle')) return 'Adding bundle...';
    if (lowerLabel.contains('add')) return 'Adding...';
    if (lowerLabel.contains('save')) return 'Saving...';
    return 'Working...';
  }

  Widget _buttonContent({required bool isBusy}) {
    final label = isBusy ? _busyText : widget.label;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: Row(
        key: ValueKey<String>(isBusy ? 'busy-$label' : 'ready-$label'),
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isBusy) ...[
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
          ] else if (widget.icon != null) ...[
            Icon(widget.icon, size: 18),
            const SizedBox(width: 7),
          ],
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasAction = widget.onPressed != null;
    final isBusy = hasAction && _tapLocked;
    final isEnabled = hasAction && !isBusy;

    return AnimatedScale(
      duration: const Duration(milliseconds: 110),
      scale: isBusy ? 0.98 : 1,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: isEnabled || isBusy
              ? [
                  BoxShadow(
                    color: FarmColors.green.withOpacity(isBusy ? 0.14 : 0.24),
                    blurRadius: isBusy ? 12 : 22,
                    offset: Offset(0, isBusy ? 5 : 10),
                  ),
                ]
              : const [],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: hasAction ? FarmColors.green : FarmColors.line,
            foregroundColor: hasAction ? Colors.white : FarmColors.muted,
            disabledBackgroundColor:
                isBusy ? FarmColors.green.withOpacity(0.82) : FarmColors.line,
            disabledForegroundColor: isBusy ? Colors.white : FarmColors.muted,
            elevation: 0,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 17, horizontal: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          onPressed: isEnabled ? _handlePressed : null,
          child: _buttonContent(isBusy: isBusy),
        ),
      ),
    );
  }
}

class FarmEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;
  final bool compact;

  const FarmEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return FarmCard(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: compact ? 10 : 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: compact ? 52 : 64,
              width: compact ? 52 : 64,
              decoration: BoxDecoration(
                color: FarmColors.primarySoft,
                shape: BoxShape.circle,
                border: Border.all(color: FarmColors.green.withOpacity(0.12)),
              ),
              child: Icon(
                icon,
                size: compact ? 26 : 32,
                color: FarmColors.green,
              ),
            ),
            SizedBox(height: compact ? 10 : 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: FarmColors.ink,
                fontSize: compact ? 16 : 19,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: FarmColors.mutedText,
                height: 1.35,
                fontSize: compact ? 13 : 14.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: compact ? 12 : 16),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: Icon(actionIcon ?? Icons.arrow_forward_rounded, size: 18),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// =====================================================
// HPJ AGRICULTURE INTELLIGENCE FEED UI
// =====================================================
typedef HpjAgricultureFeedAction = Future<void> Function(
  AgricultureFeedUpdate update,
);

class HpjAgricultureUpdatesSection extends StatefulWidget {
  final String audience;
  final String workspace;
  final int limit;
  final int refreshKey;
  final HpjAgricultureFeedAction? onAction;
  final String title;
  final String subtitle;
  final bool socialStyle;
  final bool showImages;
  final bool showEducation;
  final bool onlyEducation;

  const HpjAgricultureUpdatesSection({
    super.key,
    required this.audience,
    required this.workspace,
    this.limit = 3,
    this.refreshKey = 0,
    this.onAction,
    this.title = 'Agriculture intelligence',
    this.subtitle = 'Useful market, industry and HPJ updates selected for you.',
    this.socialStyle = false,
    this.showImages = true,
    this.showEducation = true,
    this.onlyEducation = false,
  });

  @override
  State<HpjAgricultureUpdatesSection> createState() =>
      _HpjAgricultureUpdatesSectionState();
}

class _HpjAgricultureUpdatesSectionState
    extends State<HpjAgricultureUpdatesSection> {
  late Future<List<AgricultureFeedUpdate>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant HpjAgricultureUpdatesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshKey != widget.refreshKey ||
        oldWidget.audience != widget.audience ||
        oldWidget.limit != widget.limit ||
        oldWidget.showEducation != widget.showEducation ||
        oldWidget.onlyEducation != widget.onlyEducation) {
      _future = _load();
    }
  }

  Future<List<AgricultureFeedUpdate>> _load() async {
    final updates = await fetchAgricultureFeedUpdates(
      audience: widget.audience,
      limit: widget.limit + 8,
    );

    final filtered = updates.where((update) {
      final isEducation = update.category == 'education';
      if (widget.onlyEducation) return isEducation;
      if (!widget.showEducation && isEducation) return false;
      return true;
    }).take(widget.limit).toList();

    return filtered;
  }

  Future<void> _refresh() async {
    final next = _load();
    if (mounted) setState(() => _future = next);
    await next;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AgricultureFeedUpdate>>(
      future: _future,
      builder: (context, snapshot) {
        final updates = snapshot.data ?? const <AgricultureFeedUpdate>[];
        if (snapshot.connectionState == ConnectionState.waiting &&
            updates.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(minHeight: 2),
          );
        }
        if (updates.isEmpty) return const SizedBox.shrink();

        if (widget.socialStyle) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...updates.map(
                (update) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: HpjAgricultureUpdateCard(
                    update: update,
                    workspace: widget.workspace,
                    onAction: widget.onAction,
                    socialStyle: true,
                    showImages: widget.showImages,
                  ),
                ),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: FarmColors.primarySoft,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.public_rounded,
                    color: FarmColors.primary,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          color: FarmColors.ink,
                          fontSize: 16.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.subtitle,
                        style: const TextStyle(
                          color: FarmColors.mutedText,
                          fontSize: 10.5,
                          height: 1.3,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh updates',
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh_rounded, size: 19),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...updates.map(
              (update) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: HpjAgricultureUpdateCard(
                  update: update,
                  workspace: widget.workspace,
                  onAction: widget.onAction,
                  socialStyle: false,
                  showImages: widget.showImages,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class HpjAgricultureUpdateCard extends StatefulWidget {
  final AgricultureFeedUpdate update;
  final String workspace;
  final HpjAgricultureFeedAction? onAction;
  final bool socialStyle;
  final bool showImages;

  const HpjAgricultureUpdateCard({
    super.key,
    required this.update,
    required this.workspace,
    this.onAction,
    this.socialStyle = false,
    this.showImages = true,
  });

  @override
  State<HpjAgricultureUpdateCard> createState() =>
      _HpjAgricultureUpdateCardState();
}

class _HpjAgricultureUpdateCardState extends State<HpjAgricultureUpdateCard> {
  bool _seen = true;

  String get _seenKey {
    final revision = widget.update.updatedAt ?? widget.update.publishAt;
    return 'agri:${widget.update.id}:${revision.millisecondsSinceEpoch}';
  }

  @override
  void initState() {
    super.initState();
    unawaited(_loadSeen());
  }

  @override
  void didUpdateWidget(covariant HpjAgricultureUpdateCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.update.id != widget.update.id ||
        oldWidget.update.updatedAt != widget.update.updatedAt) {
      unawaited(_loadSeen());
    }
  }

  Future<void> _loadSeen() async {
    if (!isLoggedIn) {
      if (mounted) setState(() => _seen = true);
      return;
    }
    final value = await isHpjFeedItemSeen(
      workspace: widget.workspace,
      itemKey: _seenKey,
    );
    if (mounted) setState(() => _seen = value);
  }

  Future<void> _markSeen() async {
    if (!_seen && mounted) setState(() => _seen = true);
    if (!isLoggedIn) return;
    await markHpjFeedItemSeen(
      workspace: widget.workspace,
      itemKey: _seenKey,
    );
  }

  Future<void> _openSource() async {
    await _markSeen();
    final url = widget.update.sourceUrl?.trim() ?? '';
    if (url.isEmpty) return;
    final opened = await openExternalShareUrl(url);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the source link.')),
      );
    }
  }

  Future<void> _runAction() async {
    await _markSeen();
    final callback = widget.onAction;
    if (callback != null) {
      await callback(widget.update);
      return;
    }
    if (widget.update.actionType == 'external') {
      await _openSource();
    }
  }

  IconData get _categoryIcon {
    switch (widget.update.category) {
      case 'official_notice':
        return Icons.account_balance_outlined;
      case 'market_intelligence':
        return Icons.query_stats_rounded;
      case 'hpj_update':
        return Icons.campaign_outlined;
      case 'opportunity':
        return Icons.lightbulb_outline_rounded;
      case 'education':
        return Icons.school_outlined;
      case 'weather_alert':
        return Icons.cloud_outlined;
      default:
        return Icons.newspaper_rounded;
    }
  }

  Color get _priorityColor {
    if (widget.update.priority == 'urgent') return FarmColors.danger;
    if (widget.update.priority == 'important') return FarmColors.warning;
    return FarmColors.primary;
  }

  String _dateLabel(DateTime value) {
    final local = value.toLocal();
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
    return '${local.day} ${months[local.month - 1]}';
  }

  String _socialTimeLabel(DateTime value) {
    final now = DateTime.now();
    final diff = now.difference(value.toLocal());
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return _dateLabel(value);
  }

  Widget _buildSocialCard(
    AgricultureFeedUpdate update,
    String? imageUrl,
    Color priorityColor,
    String actionLabel,
    bool showActionButton,
    String sourceButtonLabel,
  ) {
    final source = (update.sourceName ?? '').trim();
    final meta = <String>[
      _socialTimeLabel(update.publishAt),
      if (source.isNotEmpty) source,
    ].join(' • ');

    return Material(
      color: FarmColors.card,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: _markSeen,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 13, 14, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: !_seen
                  ? FarmColors.primary.withOpacity(0.34)
                  : FarmColors.line.withOpacity(0.78),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.025),
                blurRadius: 14,
                offset: const Offset(0, 5),
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
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: priorityColor.withOpacity(0.10),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_categoryIcon, color: priorityColor, size: 20),
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
                                update.categoryLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: FarmColors.ink,
                                  fontSize: 13.3,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            if (!_seen)
                              Container(
                                margin: const EdgeInsets.only(left: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: FarmColors.primary,
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: const Text(
                                  'NEW',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 7.5,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          meta,
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
                  const SizedBox(width: 4),
                  Icon(
                    Icons.more_horiz_rounded,
                    size: 20,
                    color: FarmColors.mutedText.withOpacity(0.75),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          update.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: FarmColors.ink,
                            fontSize: 15.5,
                            height: 1.16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          update.summary,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: FarmColors.mutedText,
                            fontSize: 11,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (imageUrl != null) ...[
                    const SizedBox(width: 11),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        imageUrl,
                        width: 86,
                        height: 78,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 86,
                          height: 78,
                          color: FarmColors.primarySoft,
                          alignment: Alignment.center,
                          child: Icon(
                            _categoryIcon,
                            color: FarmColors.primary,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (update.isImportant) ...[
                const SizedBox(height: 9),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    update.priorityLabel.toUpperCase(),
                    style: TextStyle(
                      color: priorityColor,
                      fontSize: 8.2,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
              if (update.hasSource || showActionButton) ...[
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (update.hasSource)
                      TextButton.icon(
                        onPressed: _openSource,
                        icon: const Icon(Icons.open_in_new_rounded, size: 15),
                        label: Text(sourceButtonLabel),
                      ),
                    const Spacer(),
                    if (showActionButton)
                      FilledButton.tonalIcon(
                        onPressed: _runAction,
                        icon: const Icon(Icons.arrow_forward_rounded, size: 15),
                        label: Text(actionLabel),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final update = widget.update;
    final imageUrl = widget.showImages
        ? cleanHostedImageUrl(update.imageUrl)
        : null;
    final priorityColor = _priorityColor;
    final actionLabel = (update.actionLabel ?? '').trim().isEmpty
        ? 'Open'
        : update.actionLabel!.trim();
    final showActionButton =
        update.hasAction && update.actionType != 'external';
    final sourceButtonLabel = update.actionType == 'external' &&
            (update.actionLabel ?? '').trim().isNotEmpty
        ? update.actionLabel!.trim()
        : 'Read source';

    if (widget.socialStyle) {
      return _buildSocialCard(
        update,
        imageUrl,
        priorityColor,
        actionLabel,
        showActionButton,
        sourceButtonLabel,
      );
    }

    return Material(
      color: FarmColors.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: _markSeen,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: !_seen
                  ? FarmColors.primary.withOpacity(0.45)
                  : FarmColors.line,
              width: !_seen ? 1.4 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (imageUrl != null)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(17),
                  ),
                  child: AspectRatio(
                    aspectRatio: 16 / 8.2,
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: FarmColors.primarySoft,
                        child: Icon(
                          _categoryIcon,
                          size: 36,
                          color: FarmColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: priorityColor.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _categoryIcon,
                            color: priorityColor,
                            size: 17,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            update.categoryLabel.toUpperCase(),
                            style: TextStyle(
                              color: priorityColor,
                              fontSize: 8.8,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.55,
                            ),
                          ),
                        ),
                        if (!_seen)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: FarmColors.primary,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'NEW',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 7.8,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        if (update.isImportant) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: priorityColor.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              update.priorityLabel.toUpperCase(),
                              style: TextStyle(
                                color: priorityColor,
                                fontSize: 7.8,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      update.title,
                      style: const TextStyle(
                        color: FarmColors.ink,
                        fontSize: 16.5,
                        height: 1.12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      update.summary,
                      style: const TextStyle(
                        color: FarmColors.mutedText,
                        fontSize: 11.2,
                        height: 1.42,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            [
                              if ((update.sourceName ?? '').trim().isNotEmpty)
                                update.sourceName!.trim(),
                              _dateLabel(update.publishAt),
                            ].join(' • '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: FarmColors.mutedText,
                              fontSize: 9.4,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (update.hasSource || showActionButton) ...[
                      const SizedBox(height: 11),
                      Row(
                        children: [
                          if (update.hasSource)
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _openSource,
                                icon: const Icon(
                                  Icons.open_in_new_rounded,
                                  size: 15,
                                ),
                                label: Text(sourceButtonLabel),
                              ),
                            ),
                          if (update.hasSource && showActionButton)
                            const SizedBox(width: 8),
                          if (showActionButton)
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _runAction,
                                icon: const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 16,
                                ),
                                label: Text(actionLabel),
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
        ),
      ),
    );
  }
}

// =====================================================
// HPJ JAMAICA MARKET PULSE
// National, anonymized supply-demand intelligence.
// This is intentionally compact: it recommends what to do,
// rather than creating another dashboard for users to learn.
// =====================================================
typedef HpjJamaicaInsightAction = Future<void> Function(
  JamaicaSupplyDemandInsight insight,
);

class HpjJamaicaMarketPulseSection extends StatefulWidget {
  final String audience;
  final int refreshKey;
  final int limit;
  final bool adminMode;
  final bool socialStyle;
  final List<String> preferredCropNames;
  final HpjJamaicaInsightAction? onPrimaryAction;

  const HpjJamaicaMarketPulseSection({
    super.key,
    required this.audience,
    this.refreshKey = 0,
    this.limit = 8,
    this.adminMode = false,
    this.socialStyle = false,
    this.preferredCropNames = const <String>[],
    this.onPrimaryAction,
  });

  @override
  State<HpjJamaicaMarketPulseSection> createState() =>
      _HpjJamaicaMarketPulseSectionState();
}

class _HpjJamaicaMarketPulseSectionState
    extends State<HpjJamaicaMarketPulseSection> {
  late Future<List<JamaicaSupplyDemandInsight>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant HpjJamaicaMarketPulseSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshKey != widget.refreshKey ||
        oldWidget.audience != widget.audience ||
        oldWidget.limit != widget.limit) {
      _future = _load();
    }
  }

  Future<List<JamaicaSupplyDemandInsight>> _load() {
    return fetchJamaicaSupplyDemandIntelligence(limit: widget.limit);
  }

  Future<void> _refresh() async {
    final next = _load();
    if (mounted) setState(() => _future = next);
    await next;
  }

  String _date(DateTime? value) {
    if (value == null) return 'date to be confirmed';
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
    final local = value.toLocal();
    return '${local.day} ${months[local.month - 1]}';
  }

  Color _signalColor(JamaicaSupplyDemandInsight item) {
    if (item.isCriticalShortage) return FarmColors.danger;
    if (item.isTight || item.hasShortage) return FarmColors.warning;
    if (item.hasSurplus) return FarmColors.success;
    return FarmColors.primary;
  }

  JamaicaSupplyDemandInsight? _focus(
    List<JamaicaSupplyDemandInsight> items,
  ) {
    if (items.isEmpty) return null;

    final preferred = widget.preferredCropNames
        .map(hpjSmartNormalizeSearch)
        .where((name) => name.isNotEmpty)
        .toSet();

    bool isPreferred(JamaicaSupplyDemandInsight item) {
      if (preferred.isEmpty) return false;
      final name = hpjSmartNormalizeSearch(item.cropName);
      return preferred.any(
        (crop) => crop == name || crop.contains(name) || name.contains(crop),
      );
    }

    final ranked = List<JamaicaSupplyDemandInsight>.of(items)
      ..sort((a, b) {
        final aPreferred = isPreferred(a) ? 1 : 0;
        final bPreferred = isPreferred(b) ? 1 : 0;
        if (aPreferred != bPreferred) {
          return bPreferred.compareTo(aPreferred);
        }
        if (a.isCriticalShortage != b.isCriticalShortage) {
          return b.isCriticalShortage ? 1 : -1;
        }
        if (a.hasShortage != b.hasShortage) {
          return b.hasShortage ? 1 : -1;
        }
        return b.priorityScore.compareTo(a.priorityScore);
      });

    return ranked.first;
  }

  String _nextBestTitle(JamaicaSupplyDemandInsight item) {
    switch (widget.audience.trim().toLowerCase()) {
      case 'farmer':
        if (item.hasShortage) return 'Jamaica needs more ${item.cropName}';
        if (item.hasSurplus) return '${item.cropName} supply is strong';
        return 'Keep ${item.cropName} supply current';
      case 'wholesale':
        if (item.hasShortage) return '${item.cropName} may tighten';
        if (item.hasSurplus) return '${item.cropName} supply is available';
        return 'Plan ${item.cropName} with confidence';
      default:
        if (item.hasShortage) return 'Close the ${item.cropName} supply gap';
        if (item.hasSurplus) return 'Move ${item.cropName} surplus';
        return 'Watch ${item.cropName} closely';
    }
  }

  String _nextBestMessage(JamaicaSupplyDemandInsight item) {
    final parishText = item.supplyParishes.isEmpty
        ? 'No parish supply is confirmed yet.'
        : 'Supply reported from ${item.supplyParishes.take(3).join(', ')}'
            '${item.supplyParishes.length > 3 ? ' +${item.supplyParishes.length - 3} more' : ''}.';

    if (item.hasDemand) {
      return 'Planned business demand is ${item.formattedDemand}; reported '
          'supply is ${item.formattedSupply}. '
          '${item.hasShortage ? '${item.formattedGap} is still uncovered. ' : ''}'
          'Earliest need: ${_date(item.earliestNeedBy)}. $parishText';
    }

    return '${item.formattedSupply} is currently reported across Jamaica. '
        '$parishText';
  }

  String _actionLabel(JamaicaSupplyDemandInsight item) {
    switch (widget.audience.trim().toLowerCase()) {
      case 'farmer':
        return item.hasShortage ? 'View buyer demand' : 'Update supply';
      case 'wholesale':
        return item.hasShortage ? 'Plan ahead' : 'Shop wholesale';
      default:
        return 'Review signal';
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<JamaicaSupplyDemandInsight>>(
      future: _future,
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <JamaicaSupplyDemandInsight>[];

        if (snapshot.connectionState == ConnectionState.waiting &&
            items.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(minHeight: 2),
          );
        }

        if (items.isEmpty) return const SizedBox.shrink();

        final focus = _focus(items);
        final totalDemand = items.fold<double>(
          0,
          (sum, item) => sum + item.demandQuantity,
        );
        final totalSupply = items.fold<double>(
          0,
          (sum, item) => sum + item.supplyQuantity,
        );
        final overallCoverage = totalDemand <= 0
            ? 100
            : ((totalSupply / totalDemand) * 100).clamp(0, 999).round();

        final parishes = <String>{};
        for (final item in items) {
          parishes.addAll(item.supplyParishes);
        }

        final criticalCount =
            items.where((item) => item.isCriticalShortage).length;
        final gapCount = items.where((item) => item.hasShortage).length;

        if (widget.socialStyle && focus != null && !widget.adminMode) {
          return _HpjJamaicaSocialPulseCard(
            insight: focus,
            title: _nextBestTitle(focus),
            message: _nextBestMessage(focus),
            actionLabel: _actionLabel(focus),
            color: _signalColor(focus),
            earliestNeedLabel: _date(focus.earliestNeedBy),
            onTap: widget.onPrimaryAction == null
                ? null
                : () async {
                    await widget.onPrimaryAction!(focus);
                  },
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: FarmColors.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.map_outlined,
                    color: FarmColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 9),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Jamaica Market Pulse',
                        style: TextStyle(
                          color: FarmColors.ink,
                          fontSize: 16.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Reported farmer supply compared with planned Jamaican business demand.',
                        style: TextStyle(
                          color: FarmColors.mutedText,
                          fontSize: 10.4,
                          height: 1.3,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh Jamaica market pulse',
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh_rounded, size: 19),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                _HpjJamaicaPulseMetric(
                  label: 'Supply coverage',
                  value: '$overallCoverage%',
                ),
                _HpjJamaicaPulseMetric(
                  label: 'Open crop gaps',
                  value: '$gapCount',
                  warning: gapCount > 0,
                ),
                _HpjJamaicaPulseMetric(
                  label: 'Parishes reporting',
                  value: '${parishes.length}',
                ),
              ],
            ),
            if (widget.adminMode && criticalCount > 0) ...[
              const SizedBox(height: 9),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: FarmColors.danger.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: FarmColors.danger.withOpacity(0.20),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: FarmColors.danger,
                      size: 19,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$criticalCount smart exception${criticalCount == 1 ? '' : 's'}: '
                        'planned demand has less than 50% reported supply coverage.',
                        style: const TextStyle(
                          color: FarmColors.ink,
                          fontSize: 10.4,
                          height: 1.35,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (focus != null) ...[
              const SizedBox(height: 10),
              _HpjJamaicaNextBestActionCard(
                insight: focus,
                title: _nextBestTitle(focus),
                message: _nextBestMessage(focus),
                actionLabel: _actionLabel(focus),
                color: _signalColor(focus),
                showAction: widget.onPrimaryAction != null,
                onTap: widget.onPrimaryAction == null
                    ? null
                    : () async {
                        await widget.onPrimaryAction!(focus);
                      },
              ),
            ],
            if (widget.adminMode) ...[
              const SizedBox(height: 10),
              ...items.take(5).map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: _HpjJamaicaInsightRow(
                        item: item,
                        color: _signalColor(item),
                      ),
                    ),
                  ),
            ],
          ],
        );
      },
    );
  }
}

class _HpjJamaicaSocialPulseCard extends StatelessWidget {
  final JamaicaSupplyDemandInsight insight;
  final String title;
  final String message;
  final String actionLabel;
  final String earliestNeedLabel;
  final Color color;
  final Future<void> Function()? onTap;

  const _HpjJamaicaSocialPulseCard({
    required this.insight,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.earliestNeedLabel,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final shortMessage = insight.hasDemand
        ? 'Planned demand is ${insight.formattedDemand}; reported supply is '
            '${insight.formattedSupply}. '
            '${insight.hasShortage ? '${insight.formattedGap} is still needed.' : 'Supply is currently covering demand.'}'
        : message;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 10),
      decoration: BoxDecoration(
        color: FarmColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: FarmColors.line.withOpacity(0.78)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
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
                width: 46,
                height: 46,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: FarmColors.primary.withOpacity(0.12),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'lib/assets/images/logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.eco_rounded,
                        color: FarmColors.primary,
                        size: 27,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Jamaica Market Pulse',
                      style: TextStyle(
                        color: FarmColors.ink,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'HPJ market intelligence • Jamaica',
                      style: TextStyle(
                        color: FarmColors.mutedText,
                        fontSize: 9.8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.more_horiz_rounded,
                size: 20,
                color: FarmColors.mutedText,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: FarmColors.ink,
                        fontSize: 16,
                        height: 1.15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      shortMessage,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: FarmColors.mutedText,
                        fontSize: 11,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              HpjProductThumb(
                productName: insight.cropName,
                size: 82,
                radius: 15,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  insight.coverageLabel.toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontSize: 8.3,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (insight.earliestNeedBy != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F4F1),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    'NEED BY ${earliestNeedLabel.toUpperCase()}',
                    style: const TextStyle(
                      color: FarmColors.mutedText,
                      fontSize: 8.3,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
          if (onTap != null) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 5),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () => unawaited(onTap!()),
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: Text(actionLabel),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HpjJamaicaPulseMetric extends StatelessWidget {
  final String label;
  final String value;
  final bool warning;

  const _HpjJamaicaPulseMetric({
    required this.label,
    required this.value,
    this.warning = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: warning ? FarmColors.warning.withOpacity(0.08) : FarmColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              warning ? FarmColors.warning.withOpacity(0.25) : FarmColors.line,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              color: warning ? FarmColors.warning : FarmColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: FarmColors.mutedText,
              fontSize: 9.2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HpjJamaicaNextBestActionCard extends StatelessWidget {
  final JamaicaSupplyDemandInsight insight;
  final String title;
  final String message;
  final String actionLabel;
  final Color color;
  final bool showAction;
  final Future<void> Function()? onTap;

  const _HpjJamaicaNextBestActionCard({
    required this.insight,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.color,
    required this.showAction,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FarmCard(
      padding: const EdgeInsets.all(13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HpjProductThumb(
                productName: insight.cropName,
                size: 62,
                radius: 13,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      insight.isCriticalShortage
                          ? 'SMART EXCEPTION • NEXT BEST ACTION'
                          : 'NEXT BEST ACTION',
                      style: TextStyle(
                        color: color,
                        fontSize: 8.3,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.45,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: const TextStyle(
                        color: FarmColors.ink,
                        fontSize: 15,
                        height: 1.15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      insight.coverageLabel,
                      style: TextStyle(
                        color: color,
                        fontSize: 9.4,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            message,
            style: const TextStyle(
              color: FarmColors.mutedText,
              fontSize: 10.5,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (showAction) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onTap == null
                    ? null
                    : () {
                        unawaited(onTap!());
                      },
                icon: const Icon(Icons.arrow_forward_rounded, size: 17),
                label: Text(actionLabel),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HpjJamaicaInsightRow extends StatelessWidget {
  final JamaicaSupplyDemandInsight item;
  final Color color;

  const _HpjJamaicaInsightRow({
    required this.item,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final coverage = item.hasDemand
        ? (item.coveragePercent / 100).clamp(0.0, 1.0).toDouble()
        : 1.0;

    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: FarmColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: FarmColors.line),
      ),
      child: Row(
        children: [
          HpjProductThumb(
            productName: item.cropName,
            size: 48,
            radius: 11,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.cropName,
                        style: const TextStyle(
                          color: FarmColors.ink,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Text(
                      item.statusLabel,
                      style: TextStyle(
                        color: color,
                        fontSize: 8.8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: coverage,
                    minHeight: 5,
                    backgroundColor: FarmColors.line,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Demand ${item.formattedDemand} • Supply ${item.formattedSupply}'
                  '${item.hasShortage ? ' • Gap ${item.formattedGap}' : ''}',
                  style: const TextStyle(
                    color: FarmColors.mutedText,
                    fontSize: 9.2,
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
}

class HpjCompactAccountHero extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String badge;
  final Color? badgeColor;

  const HpjCompactAccountHero({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBadgeColor = badgeColor ?? FarmColors.primary;

    return FarmCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: FarmColors.primarySoft,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              icon,
              color: FarmColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.trim().isEmpty ? 'HPJ Account' : title.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: FarmColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (subtitle.trim().isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: FarmColors.mutedText,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: effectiveBadgeColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: effectiveBadgeColor.withOpacity(0.18),
              ),
            ),
            child: Text(
              badge,
              style: TextStyle(
                color: effectiveBadgeColor,
                fontSize: 8.8,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HpjAccountHelpInfoScreen extends StatelessWidget {
  final String supportSubject;
  final bool showTrustCenter;

  const HpjAccountHelpInfoScreen({
    super.key,
    required this.supportSubject,
    this.showTrustCenter = false,
  });

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
        title: const Text('Help & information'),
        backgroundColor: FarmColors.background,
      ),
      body: FarmPage(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 100),
          children: [
            const Header(
              title: 'Help & information',
              subtitle: 'Support and important HPJ information in one place.',
            ),
            const SizedBox(height: 14),
            FarmCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  AccountListTile(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'Inbox & support',
                    subtitle: 'Private messages with the HPJ team.',
                    onTap: () => _open(
                      context,
                      SupportScreen(initialSubject: supportSubject),
                    ),
                  ),
                  AccountListTile(
                    icon: Icons.contact_support_outlined,
                    title: 'Contact HPJ',
                    subtitle: 'Chat, WhatsApp or call us.',
                    isLast: !showTrustCenter,
                    onTap: () => _open(
                      context,
                      const ContactHpjScreen(),
                    ),
                  ),
                  if (showTrustCenter)
                    AccountListTile(
                      icon: Icons.verified_user_outlined,
                      title: 'Trust Center',
                      subtitle: 'Freshness, privacy and customer support.',
                      isLast: true,
                      onTap: () => _open(
                        context,
                        const TrustCenterScreen(),
                      ),
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
                      title: 'About & policies',
                      subtitle: 'HPJ information and account policies.',
                    ),
                  ),
                  AccountListTile(
                    icon: Icons.eco_outlined,
                    title: 'About The Harvest Place Ja',
                    subtitle: 'Our mission and how HPJ works.',
                    onTap: () => _open(
                      context,
                      const AboutHpjScreen(),
                    ),
                  ),
                  AccountListTile(
                    icon: Icons.description_outlined,
                    title: 'Terms of Service',
                    subtitle: 'Rules for using HPJ.',
                    onTap: () => _open(
                      context,
                      const TermsOfServiceScreen(),
                    ),
                  ),
                  AccountListTile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    subtitle: 'How your information is handled.',
                    onTap: () => _open(
                      context,
                      const PrivacyPolicyScreen(),
                    ),
                  ),
                  AccountListTile(
                    icon: Icons.replay_circle_filled_outlined,
                    title: 'Refund Policy',
                    subtitle: 'Order and freshness support.',
                    isLast: true,
                    onTap: () => _open(
                      context,
                      const RefundPolicyScreen(),
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


// =====================================================
// SHARED PARTNER INBOX ACTION
// =====================================================
// Farmer and wholesale workspaces use the same private HPJ conversation
// system.  The backend remains the existing secured support conversation
// service; only the presentation is elevated to a first-class Inbox.
class HpjInboxActionButton extends StatefulWidget {
  final String tooltip;
  final String initialSubject;

  const HpjInboxActionButton({
    super.key,
    this.tooltip = 'Inbox',
    this.initialSubject = '',
  });

  @override
  State<HpjInboxActionButton> createState() => _HpjInboxActionButtonState();
}

class _HpjInboxActionButtonState extends State<HpjInboxActionButton> {
  late Future<int> _future;

  @override
  void initState() {
    super.initState();
    _future = _unreadCount();
  }

  Future<int> _unreadCount() async {
    final tickets = await fetchMySupportTickets();
    return tickets.where((ticket) => ticket.hasUnreadForCustomer).length;
  }

  Future<void> _openInbox() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SupportScreen(
          initialSubject: widget.initialSubject,
        ),
      ),
    );

    if (!mounted) return;
    setState(() {
      _future = _unreadCount();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: _future,
      builder: (context, snapshot) {
        final unread = snapshot.data ?? 0;

        return IconButton(
          tooltip: widget.tooltip,
          onPressed: _openInbox,
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.mail_outline_rounded),
              if (unread > 0)
                Positioned(
                  right: -7,
                  top: -7,
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 17,
                      minHeight: 17,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: FarmColors.danger,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      unread > 9 ? '9+' : '$unread',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                        height: 1,
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
