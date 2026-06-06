// Replace _HomeScreenState.loadHomeProducts() and refreshHomeProducts() with this.

Future<List<Product>> loadHomeProducts({bool forceRefresh = false}) async {
  final cached = FarmDataCache.products;

  if (!forceRefresh && cached != null && cached.isNotEmpty) {
    final visible = List<Product>.from(cached)
      ..sort(compareCustomerProductAvailabilityThenName);

    cachedHomeProducts = visible;

    // Refresh quietly after showing cached products first.
    unawaited(_refreshHomeProductsQuietly());

    return cachedHomeProducts;
  }

  final products = await fetchProductsForCustomerUi(
    forceRefresh: forceRefresh,
    timeout: const Duration(seconds: 10),
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
      timeout: const Duration(seconds: 10),
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
  final nextBuyAgainProducts = fetchBuyAgainProductsForCustomerUi(
    forceRefresh: true,
  );
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
