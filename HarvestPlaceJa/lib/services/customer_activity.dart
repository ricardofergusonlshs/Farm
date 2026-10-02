part of harvest_place_app;

// ============================================================================
// HPJ CUSTOMER ACTIVITY + DEMAND INTELLIGENCE — MVP
// Privacy-aware, signed-in customer activity signals for personalization and
// aggregated Owner/Manager demand intelligence.
// ============================================================================

class HpjCustomerActivityType {
  static const String sessionStart = 'session_start';
  static const String search = 'search';
  static const String productView = 'product_view';
  static const String favoriteAdd = 'favorite_add';
  static const String favoriteRemove = 'favorite_remove';
  static const String cartAdd = 'cart_add';
  static const String cartRemove = 'cart_remove';
  static const String checkoutStart = 'checkout_start';
  static const String purchase = 'purchase';
  static const String farmFollow = 'farm_follow';
  static const String farmUnfollow = 'farm_unfollow';
  static const String mealView = 'meal_view';
  static const String mealPost = 'meal_post';
  static const String dealOpen = 'deal_open';

  static const Set<String> values = <String>{
    sessionStart,
    search,
    productView,
    favoriteAdd,
    favoriteRemove,
    cartAdd,
    cartRemove,
    checkoutStart,
    purchase,
    farmFollow,
    farmUnfollow,
    mealView,
    mealPost,
    dealOpen,
  };
}

final Map<String, DateTime> _hpjRecentActivityKeys = <String, DateTime>{};

String _hpjCleanActivityText(String? value, {int maxLength = 180}) {
  final cleaned = (value ?? '').trim().replaceAll(RegExp(r'\s+'), ' ');
  if (cleaned.length <= maxLength) return cleaned;
  return cleaned.substring(0, maxLength);
}

bool hpjCustomerActivityHistoryEnabled() {
  if (supabase.auth.currentUser == null) return false;
  return hpjCurrentUserExperiencePreferences.saveActivityHistory;
}

bool _hpjActivityAllowedNow(
  String key, {
  Duration window = const Duration(milliseconds: 900),
}) {
  final now = DateTime.now();
  final previous = _hpjRecentActivityKeys[key];
  if (previous != null && now.difference(previous) < window) return false;
  _hpjRecentActivityKeys[key] = now;

  // Keep this tiny in-memory throttle map bounded.
  if (_hpjRecentActivityKeys.length > 180) {
    final cutoff = now.subtract(const Duration(hours: 1));
    _hpjRecentActivityKeys.removeWhere((_, value) => value.isBefore(cutoff));
  }
  return true;
}

Future<void> hpjTrackCustomerActivity({
  required String eventType,
  Product? product,
  String query = '',
  int? quantity,
  String source = 'customer',
  Map<String, dynamic> metadata = const <String, dynamic>{},
  Duration dedupeWindow = const Duration(milliseconds: 900),
}) async {
  // Aggregate audience/conversion analytics are deliberately separate from
  // the customer's optional private activity history. This also allows HPJ to
  // count anonymous website/app visits without exposing identity in Admin.
  unawaited(
    HpjAudienceAnalytics.trackFromCustomerActivity(
      eventType: eventType,
      product: product,
      query: query,
      quantity: quantity,
      source: source,
      metadata: metadata,
    ),
  );

  final user = supabase.auth.currentUser;
  if (user == null || !HpjCustomerActivityType.values.contains(eventType)) {
    return;
  }
  if (!hpjCustomerActivityHistoryEnabled()) return;

  // Sample listings are presentation-only. They may still contribute to
  // aggregate visitor counts, but they must not inflate product procurement
  // interest or private customer product-history signals.
  if (product?.isSampleProduct == true) return;

  final productId = _hpjCleanActivityText(product?.id, maxLength: 120);
  final queryText = _hpjCleanActivityText(query, maxLength: 180);
  final cleanSource = _hpjCleanActivityText(source, maxLength: 80);
  final throttleKey = '$eventType|$productId|$queryText|$cleanSource|${quantity ?? ''}';

  if (!_hpjActivityAllowedNow(throttleKey, window: dedupeWindow)) return;

  try {
    await supabase.rpc(
      'hpj_track_customer_activity',
      params: <String, dynamic>{
        'p_event_type': eventType,
        'p_product_id': productId.isEmpty ? null : productId,
        'p_product_name': product == null
            ? null
            : _hpjCleanActivityText(product.name, maxLength: 180),
        'p_category': product == null
            ? null
            : _hpjCleanActivityText(product.category, maxLength: 120),
        'p_query_text': queryText.isEmpty ? null : queryText,
        'p_quantity': quantity,
        'p_source': cleanSource.isEmpty ? 'customer' : cleanSource,
        'p_metadata': metadata,
      },
    );
  } catch (error) {
    // Activity logging must never block shopping, checkout or navigation.
    farmDebugLog('Customer activity tracking skipped safely: $error');
  }
}

Future<void> hpjTrackCustomerSessionStart({
  String source = 'customer',
}) {
  return hpjTrackCustomerActivity(
    eventType: HpjCustomerActivityType.sessionStart,
    source: source,
    dedupeWindow: const Duration(minutes: 30),
  );
}

Future<void> hpjTrackCustomerSearch(
  String query, {
  int? resultCount,
  String source = 'shop',
}) {
  final cleaned = _hpjCleanActivityText(query, maxLength: 180);
  if (cleaned.length < 2) return Future<void>.value();

  return hpjTrackCustomerActivity(
    eventType: HpjCustomerActivityType.search,
    query: cleaned,
    source: source,
    metadata: <String, dynamic>{
      if (resultCount != null) 'result_count': resultCount,
    },
    dedupeWindow: const Duration(seconds: 3),
  );
}

Future<void> hpjTrackProductView(
  Product product, {
  String source = 'shop',
}) {
  return hpjTrackCustomerActivity(
    eventType: HpjCustomerActivityType.productView,
    product: product,
    source: source,
    dedupeWindow: const Duration(seconds: 4),
  );
}

Future<void> hpjTrackFavoriteChange(
  Product product, {
  required bool isFavorite,
  String source = 'shop',
}) {
  return hpjTrackCustomerActivity(
    eventType: isFavorite
        ? HpjCustomerActivityType.favoriteAdd
        : HpjCustomerActivityType.favoriteRemove,
    product: product,
    source: source,
  );
}

Future<void> hpjTrackCartChange(
  Product product, {
  required bool added,
  int? quantity,
  String source = 'shop',
}) {
  return hpjTrackCustomerActivity(
    eventType: added
        ? HpjCustomerActivityType.cartAdd
        : HpjCustomerActivityType.cartRemove,
    product: product,
    quantity: quantity,
    source: source,
  );
}

Future<void> hpjTrackCheckoutStart({
  required int itemCount,
  double? total,
  String source = 'my_box',
}) {
  return hpjTrackCustomerActivity(
    eventType: HpjCustomerActivityType.checkoutStart,
    quantity: itemCount,
    source: source,
    metadata: <String, dynamic>{
      'item_count': itemCount,
      if (total != null) 'total': total,
    },
    dedupeWindow: const Duration(seconds: 5),
  );
}

Future<void> hpjTrackPurchase({
  required String orderId,
  required int itemCount,
  double? total,
  String source = 'checkout',
}) {
  return hpjTrackCustomerActivity(
    eventType: HpjCustomerActivityType.purchase,
    quantity: itemCount,
    source: source,
    metadata: <String, dynamic>{
      'order_id': _hpjCleanActivityText(orderId, maxLength: 120),
      'item_count': itemCount,
      if (total != null) 'total': total,
    },
    dedupeWindow: const Duration(seconds: 15),
  );
}

Future<void> hpjClearMyCustomerActivityHistory() async {
  final user = supabase.auth.currentUser;
  if (user == null) return;

  try {
    await supabase.rpc('hpj_clear_my_customer_activity');
    _hpjRecentActivityKeys.clear();
  } catch (error) {
    farmDebugLog('Customer activity clear failed: $error');
    rethrow;
  }
}

class HpjDemandSignal {
  final String productId;
  final String productName;
  final String category;
  final int views;
  final int favorites;
  final int cartAdds;
  final int cartRemoves;
  final int purchases;
  final int uniqueUsers;
  final double demandScore;
  final DateTime? lastSignalAt;

  const HpjDemandSignal({
    required this.productId,
    required this.productName,
    required this.category,
    required this.views,
    required this.favorites,
    required this.cartAdds,
    required this.cartRemoves,
    required this.purchases,
    required this.uniqueUsers,
    required this.demandScore,
    required this.lastSignalAt,
  });

  factory HpjDemandSignal.fromMap(Map<String, dynamic> row) {
    int asInt(dynamic value) => value is num
        ? value.toInt()
        : int.tryParse((value ?? '0').toString()) ?? 0;
    double asDouble(dynamic value) => value is num
        ? value.toDouble()
        : double.tryParse((value ?? '0').toString()) ?? 0;

    return HpjDemandSignal(
      productId: (row['product_id'] ?? '').toString(),
      productName: (row['product_name'] ?? 'Unknown product').toString(),
      category: (row['category'] ?? '').toString(),
      views: asInt(row['views']),
      favorites: asInt(row['favorites']),
      cartAdds: asInt(row['cart_adds']),
      cartRemoves: asInt(row['cart_removes']),
      purchases: asInt(row['purchases']),
      uniqueUsers: asInt(row['unique_users']),
      demandScore: asDouble(row['demand_score']),
      lastSignalAt: DateTime.tryParse((row['last_signal_at'] ?? '').toString()),
    );
  }
}

class HpjSearchDemandSignal {
  final String query;
  final int searches;
  final int uniqueUsers;
  final int zeroResultSearches;
  final double averageResults;
  final DateTime? lastSearchedAt;

  const HpjSearchDemandSignal({
    required this.query,
    required this.searches,
    required this.uniqueUsers,
    required this.zeroResultSearches,
    required this.averageResults,
    required this.lastSearchedAt,
  });

  factory HpjSearchDemandSignal.fromMap(Map<String, dynamic> row) {
    int asInt(dynamic value) => value is num
        ? value.toInt()
        : int.tryParse((value ?? '0').toString()) ?? 0;
    double asDouble(dynamic value) => value is num
        ? value.toDouble()
        : double.tryParse((value ?? '0').toString()) ?? 0;

    return HpjSearchDemandSignal(
      query: (row['query_text'] ?? '').toString(),
      searches: asInt(row['searches']),
      uniqueUsers: asInt(row['unique_users']),
      zeroResultSearches: asInt(row['zero_result_searches']),
      averageResults: asDouble(row['average_results']),
      lastSearchedAt:
          DateTime.tryParse((row['last_searched_at'] ?? '').toString()),
    );
  }
}

Future<List<HpjDemandSignal>> fetchHpjDemandSignals({
  int days = 30,
  int limit = 50,
}) async {
  final response = await supabase.rpc(
    'hpj_customer_demand_summary',
    params: <String, dynamic>{
      'p_days': days.clamp(1, 365),
      'p_limit': limit.clamp(1, 200),
    },
  );

  return (response as List<dynamic>)
      .map((row) => HpjDemandSignal.fromMap(
            Map<String, dynamic>.from(row as Map),
          ))
      .toList(growable: false);
}

Future<List<HpjSearchDemandSignal>> fetchHpjSearchDemandSignals({
  int days = 30,
  int limit = 50,
}) async {
  final response = await supabase.rpc(
    'hpj_search_demand_summary',
    params: <String, dynamic>{
      'p_days': days.clamp(1, 365),
      'p_limit': limit.clamp(1, 200),
    },
  );

  return (response as List<dynamic>)
      .map((row) => HpjSearchDemandSignal.fromMap(
            Map<String, dynamic>.from(row as Map),
          ))
      .toList(growable: false);
}

class HpjProductInterestSignal {
  final String productId;
  final String productName;
  final String category;
  final String farmName;
  final String parish;
  final int searches;
  final int views;
  final int favoriteAdds;
  final int cartAdds;
  final int cartRemoves;
  final int interestedCustomers;
  final int orderCount;
  final int unitsSold;
  final int buyers;
  final int repeatBuyers;
  final double revenue;
  final double demandScore;
  final double conversionPct;
  final double trendPct;
  final int stockQuantity;
  final bool isAvailable;
  final String supplyStatus;
  final String decisionSignal;
  final DateTime? lastSignalAt;

  const HpjProductInterestSignal({
    required this.productId,
    required this.productName,
    required this.category,
    required this.farmName,
    required this.parish,
    required this.searches,
    required this.views,
    required this.favoriteAdds,
    required this.cartAdds,
    required this.cartRemoves,
    required this.interestedCustomers,
    required this.orderCount,
    required this.unitsSold,
    required this.buyers,
    required this.repeatBuyers,
    required this.revenue,
    required this.demandScore,
    required this.conversionPct,
    required this.trendPct,
    required this.stockQuantity,
    required this.isAvailable,
    required this.supplyStatus,
    required this.decisionSignal,
    required this.lastSignalAt,
  });

  factory HpjProductInterestSignal.fromMap(Map<String, dynamic> row) {
    int asInt(dynamic value) => value is num
        ? value.toInt()
        : int.tryParse((value ?? '0').toString()) ?? 0;
    double asDouble(dynamic value) => value is num
        ? value.toDouble()
        : double.tryParse((value ?? '0').toString()) ?? 0;
    bool asBool(dynamic value) {
      if (value is bool) return value;
      final text = (value ?? '').toString().toLowerCase();
      return text == 'true' || text == '1';
    }

    return HpjProductInterestSignal(
      productId: (row['product_id'] ?? '').toString(),
      productName: (row['product_name'] ?? 'Unknown product').toString(),
      category: (row['category'] ?? '').toString(),
      farmName: (row['farm_name'] ?? '').toString(),
      parish: (row['parish'] ?? '').toString(),
      searches: asInt(row['searches']),
      views: asInt(row['views']),
      favoriteAdds: asInt(row['favorite_adds']),
      cartAdds: asInt(row['cart_adds']),
      cartRemoves: asInt(row['cart_removes']),
      interestedCustomers: asInt(row['interested_customers']),
      orderCount: asInt(row['order_count']),
      unitsSold: asInt(row['units_sold']),
      buyers: asInt(row['buyers']),
      repeatBuyers: asInt(row['repeat_buyers']),
      revenue: asDouble(row['revenue']),
      demandScore: asDouble(row['demand_score']),
      conversionPct: asDouble(row['conversion_pct']),
      trendPct: asDouble(row['trend_pct']),
      stockQuantity: asInt(row['stock_quantity']),
      isAvailable: asBool(row['is_available']),
      supplyStatus: (row['supply_status'] ?? 'Unknown').toString(),
      decisionSignal: (row['decision_signal'] ?? 'Monitor').toString(),
      lastSignalAt: DateTime.tryParse((row['last_signal_at'] ?? '').toString()),
    );
  }
}

class HpjUnmetSearchSignal {
  final String query;
  final int searches;
  final int uniqueUsers;
  final int zeroResultSearches;
  final double zeroResultRate;
  final double opportunityScore;
  final DateTime? lastSearchedAt;
  final String decisionSignal;

  const HpjUnmetSearchSignal({
    required this.query,
    required this.searches,
    required this.uniqueUsers,
    required this.zeroResultSearches,
    required this.zeroResultRate,
    required this.opportunityScore,
    required this.lastSearchedAt,
    required this.decisionSignal,
  });

  factory HpjUnmetSearchSignal.fromMap(Map<String, dynamic> row) {
    int asInt(dynamic value) => value is num
        ? value.toInt()
        : int.tryParse((value ?? '0').toString()) ?? 0;
    double asDouble(dynamic value) => value is num
        ? value.toDouble()
        : double.tryParse((value ?? '0').toString()) ?? 0;

    return HpjUnmetSearchSignal(
      query: (row['query_text'] ?? '').toString(),
      searches: asInt(row['searches']),
      uniqueUsers: asInt(row['unique_users']),
      zeroResultSearches: asInt(row['zero_result_searches']),
      zeroResultRate: asDouble(row['zero_result_rate']),
      opportunityScore: asDouble(row['opportunity_score']),
      lastSearchedAt:
          DateTime.tryParse((row['last_searched_at'] ?? '').toString()),
      decisionSignal: (row['decision_signal'] ?? 'Search interest').toString(),
    );
  }
}

Future<List<HpjProductInterestSignal>> fetchHpjProductInterestDashboard({
  int days = 30,
  int limit = 200,
  String category = '',
  String parish = '',
}) async {
  final response = await supabase.rpc(
    'hpj_product_interest_dashboard',
    params: <String, dynamic>{
      'p_days': days.clamp(1, 365),
      'p_limit': limit.clamp(1, 300),
      'p_category': category.trim().isEmpty ? null : category.trim(),
      'p_parish': parish.trim().isEmpty ? null : parish.trim(),
    },
  );

  return (response as List<dynamic>)
      .map(
        (row) => HpjProductInterestSignal.fromMap(
          Map<String, dynamic>.from(row as Map),
        ),
      )
      .toList(growable: false);
}

Future<List<HpjUnmetSearchSignal>> fetchHpjUnmetSearchDemand({
  int days = 30,
  int limit = 100,
}) async {
  final response = await supabase.rpc(
    'hpj_unmet_search_demand',
    params: <String, dynamic>{
      'p_days': days.clamp(1, 365),
      'p_limit': limit.clamp(1, 200),
    },
  );

  return (response as List<dynamic>)
      .map(
        (row) => HpjUnmetSearchSignal.fromMap(
          Map<String, dynamic>.from(row as Map),
        ),
      )
      .toList(growable: false);
}

class AdminCustomerDemandIntelligenceScreen extends StatefulWidget {
  final bool embedded;

  const AdminCustomerDemandIntelligenceScreen({
    super.key,
    this.embedded = false,
  });

  @override
  State<AdminCustomerDemandIntelligenceScreen> createState() =>
      _AdminCustomerDemandIntelligenceScreenState();
}

class _AdminCustomerDemandIntelligenceScreenState
    extends State<AdminCustomerDemandIntelligenceScreen> {
  int days = 30;
  String categoryFilter = 'All categories';
  String parishFilter = 'All parishes';
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = Future.wait<dynamic>(<Future<dynamic>>[
      fetchHpjProductInterestDashboard(days: days, limit: 240),
      fetchHpjUnmetSearchDemand(days: days, limit: 120),
    ]);
  }

  void _setDays(int value) {
    if (days == value) return;
    setState(() {
      days = value;
      _reload();
    });
  }

  List<String> _categories(List<HpjProductInterestSignal> values) {
    final result = values
        .map((item) => item.category.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return <String>['All categories', ...result];
  }

  List<String> _parishes(List<HpjProductInterestSignal> values) {
    final result = values
        .map((item) => item.parish.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return <String>['All parishes', ...result];
  }

  int _decisionPriority(String signal) {
    switch (signal.trim().toLowerCase()) {
      case 'source more':
        return 0;
      case 'protect repeat supply':
        return 1;
      case 'review conversion':
        return 2;
      case 'rising demand':
        return 3;
      case 'maintain supply':
        return 4;
      case 'steady demand':
        return 5;
      default:
        return 6;
    }
  }

  Color _decisionColor(String signal) {
    switch (signal.trim().toLowerCase()) {
      case 'source more':
        return const Color(0xFFB55222);
      case 'protect repeat supply':
        return const Color(0xFF8A5B00);
      case 'review conversion':
        return const Color(0xFF8A6411);
      case 'rising demand':
        return const Color(0xFF2C6F42);
      case 'maintain supply':
        return FarmColors.green;
      case 'steady demand':
        return const Color(0xFF426C54);
      default:
        return FarmColors.mutedText;
    }
  }

  String _trendLabel(double value) {
    if (value >= 25) return 'Rising ${value.toStringAsFixed(0)}%';
    if (value <= -25) return 'Cooling ${value.abs().toStringAsFixed(0)}%';
    return 'Stable ${value >= 0 ? '+' : ''}${value.toStringAsFixed(0)}%';
  }

  Widget _buildBody() {
    return FutureBuilder<List<dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            snapshot.data == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.query_stats_outlined,
                    color: FarmColors.mutedText,
                    size: 44,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Product interest data is not ready yet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: FarmColors.deepGreen,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Run the Product Interest & Demand SQL upgrade in Supabase, then refresh.\n\n${friendlyAppError(snapshot.error!)}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: FarmColors.mutedText,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final allProducts = snapshot.data == null
            ? const <HpjProductInterestSignal>[]
            : List<HpjProductInterestSignal>.from(snapshot.data![0] as List);
        final searchGaps = snapshot.data == null
            ? const <HpjUnmetSearchSignal>[]
            : List<HpjUnmetSearchSignal>.from(snapshot.data![1] as List);

        final categories = _categories(allProducts);
        final parishes = _parishes(allProducts);
        final safeCategory = categories.contains(categoryFilter)
            ? categoryFilter
            : 'All categories';
        final safeParish = parishes.contains(parishFilter)
            ? parishFilter
            : 'All parishes';

        final products = allProducts.where((item) {
          final categoryOk = safeCategory == 'All categories' ||
              item.category.trim() == safeCategory;
          final parishOk = safeParish == 'All parishes' ||
              item.parish.trim() == safeParish;
          return categoryOk && parishOk;
        }).toList()
          ..sort((a, b) {
            final priority = _decisionPriority(a.decisionSignal)
                .compareTo(_decisionPriority(b.decisionSignal));
            if (priority != 0) return priority;
            return b.demandScore.compareTo(a.demandScore);
          });

        final sourceMore = products
            .where((item) => item.decisionSignal == 'Source more')
            .length;
        final conversionGaps = products
            .where((item) => item.decisionSignal == 'Review conversion')
            .length;
        final repeatWinners = products.where((item) => item.repeatBuyers > 0).length;
        final zeroResultSearches = searchGaps.fold<int>(
          0,
          (sum, item) => sum + item.zeroResultSearches,
        );
        final totalUnits = products.fold<int>(0, (sum, item) => sum + item.unitsSold);
        final totalRevenue = products.fold<double>(0, (sum, item) => sum + item.revenue);

        final decisionQueue = products
            .where((item) => _decisionPriority(item.decisionSignal) <= 3)
            .take(15)
            .toList();

        return RefreshIndicator(
          onRefresh: () async {
            setState(_reload);
            await _future;
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
            children: [
              _HpjProductDemandHero(
                days: days,
                productCount: products.length,
                sourceMoreCount: sourceMore,
                conversionGapCount: conversionGaps,
                repeatWinnerCount: repeatWinners,
                onRefresh: () => setState(_reload),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (final value in <int>[7, 30, 90])
                    ChoiceChip(
                      label: Text('$value days'),
                      selected: days == value,
                      onSelected: (_) => _setDays(value),
                    ),
                  SizedBox(
                    width: 190,
                    child: DropdownButtonFormField<String>(
                      value: safeCategory,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      items: categories
                          .map(
                            (value) => DropdownMenuItem<String>(
                              value: value,
                              child: Text(value, overflow: TextOverflow.ellipsis),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => categoryFilter = value);
                      },
                    ),
                  ),
                  SizedBox(
                    width: 190,
                    child: DropdownButtonFormField<String>(
                      value: safeParish,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Product parish',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      items: parishes
                          .map(
                            (value) => DropdownMenuItem<String>(
                              value: value,
                              child: Text(value, overflow: TextOverflow.ellipsis),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => parishFilter = value);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 760;
                  final cards = <Widget>[
                    _HpjDemandMetricCard(
                      label: 'Units sold',
                      value: '$totalUnits',
                      detail: 'Confirmed non-cancelled orders',
                      icon: Icons.shopping_bag_outlined,
                    ),
                    _HpjDemandMetricCard(
                      label: 'Revenue signal',
                      value: 'J\$${totalRevenue.toStringAsFixed(0)}',
                      detail: 'From products in this view',
                      icon: Icons.payments_outlined,
                    ),
                    _HpjDemandMetricCard(
                      label: 'Unmet searches',
                      value: '$zeroResultSearches',
                      detail: 'Searches that found no result',
                      icon: Icons.search_off_rounded,
                    ),
                    _HpjDemandMetricCard(
                      label: 'Repeat winners',
                      value: '$repeatWinners',
                      detail: 'Products with repeat buyers',
                      icon: Icons.replay_rounded,
                    ),
                  ];

                  if (wide) {
                    return Row(
                      children: [
                        for (var i = 0; i < cards.length; i++) ...[
                          Expanded(child: cards[i]),
                          if (i != cards.length - 1) const SizedBox(width: 8),
                        ],
                      ],
                    );
                  }

                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: cards
                        .map(
                          (card) => SizedBox(
                            width: (constraints.maxWidth - 8) / 2,
                            child: card,
                          ),
                        )
                        .toList(),
                  );
                },
              ),
              const SizedBox(height: 14),
              _HpjProductDemandSectionCard(
                title: 'Decision queue',
                subtitle:
                    'Products HPJ should review first for sourcing, stock protection, conversion or rising demand.',
                child: decisionQueue.isEmpty
                    ? const _HpjDemandEmpty(
                        message:
                            'No priority product decisions yet. Customer activity will build this queue over time.',
                      )
                    : Column(
                        children: decisionQueue
                            .map(
                              (item) => _HpjProductDemandRow(
                                item: item,
                                decisionColor: _decisionColor(item.decisionSignal),
                                trendLabel: _trendLabel(item.trendPct),
                                compact: false,
                              ),
                            )
                            .toList(),
                      ),
              ),
              const SizedBox(height: 14),
              _HpjProductDemandSectionCard(
                title: 'Product interest & buying behaviour',
                subtitle:
                    'Search and browsing intent should support—not replace—confirmed order data. Demand Score weights views, saves, My Box actions, units sold and repeat buying.',
                child: products.isEmpty
                    ? const _HpjDemandEmpty(
                        message:
                            'No matching product signals yet for this period and filter.',
                      )
                    : Column(
                        children: products
                            .take(35)
                            .map(
                              (item) => _HpjProductDemandRow(
                                item: item,
                                decisionColor: _decisionColor(item.decisionSignal),
                                trendLabel: _trendLabel(item.trendPct),
                                compact: true,
                              ),
                            )
                            .toList(),
                      ),
              ),
              const SizedBox(height: 14),
              _HpjProductDemandSectionCard(
                title: 'Unmet search demand',
                subtitle:
                    'These phrases help expose products customers want but cannot easily find in the marketplace.',
                child: searchGaps.where((item) => item.zeroResultSearches > 0).isEmpty
                    ? const _HpjDemandEmpty(
                        message: 'No zero-result customer searches in this period.',
                      )
                    : Column(
                        children: searchGaps
                            .where((item) => item.zeroResultSearches > 0)
                            .take(25)
                            .map((item) => _HpjSearchGapRow(item: item))
                            .toList(),
                      ),
              ),
              const SizedBox(height: 14),
              const _HpjProductDemandSectionCard(
                title: 'How to use this dashboard',
                subtitle: 'Interest is evidence—not a guaranteed future order.',
                child: Text(
                  'Use Source more when strong interest meets low or unavailable stock. Protect repeat supply highlights products with repeat customers. Review conversion flags products reaching My Box but producing few orders. Rising demand compares the selected period with the previous equal period. Grow Intelligence should still be used before making planting commitments because it combines broader demand and confirmed supply signals.',
                  style: TextStyle(
                    color: FarmColors.ink,
                    fontSize: 12.5,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      return ColoredBox(
        color: FarmColors.background,
        child: _buildBody(),
      );
    }

    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: AppBar(
        title: const Text('Product Interest & Demand'),
        backgroundColor: FarmColors.background,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => setState(_reload),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }
}

class _HpjProductDemandHero extends StatelessWidget {
  final int days;
  final int productCount;
  final int sourceMoreCount;
  final int conversionGapCount;
  final int repeatWinnerCount;
  final VoidCallback onRefresh;

  const _HpjProductDemandHero({
    required this.days,
    required this.productCount,
    required this.sourceMoreCount,
    required this.conversionGapCount,
    required this.repeatWinnerCount,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [FarmColors.deepGreen, FarmColors.green],
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CUSTOMER PRODUCT INTELLIGENCE',
                      style: TextStyle(
                        color: Color(0xFFE8C768),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .85,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'What customers want → what HPJ should do',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        height: 1.08,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Refresh demand data',
                onPressed: onRefresh,
                color: Colors.white,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Last $days days • $productCount products with signals • $sourceMoreCount source-more alerts • $conversionGapCount conversion gaps • $repeatWinnerCount repeat winners',
            style: TextStyle(
              color: Colors.white.withOpacity(.88),
              fontSize: 11.5,
              height: 1.4,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HpjDemandMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String detail;
  final IconData icon;

  const _HpjDemandMetricCard({
    required this.label,
    required this.value,
    required this.detail,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: FarmColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: FarmColors.green, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: FarmColors.deepGreen,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: FarmColors.ink,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            detail,
            style: const TextStyle(
              color: FarmColors.mutedText,
              fontSize: 8.8,
              height: 1.25,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HpjProductDemandSectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _HpjProductDemandSectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: FarmColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: FarmColors.deepGreen,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: FarmColors.mutedText,
              fontSize: 10.5,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _HpjProductDemandRow extends StatelessWidget {
  final HpjProductInterestSignal item;
  final Color decisionColor;
  final String trendLabel;
  final bool compact;

  const _HpjProductDemandRow({
    required this.item,
    required this.decisionColor,
    required this.trendLabel,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final source = <String>[
      if (item.farmName.trim().isNotEmpty) item.farmName.trim(),
      if (item.parish.trim().isNotEmpty) item.parish.trim(),
    ].join(' • ');

    return Container(
      padding: EdgeInsets.symmetric(vertical: compact ? 10 : 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: FarmColors.line)),
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
                      item.productName,
                      style: const TextStyle(
                        color: FarmColors.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (source.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        source,
                        style: const TextStyle(
                          color: FarmColors.mutedText,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: decisionColor.withOpacity(.10),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: decisionColor.withOpacity(.28)),
                ),
                child: Text(
                  item.decisionSignal,
                  style: TextStyle(
                    color: decisionColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Wrap(
            spacing: 9,
            runSpacing: 5,
            children: [
              _HpjInlineMetric(label: 'Score', value: item.demandScore.toStringAsFixed(0)),
              _HpjInlineMetric(label: 'Searches', value: '${item.searches}'),
              _HpjInlineMetric(label: 'Views', value: '${item.views}'),
              _HpjInlineMetric(label: 'Saves', value: '${item.favoriteAdds}'),
              _HpjInlineMetric(label: 'Box adds', value: '${item.cartAdds}'),
              _HpjInlineMetric(label: 'Units sold', value: '${item.unitsSold}'),
              _HpjInlineMetric(label: 'Buyers', value: '${item.buyers}'),
              _HpjInlineMetric(label: 'Repeat', value: '${item.repeatBuyers}'),
              _HpjInlineMetric(label: 'Convert', value: '${item.conversionPct.toStringAsFixed(0)}%'),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${item.supplyStatus} • ${item.stockQuantity} in stock',
                  style: const TextStyle(
                    color: FarmColors.mutedText,
                    fontSize: 9.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                trendLabel,
                style: TextStyle(
                  color: item.trendPct >= 25
                      ? FarmColors.green
                      : item.trendPct <= -25
                          ? const Color(0xFF9A6514)
                          : FarmColors.mutedText,
                  fontSize: 9.2,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HpjInlineMetric extends StatelessWidget {
  final String label;
  final String value;

  const _HpjInlineMetric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      '$label $value',
      style: const TextStyle(
        color: FarmColors.ink,
        fontSize: 9.2,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _HpjSearchGapRow extends StatelessWidget {
  final HpjUnmetSearchSignal item;

  const _HpjSearchGapRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final strong = item.zeroResultSearches >= 3;
    final accent = strong ? const Color(0xFFB55222) : const Color(0xFF8A6411);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: FarmColors.line)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: accent.withOpacity(.10),
            child: Icon(Icons.search_off_rounded, color: accent, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.query,
                  style: const TextStyle(
                    color: FarmColors.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${item.searches} searches • ${item.uniqueUsers} customers • ${item.zeroResultSearches} no-result • ${item.zeroResultRate.toStringAsFixed(0)}% gap rate',
                  style: const TextStyle(
                    color: FarmColors.mutedText,
                    fontSize: 9.2,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            item.decisionSignal,
            style: TextStyle(
              color: accent,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _HpjDemandEmpty extends StatelessWidget {
  final String message;

  const _HpjDemandEmpty({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: FarmColors.mutedText,
          fontSize: 11,
          height: 1.4,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
