// Replace _ShopScreenState.loadProducts() and _loadOptionalShopProductSections() with this.

Future<void> loadProducts({bool forceRefresh = false}) async {
  if (!mounted) return;

  final cached = FarmDataCache.products;
  if (!forceRefresh && cached != null && cached.isNotEmpty) {
    final cleanCached = List<Product>.from(cached)
      ..removeWhere(
        (product) => product.name.trim().isEmpty || product.price < 0,
      )
      ..sort(compareCustomerProductAvailabilityThenName);

    if (mounted) {
      setState(() {
        products = cleanCached;
        loadingProducts = false;
        productLoadMessage = cleanCached.isEmpty
            ? 'No fresh products are available right now. Please check back soon.'
            : null;
      });
    }

    unawaited(_refreshShopProductsQuietly());
    unawaited(_loadOptionalShopProductSections());
    return;
  }

  setState(() {
    loadingProducts = true;
    productLoadMessage = null;
  });

  try {
    final fetchedProducts = await fetchProductsForCustomerUi(
      forceRefresh: forceRefresh,
      timeout: const Duration(seconds: 10),
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

    unawaited(_loadOptionalShopProductSections());
  } catch (error) {
    farmDebugLog('Shop product load failed: $error');

    if (!mounted) return;

    final fallback = FarmDataCache.products ?? products;

    setState(() {
      products = fallback;
      loadingProducts = false;
      productLoadMessage = fallback.isEmpty
          ? 'We couldn’t load fresh products right now. Please try again.'
          : null;
    });
  }
}

Future<void> _refreshShopProductsQuietly() async {
  try {
    final fetchedProducts = await fetchProductsForCustomerUi(
      forceRefresh: true,
      timeout: const Duration(seconds: 10),
    );

    final cleanProducts = fetchedProducts.where((product) {
      return product.name.trim().isNotEmpty && product.price >= 0;
    }).toList()
      ..sort(compareCustomerProductAvailabilityThenName);

    if (!mounted || cleanProducts.isEmpty) return;

    setState(() {
      products = cleanProducts;
      loadingProducts = false;
      productLoadMessage = null;
    });
  } catch (error) {
    farmDebugLog('Quiet shop refresh skipped: $error');
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
