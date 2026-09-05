part of harvest_place_app;

// =============================================================
// HPJ PHASE 038 — PUBLIC FARM PROFILES MVP
// =============================================================
// Purpose:
// - Give each approved HPJ farmer a public, marketplace-safe farm page.
// - Keep private phone/email/exact address/payout data OUT of the public page.
// - Keep commerce and enquiries inside HPJ.
// - Let Owner/Manager prepare and publish pages before farmers manage them.
// - Reuse existing HPJ products and Customer Care instead of creating a
//   duplicate marketplace or chat system.
// =============================================================

class FarmPublicProfileRecord {
  final String farmerId;
  final String publicName;
  final String community;
  final String parish;
  final String publicBio;
  final String? coverImageUrl;
  final String? logoImageUrl;
  final List<String> tags;
  final List<String> farmingPractices;
  final bool isPublished;
  final bool hpjVerified;
  final String shareSlug;
  final DateTime? updatedAt;

  const FarmPublicProfileRecord({
    required this.farmerId,
    required this.publicName,
    required this.community,
    required this.parish,
    required this.publicBio,
    this.coverImageUrl,
    this.logoImageUrl,
    this.tags = const <String>[],
    this.farmingPractices = const <String>[],
    required this.isPublished,
    required this.hpjVerified,
    required this.shareSlug,
    this.updatedAt,
  });

  factory FarmPublicProfileRecord.fromSupabase(Map<String, dynamic> data) {
    List<String> strings(dynamic value) {
      if (value is List) {
        return value
            .map((item) => item.toString().trim())
            .where((item) => item.isNotEmpty)
            .toList();
      }
      return const <String>[];
    }

    final cover = cleanHostedImageUrl(data['cover_image_url']?.toString());
    final logo = cleanHostedImageUrl(data['logo_image_url']?.toString());

    return FarmPublicProfileRecord(
      farmerId: (data['farmer_id'] ?? '').toString(),
      publicName: (data['public_name'] ?? 'HPJ Partner Farm').toString().trim(),
      community: (data['community'] ?? '').toString().trim(),
      parish: (data['parish'] ?? '').toString().trim(),
      publicBio: (data['public_bio'] ?? '').toString().trim(),
      coverImageUrl: cover,
      logoImageUrl: logo,
      tags: strings(data['tags']),
      farmingPractices: strings(data['farming_practices']),
      isPublished: data['is_published'] == true,
      hpjVerified: data['hpj_verified'] == true,
      shareSlug: (data['share_slug'] ?? '').toString().trim(),
      updatedAt: DateTime.tryParse((data['updated_at'] ?? '').toString()),
    );
  }

  String get locationLine {
    final values = <String>[
      if (community.isNotEmpty) community,
      if (parish.isNotEmpty) parish,
    ];
    return values.isEmpty ? 'Jamaica' : values.join(', ');
  }
}

class FarmPublicPhoto {
  final String id;
  final String farmerId;
  final String imageUrl;
  final String caption;
  final int sortOrder;
  final bool isActive;

  const FarmPublicPhoto({
    required this.id,
    required this.farmerId,
    required this.imageUrl,
    required this.caption,
    required this.sortOrder,
    required this.isActive,
  });

  factory FarmPublicPhoto.fromSupabase(Map<String, dynamic> data) {
    return FarmPublicPhoto(
      id: (data['id'] ?? '').toString(),
      farmerId: (data['farmer_id'] ?? '').toString(),
      imageUrl: cleanHostedImageUrl(data['image_url']?.toString()) ?? '',
      caption: (data['caption'] ?? '').toString().trim(),
      sortOrder: int.tryParse((data['sort_order'] ?? '100').toString()) ?? 100,
      isActive: data['is_active'] != false,
    );
  }
}

class PublicFarmSupplyItem {
  final String cropName;
  final String category;
  final String stage;
  final String unit;
  final DateTime? expectedHarvestDate;
  final String? linkedProductId;
  final bool sellToCustomer;
  final bool sellToWholesale;

  const PublicFarmSupplyItem({
    required this.cropName,
    required this.category,
    required this.stage,
    required this.unit,
    this.expectedHarvestDate,
    this.linkedProductId,
    this.sellToCustomer = false,
    this.sellToWholesale = true,
  });

  factory PublicFarmSupplyItem.fromSupabase(Map<String, dynamic> data) {
    final rawProductId = (data['linked_product_id'] ?? '').toString().trim();

    return PublicFarmSupplyItem(
      cropName: (data['crop_name'] ?? '').toString().trim(),
      category: (data['category'] ?? '').toString().trim(),
      stage: (data['stage'] ?? 'growing').toString().trim().toLowerCase(),
      unit: (data['unit'] ?? '').toString().trim(),
      expectedHarvestDate:
          DateTime.tryParse((data['expected_harvest_date'] ?? '').toString()),
      linkedProductId: rawProductId.isEmpty ? null : rawProductId,
      sellToCustomer: data['sell_to_customer'] == true,
      sellToWholesale: data['sell_to_wholesale'] != false,
    );
  }

  String get stageLabel {
    switch (stage) {
      case 'planning':
        return 'Planning';
      case 'expected':
        return 'Expected';
      case 'harvest_ready':
        return 'Harvest ready';
      case 'harvested':
        return 'Harvested';
      case 'hpj_confirmed':
        return 'Confirmed with HPJ';
      default:
        return 'Growing';
    }
  }

  bool get isReadyNow =>
      stage == 'harvest_ready' ||
      stage == 'harvested' ||
      stage == 'hpj_confirmed';

  bool get hasLinkedProduct =>
      linkedProductId != null && linkedProductId!.trim().isNotEmpty;

  String get marketChannelLabel {
    if (sellToCustomer && sellToWholesale) {
      return 'Customer + Wholesale';
    }
    if (sellToCustomer) return 'Customer Marketplace';
    if (sellToWholesale) return 'Wholesale Business';
    return 'HPJ supply';
  }
}

class FarmPublicProfileBundle {
  final FarmPublicProfileRecord? profile;
  final List<Product> products;
  final List<FarmPublicPhoto> photos;
  final List<PublicFarmSupplyItem> growingSupply;

  const FarmPublicProfileBundle({
    required this.profile,
    required this.products,
    required this.photos,
    required this.growingSupply,
  });
}

const String _farmPublicProfileSelectFields =
    'farmer_id, public_name, community, parish, public_bio, '
    'cover_image_url, logo_image_url, tags, farming_practices, '
    'is_published, hpj_verified, share_slug, updated_at';

const String _farmPublicPhotoSelectFields =
    'id, farmer_id, image_url, caption, sort_order, is_active, created_at';

const String _farmPublicProductSelectFields =
    'id, name, description, price, unit, image_url, is_available, '
    'stock_quantity, created_at, category, is_organic, is_local, '
    'harvest_date, farmer_id, farmer_name, farm_name, parish, '
    'approval_status, platform_commission_percent, original_price, '
    'discount_price, discount_percent, discount_label, discount_starts_at, '
    'discount_ends_at, is_discount_active, product_status, ready_soon, '
    'estimated_ready_date, expected_stock_quantity, is_deal_of_day, deal_rank, '
    'subscribe_save_enabled, subscribe_save_discount_percent, nutrient_strong, '
    'nutrient_good, nutrient_contains, nutrition_notes, nutrition_source, '
    'nutrition_verified, usda_fdc_id, serving_size_g';

Future<FarmPublicProfileRecord?> fetchFarmPublicProfile(
  String farmerId, {
  bool includeUnpublished = false,
}) async {
  final cleanId = farmerId.trim();
  if (cleanId.isEmpty) return null;

  try {
    final response = includeUnpublished
        ? await supabase
            .from('farm_public_profiles')
            .select(_farmPublicProfileSelectFields)
            .eq('farmer_id', cleanId)
            .maybeSingle()
        : await supabase
            .from('farm_public_profiles')
            .select(_farmPublicProfileSelectFields)
            .eq('farmer_id', cleanId)
            .eq('is_published', true)
            .maybeSingle();

    if (response == null) return null;
    return FarmPublicProfileRecord.fromSupabase(
      Map<String, dynamic>.from(response),
    );
  } catch (error) {
    farmDebugLog('Public farm profile unavailable: $error');
    return null;
  }
}

Future<List<FarmPublicPhoto>> fetchFarmPublicPhotos(
  String farmerId, {
  bool includeInactive = false,
}) async {
  final cleanId = farmerId.trim();
  if (cleanId.isEmpty) return const <FarmPublicPhoto>[];

  try {
    final response = includeInactive
        ? await supabase
            .from('farm_public_photos')
            .select(_farmPublicPhotoSelectFields)
            .eq('farmer_id', cleanId)
            .order('sort_order', ascending: true)
        : await supabase
            .from('farm_public_photos')
            .select(_farmPublicPhotoSelectFields)
            .eq('farmer_id', cleanId)
            .eq('is_active', true)
            .order('sort_order', ascending: true);

    return (response as List)
        .map(
          (item) => FarmPublicPhoto.fromSupabase(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .where((photo) => photo.imageUrl.isNotEmpty)
        .toList();
  } catch (error) {
    farmDebugLog('Public farm photos unavailable: $error');
    return const <FarmPublicPhoto>[];
  }
}

Future<List<FarmPublicProfileRecord>> fetchPublishedFarmPublicProfiles({
  int limit = 8,
}) async {
  final safeLimit = limit.clamp(1, 40).toInt();

  try {
    final response = await supabase
        .from('farm_public_profiles')
        .select(_farmPublicProfileSelectFields)
        .eq('is_published', true)
        .order('hpj_verified', ascending: false)
        .order('public_name', ascending: true)
        .limit(safeLimit);

    return (response as List)
        .map(
          (item) => FarmPublicProfileRecord.fromSupabase(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .where((profile) => profile.farmerId.isNotEmpty)
        .toList();
  } catch (error) {
    farmDebugLog('Published farm profiles unavailable: $error');
    return const <FarmPublicProfileRecord>[];
  }
}

Future<List<PublicFarmSupplyItem>> fetchPublicFarmGrowingSupply(
  String farmerId,
) async {
  final cleanId = farmerId.trim();
  if (cleanId.isEmpty) return const <PublicFarmSupplyItem>[];

  try {
    final response = await supabase.rpc(
      'public_farm_growing_supply',
      params: <String, dynamic>{
        'p_farmer_id': cleanId,
      },
    );

    return (response as List)
        .map(
          (item) => PublicFarmSupplyItem.fromSupabase(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .where((item) => item.cropName.isNotEmpty)
        .toList();
  } catch (error) {
    farmDebugLog('Public farm growing supply unavailable: $error');
    return const <PublicFarmSupplyItem>[];
  }
}

Future<List<Product>> fetchPublicFarmProducts(String farmerId) async {
  final cleanId = farmerId.trim();
  if (cleanId.isEmpty) return const <Product>[];

  try {
    final response = await supabase
        .from('products')
        .select(_farmPublicProductSelectFields)
        .eq('farmer_id', cleanId)
        .order('is_available', ascending: false)
        .order('name', ascending: true);

    return (response as List)
        .map(
          (item) => Product.fromSupabase(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .where((product) => product.isApproved && !product.isHidden)
        .toList();
  } catch (error) {
    // Keep this feature incremental: if an older Supabase project rejects one
    // optional product column, reuse HPJ's existing catalogue service safely.
    farmDebugLog(
        'Farm product direct lookup unavailable, using catalogue: $error');
    try {
      final all = await fetchProducts();
      return all
          .where(
            (product) =>
                product.farmerId?.trim() == cleanId &&
                product.isApproved &&
                !product.isHidden,
          )
          .toList();
    } catch (fallbackError) {
      farmDebugLog(
          'Farm product catalogue fallback unavailable: $fallbackError');
      return const <Product>[];
    }
  }
}

Future<FarmPublicProfileBundle> fetchFarmPublicProfileBundle(
  String farmerId, {
  bool includeUnpublished = false,
}) async {
  final values = await Future.wait<dynamic>([
    fetchFarmPublicProfile(
      farmerId,
      includeUnpublished: includeUnpublished,
    ),
    fetchPublicFarmProducts(farmerId),
    fetchFarmPublicPhotos(
      farmerId,
      includeInactive: includeUnpublished,
    ),
    fetchPublicFarmGrowingSupply(farmerId),
  ]);

  return FarmPublicProfileBundle(
    profile: values[0] as FarmPublicProfileRecord?,
    products: values[1] as List<Product>,
    photos: values[2] as List<FarmPublicPhoto>,
    growingSupply: values[3] as List<PublicFarmSupplyItem>,
  );
}

List<String> _farmPublicCleanList(Iterable<String> values) {
  final seen = <String>{};
  final output = <String>[];

  for (final value in values) {
    final clean = value.trim();
    if (clean.isEmpty) continue;
    final key = clean.toLowerCase();
    if (seen.add(key)) output.add(clean);
  }

  return output.take(12).toList();
}

String _farmPublicSlug(String value, String farmerId) {
  var clean = value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');

  if (clean.isEmpty) clean = 'jamaican-farm';
  final suffix = farmerId.replaceAll('-', '');
  final shortSuffix = suffix.length <= 6 ? suffix : suffix.substring(0, 6);
  return '$clean-$shortSuffix';
}

Future<void> adminSaveFarmPublicProfile({
  required FarmerProfile farmer,
  required String publicName,
  required String community,
  required String publicBio,
  required List<String> tags,
  required List<String> farmingPractices,
  required bool isPublished,
  required bool hpjVerified,
  String? coverImageUrl,
  String? logoImageUrl,
}) async {
  await requireAdminAccess();

  final cleanName = publicName.trim().isEmpty
      ? (farmer.farmName.trim().isEmpty ? farmer.farmerName : farmer.farmName)
      : publicName.trim();

  final payload = <String, dynamic>{
    'farmer_id': farmer.id,
    'public_name': cleanName,
    'community': community.trim(),
    'parish': farmer.parish.trim(),
    'public_bio': publicBio.trim(),
    'cover_image_url': cleanHostedImageUrl(coverImageUrl),
    'logo_image_url': cleanHostedImageUrl(logoImageUrl),
    'tags': _farmPublicCleanList(tags),
    'farming_practices': _farmPublicCleanList(farmingPractices),
    'is_published': isPublished && farmer.isApproved,
    'hpj_verified': hpjVerified && farmer.isApproved,
    'share_slug': _farmPublicSlug(cleanName, farmer.id),
    'updated_at': DateTime.now().toIso8601String(),
  };

  await supabase.from('farm_public_profiles').upsert(
        payload,
        onConflict: 'farmer_id',
      );
}

Future<String> adminUploadFarmPublicImage({
  required String farmerId,
  required String slot,
  required PickedProductImage image,
}) async {
  await requireAdminAccess();

  if (image.bytes.isEmpty) {
    throw Exception('Choose a valid farm image.');
  }

  const maxBytes = 6 * 1024 * 1024;
  if (image.bytes.length > maxBytes) {
    throw Exception('Image is too large. Please upload an image under 6 MB.');
  }

  final cleanFarmerId = farmerId.trim();
  if (cleanFarmerId.isEmpty) {
    throw Exception('This farmer profile is missing an ID.');
  }

  final cleanSlot =
      slot.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9-]+'), '-');
  final safeName = _safeProductImageFileName(image.fileName);
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final path =
      'farm-profiles/$cleanFarmerId/${cleanSlot.isEmpty ? 'image' : cleanSlot}/$timestamp-$safeName';

  await supabase.storage.from(productImageStorageBucket).uploadBinary(
        path,
        image.bytes,
        fileOptions: FileOptions(
          contentType: _contentTypeForImage(image),
          upsert: false,
        ),
      );

  return supabase.storage.from(productImageStorageBucket).getPublicUrl(path);
}

Future<void> adminAddFarmPublicPhoto({
  required String farmerId,
  required String imageUrl,
  String caption = '',
}) async {
  await requireAdminAccess();

  final cleanUrl = cleanHostedImageUrl(imageUrl);
  if (cleanUrl == null) {
    throw Exception('Upload a valid farm photo first.');
  }

  final existing = await fetchFarmPublicPhotos(
    farmerId,
    includeInactive: true,
  );

  await supabase.from('farm_public_photos').insert({
    'farmer_id': farmerId,
    'image_url': cleanUrl,
    'caption': caption.trim(),
    'sort_order': existing.length + 1,
    'is_active': true,
  });
}

Future<void> adminDeleteFarmPublicPhoto(String photoId) async {
  await requireAdminAccess();
  final cleanId = photoId.trim();
  if (cleanId.isEmpty) return;
  await supabase.from('farm_public_photos').delete().eq('id', cleanId);
}

// =====================================================
// HPJ PHASE 041 — FARMER-SAFE PUBLIC PAGE MANAGEMENT
//
// Farmers may update marketplace-safe identity fields and images for their
// own farm. Publishing and HPJ Verified remain Admin-controlled.
// =====================================================

Future<void> farmerSaveOwnPublicFarmProfile({
  required String publicName,
  required String community,
  required String publicBio,
  required List<String> tags,
  required List<String> farmingPractices,
  String? coverImageUrl,
  String? logoImageUrl,
}) async {
  final user = supabase.auth.currentUser;
  if (user == null) {
    throw Exception('Please sign in again.');
  }

  await supabase.rpc(
    'farmer_update_own_public_farm_profile',
    params: <String, dynamic>{
      'p_public_name': publicName.trim(),
      'p_community': community.trim(),
      'p_public_bio': publicBio.trim(),
      'p_tags': _farmPublicCleanList(tags),
      'p_farming_practices': _farmPublicCleanList(farmingPractices),
      'p_cover_image_url': cleanHostedImageUrl(coverImageUrl),
      'p_logo_image_url': cleanHostedImageUrl(logoImageUrl),
    },
  );
}

Future<String> farmerUploadOwnPublicFarmImage({
  required String farmerId,
  required String slot,
  required PickedProductImage image,
}) async {
  final user = supabase.auth.currentUser;
  if (user == null) {
    throw Exception('Please sign in again.');
  }

  final cleanFarmerId = farmerId.trim();
  if (cleanFarmerId.isEmpty) {
    throw Exception('This farmer profile is missing an ID.');
  }

  if (image.bytes.isEmpty) {
    throw Exception('Choose a valid farm image.');
  }

  const maxBytes = 6 * 1024 * 1024;
  if (image.bytes.length > maxBytes) {
    throw Exception('Image is too large. Please upload an image under 6 MB.');
  }

  final cleanSlot =
      slot.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9-]+'), '-');
  final safeName = _safeProductImageFileName(image.fileName);
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final path =
      'farm-profiles/$cleanFarmerId/${cleanSlot.isEmpty ? 'image' : cleanSlot}/$timestamp-$safeName';

  await supabase.storage.from(productImageStorageBucket).uploadBinary(
        path,
        image.bytes,
        fileOptions: FileOptions(
          contentType: _contentTypeForImage(image),
          upsert: false,
        ),
      );

  return supabase.storage.from(productImageStorageBucket).getPublicUrl(path);
}

Future<void> farmerAddOwnPublicFarmPhoto({
  required String imageUrl,
  String caption = '',
}) async {
  final cleanUrl = cleanHostedImageUrl(imageUrl);
  if (cleanUrl == null) {
    throw Exception('Upload a valid farm photo first.');
  }

  await supabase.rpc(
    'farmer_add_own_public_farm_photo',
    params: <String, dynamic>{
      'p_image_url': cleanUrl,
      'p_caption': caption.trim(),
    },
  );
}

Future<void> farmerDeleteOwnPublicFarmPhoto(String photoId) async {
  final cleanId = photoId.trim();
  if (cleanId.isEmpty) return;

  await supabase.rpc(
    'farmer_delete_own_public_farm_photo',
    params: <String, dynamic>{
      'p_photo_id': cleanId,
    },
  );
}

class PublicFarmProfileButton extends StatelessWidget {
  final Product product;
  final void Function(Product product)? onAddProduct;
  final String sourceWorkspace;

  const PublicFarmProfileButton({
    super.key,
    required this.product,
    this.onAddProduct,
    this.sourceWorkspace = 'customer',
  });

  @override
  Widget build(BuildContext context) {
    final farmerId = product.farmerId?.trim() ?? '';
    if (farmerId.isEmpty) return const SizedBox.shrink();

    return FutureBuilder<FarmPublicProfileRecord?>(
      future: fetchFarmPublicProfile(farmerId),
      builder: (context, snapshot) {
        final profile = snapshot.data;
        if (profile == null || !profile.isPublished) {
          return const SizedBox.shrink();
        }

        return SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PublicFarmProfileScreen(
                    farmerId: farmerId,
                    sourceWorkspace: sourceWorkspace,
                    onAddProduct: onAddProduct,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.storefront_outlined),
            label: Text('View ${profile.publicName}'),
          ),
        );
      },
    );
  }
}

class FeaturedPublicFarmsSection extends StatelessWidget {
  final void Function(Product product)? onAddProduct;
  final String sourceWorkspace;

  const FeaturedPublicFarmsSection({
    super.key,
    this.onAddProduct,
    this.sourceWorkspace = 'customer',
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<FarmPublicProfileRecord>>(
      future: fetchPublishedFarmPublicProfiles(limit: 8),
      builder: (context, snapshot) {
        final farms = snapshot.data ?? const <FarmPublicProfileRecord>[];
        if (snapshot.connectionState == ConnectionState.waiting &&
            farms.isEmpty) {
          return const SizedBox(
            height: 174,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (farms.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Featured Farms',
              subtitle: 'Meet the Jamaican farms behind your food',
              actionLabel: 'See all',
              onAction: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => PublicFarmDirectoryScreen(
                      sourceWorkspace: sourceWorkspace,
                      onAddProduct: onAddProduct,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 178,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: farms.length,
                separatorBuilder: (_, __) => const SizedBox(width: 11),
                itemBuilder: (context, index) {
                  final farm = farms[index];
                  return _PublicFarmDiscoveryCard(
                    profile: farm,
                    width: 178,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => PublicFarmProfileScreen(
                            farmerId: farm.farmerId,
                            sourceWorkspace: sourceWorkspace,
                            onAddProduct: onAddProduct,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class PublicFarmDirectoryScreen extends StatefulWidget {
  final String sourceWorkspace;
  final void Function(Product product)? onAddProduct;
  final BusinessAccount? wholesaleAccount;

  const PublicFarmDirectoryScreen({
    super.key,
    this.sourceWorkspace = 'customer',
    this.onAddProduct,
    this.wholesaleAccount,
  });

  @override
  State<PublicFarmDirectoryScreen> createState() =>
      _PublicFarmDirectoryScreenState();
}

class _PublicFarmDirectoryScreenState extends State<PublicFarmDirectoryScreen> {
  late Future<List<FarmPublicProfileRecord>> _future;
  final searchController = TextEditingController();
  String query = '';

  @override
  void initState() {
    super.initState();
    _future = fetchPublishedFarmPublicProfiles(limit: 40);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final future = fetchPublishedFarmPublicProfiles(limit: 40);
    setState(() => _future = future);
    await future;
  }

  bool _matches(FarmPublicProfileRecord profile) {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return true;
    final haystack = <String>[
      profile.publicName,
      profile.community,
      profile.parish,
      profile.publicBio,
      ...profile.tags,
      ...profile.farmingPractices,
    ].join(' ').toLowerCase();
    return haystack.contains(clean);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: AppBar(title: const Text('Jamaican Farms')),
      body: SafeArea(
        top: false,
        child: FutureBuilder<List<FarmPublicProfileRecord>>(
          future: _future,
          builder: (context, snapshot) {
            final farms = (snapshot.data ?? const <FarmPublicProfileRecord>[])
                .where(_matches)
                .toList();

            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 120),
                children: [
                  const Header(
                    title: 'Discover Jamaican Farms',
                    subtitle: 'Farm stories and produce supplied through HPJ',
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: searchController,
                    onChanged: (value) => setState(() => query = value),
                    decoration: const InputDecoration(
                      hintText: 'Search farms, parish or farming practice...',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      snapshot.data == null)
                    const SizedBox(
                      height: 260,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (farms.isEmpty)
                    const FarmEmptyState(
                      icon: Icons.agriculture_outlined,
                      title: 'No farms found',
                      message:
                          'Try another search or check back as more HPJ partner farms go live.',
                    )
                  else
                    ...farms.map(
                      (farm) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _PublicFarmDirectoryTile(
                          profile: farm,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => PublicFarmProfileScreen(
                                  farmerId: farm.farmerId,
                                  sourceWorkspace: widget.sourceWorkspace,
                                  onAddProduct: widget.onAddProduct,
                                  wholesaleAccount: widget.wholesaleAccount,
                                ),
                              ),
                            );
                          },
                        ),
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

class _PublicFarmDiscoveryCard extends StatelessWidget {
  final FarmPublicProfileRecord profile;
  final double width;
  final VoidCallback onTap;

  const _PublicFarmDiscoveryCard({
    required this.profile,
    required this.width,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final image = cleanHostedImageUrl(profile.coverImageUrl) ??
        cleanHostedImageUrl(profile.logoImageUrl);

    return SizedBox(
      width: width,
      child: Material(
        color: FarmColors.card,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: FarmColors.line),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 105,
                  width: double.infinity,
                  child: image == null
                      ? const ColoredBox(
                          color: FarmColors.primarySoft,
                          child: Center(
                            child: Icon(
                              Icons.landscape_rounded,
                              color: FarmColors.green,
                              size: 36,
                            ),
                          ),
                        )
                      : Image.network(
                          image,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const ColoredBox(
                            color: FarmColors.primarySoft,
                            child: Center(
                              child: Icon(
                                Icons.landscape_rounded,
                                color: FarmColors.green,
                              ),
                            ),
                          ),
                        ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(11, 9, 11, 9),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                profile.publicName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: FarmColors.deepGreen,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            if (profile.hpjVerified)
                              const Icon(
                                Icons.verified_rounded,
                                color: FarmColors.gold,
                                size: 15,
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          profile.locationLine,
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PublicFarmDirectoryTile extends StatelessWidget {
  final FarmPublicProfileRecord profile;
  final VoidCallback onTap;

  const _PublicFarmDirectoryTile({
    required this.profile,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final image = cleanHostedImageUrl(profile.coverImageUrl) ??
        cleanHostedImageUrl(profile.logoImageUrl);

    return FarmCard(
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 82,
                  height: 82,
                  child: image == null
                      ? const ColoredBox(
                          color: FarmColors.primarySoft,
                          child: Icon(
                            Icons.agriculture_rounded,
                            color: FarmColors.green,
                            size: 32,
                          ),
                        )
                      : Image.network(
                          image,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const ColoredBox(
                            color: FarmColors.primarySoft,
                            child: Icon(
                              Icons.agriculture_rounded,
                              color: FarmColors.green,
                            ),
                          ),
                        ),
                ),
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
                            profile.publicName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: FarmColors.deepGreen,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (profile.hpjVerified)
                          const Icon(
                            Icons.verified_rounded,
                            color: FarmColors.gold,
                            size: 18,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile.locationLine,
                      style: const TextStyle(
                        color: FarmColors.mutedText,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (profile.tags.isNotEmpty) ...[
                      const SizedBox(height: 7),
                      Text(
                        profile.tags.take(3).join(' • '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: FarmColors.green,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: FarmColors.green,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PublicFarmProfileScreen extends StatefulWidget {
  final String farmerId;
  final bool previewUnpublished;
  final String sourceWorkspace;
  final void Function(Product product)? onAddProduct;
  final BusinessAccount? wholesaleAccount;

  const PublicFarmProfileScreen({
    super.key,
    required this.farmerId,
    this.previewUnpublished = false,
    this.sourceWorkspace = 'customer',
    this.onAddProduct,
    this.wholesaleAccount,
  });

  @override
  State<PublicFarmProfileScreen> createState() =>
      _PublicFarmProfileScreenState();
}

class _PublicFarmProfileScreenState extends State<PublicFarmProfileScreen> {
  late Future<FarmPublicProfileBundle> _future;
  final ScrollController _scrollController = ScrollController();

  // Phase 053 — image-only catalogue cache used as a safe visual fallback
  // for Coming Soon. It does not alter farm ownership, availability, price,
  // checkout, supplier linking, or product navigation.
  List<Product> _hpjProduceImageCatalog = const <Product>[];

  @override
  void initState() {
    super.initState();
    _reload();
    _loadHpjProduceImageCatalog();
  }

  void _reload() {
    _future = fetchFarmPublicProfileBundle(
      widget.farmerId,
      includeUnpublished: widget.previewUnpublished,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadHpjProduceImageCatalog({
    bool forceRefresh = false,
  }) async {
    try {
      final products = await fetchProducts(
        forceRefresh: forceRefresh,
      );

      final usable = products.where((product) {
        return product.name.trim().isNotEmpty &&
            cleanHostedImageUrl(product.imageUrl) != null;
      }).toList(growable: false);

      if (!mounted) return;

      setState(() {
        _hpjProduceImageCatalog = usable;
      });
    } catch (error) {
      // Images are enhancement-only. A catalogue refresh must never block the
      // public Farm Profile or replace the existing neutral fallback.
      farmDebugLog(
        'Phase 053 HPJ produce image catalogue unavailable: $error',
      );
    }
  }

  Future<void> _refresh() async {
    setState(_reload);
    final imageRefresh = _loadHpjProduceImageCatalog(
      forceRefresh: true,
    );
    await _future;
    await imageRefresh;
  }

  void _openSupport(String subject) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SupportScreen(initialSubject: subject),
      ),
    );
  }

  void _shareFarm(FarmPublicProfileRecord profile) {
    final text = <String>[
      profile.publicName,
      if (profile.locationLine.trim().isNotEmpty) profile.locationLine.trim(),
      'Supplied through The Harvest Place Ja',
    ].join(' • ');

    Clipboard.setData(ClipboardData(text: text));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Farm profile details copied for sharing.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _scrollToProducts() {
    if (!_scrollController.hasClients) return;

    final target = (_scrollController.position.maxScrollExtent * 0.31)
        .clamp(0.0, _scrollController.position.maxScrollExtent)
        .toDouble();

    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  Widget _networkImage(
    String? url, {
    required double height,
    BoxFit fit = BoxFit.cover,
  }) {
    final clean = cleanHostedImageUrl(url);

    if (clean == null) {
      return Container(
        height: height,
        width: double.infinity,
        color: FarmColors.primarySoft,
        alignment: Alignment.center,
        child: const Icon(
          Icons.landscape_rounded,
          color: FarmColors.green,
          size: 54,
        ),
      );
    }

    return Image.network(
      clean,
      height: height,
      width: double.infinity,
      fit: fit,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, __, ___) => Container(
        height: height,
        width: double.infinity,
        color: FarmColors.primarySoft,
        alignment: Alignment.center,
        child: const Icon(
          Icons.landscape_rounded,
          color: FarmColors.green,
          size: 54,
        ),
      ),
    );
  }

  String _supplyDateLabel(DateTime? value) {
    if (value == null) return '';

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

    return '${months[value.month - 1]} ${value.day}, ${value.year}';
  }

  IconData _tagIcon(String label) {
    final value = label.trim().toLowerCase();

    if (value.contains('family')) return Icons.groups_2_outlined;
    if (value.contains('open') || value.contains('field')) {
      return Icons.wb_sunny_outlined;
    }
    if (value.contains('organic')) return Icons.eco_outlined;
    if (value.contains('verified')) return Icons.shield_outlined;
    if (value.contains('local')) return Icons.spa_outlined;

    return Icons.eco_outlined;
  }

  Widget _tag(String label, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F4EA),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: FarmColors.gold.withOpacity(.18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon ?? _tagIcon(label),
            size: 15,
            color: FarmColors.deepGreen,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: FarmColors.deepGreen,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  List<String> _profileTags(FarmPublicProfileRecord profile) {
    final values = <String>[];

    for (final item in <String>[
      ...profile.tags,
      ...profile.farmingPractices,
    ]) {
      final clean = item.trim();
      if (clean.isEmpty) continue;

      if (!values.any(
        (existing) => existing.toLowerCase() == clean.toLowerCase(),
      )) {
        values.add(clean);
      }

      if (values.length >= 3) break;
    }

    return values;
  }

  String _farmSummary(FarmPublicProfileRecord profile) {
    final bio = profile.publicBio.trim();
    if (bio.isNotEmpty) return bio;

    final familyFarm = <String>[
      ...profile.tags,
      ...profile.farmingPractices,
    ].any((item) => item.toLowerCase().contains('family'));

    return familyFarm
        ? 'Family-run farm supplying fresh Jamaican produce through HPJ.'
        : 'Jamaican farm supplying fresh produce through HPJ.';
  }

  void _showAboutFarm(FarmPublicProfileRecord profile) {
    final details = <String>[];

    for (final raw in <String>[
      ...profile.tags,
      ...profile.farmingPractices,
    ]) {
      final value = raw.trim();
      if (value.isEmpty) continue;
      if (!details.any(
        (existing) => existing.toLowerCase() == value.toLowerCase(),
      )) {
        details.add(value);
      }
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: FarmColors.line,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        profile.publicName.trim().isEmpty
                            ? 'About this farm'
                            : profile.publicName.trim(),
                        style: const TextStyle(
                          color: FarmColors.deepGreen,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (profile.hpjVerified)
                      const Icon(
                        Icons.verified_rounded,
                        color: FarmColors.gold,
                        size: 21,
                      ),
                  ],
                ),
                if (profile.locationLine.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        size: 16,
                        color: FarmColors.deepGreen,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          profile.locationLine.trim(),
                          style: const TextStyle(
                            color: FarmColors.mutedText,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                Text(
                  _farmSummary(profile),
                  style: const TextStyle(
                    color: FarmColors.ink,
                    fontSize: 13,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (details.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: details.map(_tag).toList(growable: false),
                  ),
                ],
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFCF5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: FarmColors.gold.withOpacity(.16),
                    ),
                  ),
                  child: const Text(
                    'Orders, payments, delivery, requests and support are handled through HPJ.',
                    style: TextStyle(
                      color: FarmColors.deepGreen,
                      fontSize: 10.8,
                      height: 1.4,
                      fontWeight: FontWeight.w700,
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

  Widget _profileHero(
    FarmPublicProfileRecord profile,
    List<Product> products,
    List<FarmPublicPhoto> photos,
  ) {
    String? cover = cleanHostedImageUrl(profile.coverImageUrl);

    if (cover == null && photos.isNotEmpty) {
      for (final photo in photos) {
        final candidate = cleanHostedImageUrl(photo.imageUrl);
        if (candidate != null) {
          cover = candidate;
          break;
        }
      }
    }

    if (cover == null) {
      for (final product in products) {
        final candidate = cleanHostedImageUrl(product.imageUrl);
        if (candidate != null) {
          cover = candidate;
          break;
        }
      }
    }

    final tags = _profileTags(profile);
    final farmName = profile.publicName.trim().isEmpty
        ? 'HPJ Partner Farm'
        : profile.publicName.trim();
    final logo = cleanHostedImageUrl(profile.logoImageUrl);

    return SizedBox(
      height: 404,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 198,
            child: GestureDetector(
              onTap: cover == null
                  ? null
                  : () => _openFarmPhotoViewer(
                        cover!,
                        caption: farmName,
                      ),
              child: _networkImage(
                cover,
                height: 198,
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            top: 158,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: FarmColors.line.withOpacity(.55),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 92,
                        height: 92,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: FarmColors.gold.withOpacity(.52),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(.05),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: logo == null
                              ? const ColoredBox(
                                  color: Color(0xFFF8F4EA),
                                  child: Icon(
                                    Icons.agriculture_rounded,
                                    color: FarmColors.deepGreen,
                                    size: 40,
                                  ),
                                )
                              : ColoredBox(
                                  color: Colors.white,
                                  child: Transform.scale(
                                    scale: 1.26,
                                    child: Image.network(
                                      logo,
                                      width: 92,
                                      height: 92,
                                      fit: BoxFit.cover,
                                      filterQuality: FilterQuality.high,
                                      errorBuilder: (_, __, ___) =>
                                          const ColoredBox(
                                        color: Color(0xFFF8F4EA),
                                        child: Icon(
                                          Icons.agriculture_rounded,
                                          color: FarmColors.deepGreen,
                                          size: 40,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                        ),
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
                                    farmName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: FarmColors.deepGreen,
                                      fontSize: 20.5,
                                      height: 1.05,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                if (profile.hpjVerified) ...[
                                  const SizedBox(width: 5),
                                  const Icon(
                                    Icons.verified_rounded,
                                    color: FarmColors.deepGreen,
                                    size: 19,
                                  ),
                                ],
                              ],
                            ),
                            if (profile.locationLine.trim().isNotEmpty) ...[
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_rounded,
                                    color: FarmColors.deepGreen,
                                    size: 15,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      profile.locationLine.trim(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: FarmColors.ink,
                                        fontSize: 11,
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
                      if (widget.previewUnpublished && !profile.isPublished)
                        Container(
                          margin: const EdgeInsets.only(left: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: FarmColors.warningSoft,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'DRAFT',
                            style: TextStyle(
                              color: FarmColors.warning,
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (tags.isNotEmpty)
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        for (final item in tags) _tag(item),
                      ],
                    ),
                  const SizedBox(height: 10),
                  Text(
                    _farmSummary(profile),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: FarmColors.ink,
                      fontSize: 12,
                      height: 1.38,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  InkWell(
                    onTap: () => _showAboutFarm(profile),
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'More about this farm',
                            style: TextStyle(
                              color: FarmColors.deepGreen,
                              fontSize: 11.2,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(width: 5),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: FarmColors.deepGreen,
                            size: 16,
                          ),
                        ],
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

  Widget _sectionHeader(
    String title, {
    String actionLabel = 'See all',
    VoidCallback? onAction,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: FarmColors.deepGreen,
              fontSize: 17.5,
              height: 1.1,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: FarmColors.deepGreen,
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  actionLabel,
                  style: const TextStyle(
                    fontSize: 10.8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_rounded, size: 15),
              ],
            ),
          ),
      ],
    );
  }

  void _openProduct(Product product) {
    final isWholesale =
        widget.sourceWorkspace.trim().toLowerCase() == 'wholesale' &&
            widget.wholesaleAccount != null;

    if (isWholesale) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => WholesaleSupplierRequestScreen(
            account: widget.wholesaleAccount!,
            farm: _currentProfile!,
            initialProduct: product,
          ),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProductDetailScreen(
          product: product,
          quantity: 0,
          onAdd: () => _addProduct(product),
          onRemove: () {},
          onAddProduct: widget.onAddProduct,
        ),
      ),
    );
  }

  FarmPublicProfileRecord? _currentProfile;

  void _addProduct(Product product) {
    if (widget.onAddProduct == null) {
      _openProduct(product);
      return;
    }

    widget.onAddProduct!.call(product);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} added to My Box.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _availableProductCard(Product product) {
    final unit = (product.unit ?? '').trim();
    final isWholesale =
        widget.sourceWorkspace.trim().toLowerCase() == 'wholesale';
    final canAdd =
        product.canAddToCart && widget.onAddProduct != null && !isWholesale;
    final priceLabel = unit.isEmpty
        ? product.formattedEffectivePrice
        : '${product.formattedEffectivePrice} / $unit';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: () => _openProduct(product),
        borderRadius: BorderRadius.circular(15),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 9),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: FarmColors.line.withOpacity(.82),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 76,
                width: double.infinity,
                child: productImagePreviewFromUrl(
                  imageUrl: product.imageUrl,
                  height: 76,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: FarmColors.deepGreen,
                  fontSize: 11.4,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                priceLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: FarmColors.ink,
                  fontSize: 10.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 34,
                child: ElevatedButton.icon(
                  onPressed: canAdd
                      ? () => _addProduct(product)
                      : () => _openProduct(product),
                  icon: Icon(
                    canAdd
                        ? Icons.add_rounded
                        : isWholesale
                            ? Icons.shopping_bag_outlined
                            : Icons.arrow_forward_rounded,
                    size: 16,
                  ),
                  label: Text(
                    canAdd
                        ? 'Add'
                        : isWholesale
                            ? 'Request'
                            : 'View',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FarmColors.deepGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 10.8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _availableProductWideCard(Product product) {
    final unit = (product.unit ?? '').trim();
    final isWholesale =
        widget.sourceWorkspace.trim().toLowerCase() == 'wholesale';
    final canAdd =
        product.canAddToCart && widget.onAddProduct != null && !isWholesale;
    final priceLabel = unit.isEmpty
        ? product.formattedEffectivePrice
        : '${product.formattedEffectivePrice} / $unit';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => _openProduct(product),
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: FarmColors.line.withOpacity(.82),
            ),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: SizedBox(
                  width: 104,
                  height: 104,
                  child: productImagePreviewFromUrl(
                    imageUrl: product.imageUrl,
                    height: 104,
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: FarmColors.deepGreen,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      priceLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: FarmColors.ink,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 11),
                    SizedBox(
                      height: 36,
                      child: ElevatedButton.icon(
                        onPressed: canAdd
                            ? () => _addProduct(product)
                            : () => _openProduct(product),
                        icon: Icon(
                          canAdd
                              ? Icons.add_rounded
                              : isWholesale
                                  ? Icons.shopping_bag_outlined
                                  : Icons.arrow_forward_rounded,
                          size: 17,
                        ),
                        label: Text(
                          canAdd
                              ? 'Add to My Box'
                              : isWholesale
                                  ? 'Request'
                                  : 'View product',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FarmColors.deepGreen,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
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
    );
  }

  void _showAllProducts(
    String title,
    List<Product> products,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(26),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: FractionallySizedBox(
            heightFactor: .78,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: FarmColors.line,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: FarmColors.deepGreen,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                    itemCount: products.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, index) {
                      final product = products[index];
                      final unit = (product.unit ?? '').trim();

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 4,
                        ),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            width: 52,
                            height: 52,
                            child: productImagePreviewFromUrl(
                              imageUrl: product.imageUrl,
                              height: 52,
                            ),
                          ),
                        ),
                        title: Text(
                          product.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        subtitle: Text(
                          product.isReadySoon
                              ? product.readySoonLabel
                              : '${product.formattedEffectivePrice}'
                                  '${unit.isEmpty ? '' : ' / $unit'}',
                        ),
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                        ),
                        onTap: () {
                          Navigator.of(context).pop();
                          _openProduct(product);
                        },
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
  }

  Widget _availableProductsSection(List<Product> products) {
    final visible = products.take(3).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          'Available through HPJ',
          actionLabel: 'See all (${products.length})',
          onAction: products.length > 3
              ? () => _showAllProducts(
                    'Available through HPJ',
                    products,
                  )
              : null,
        ),
        const SizedBox(height: 9),
        if (products.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFCF5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: FarmColors.line.withOpacity(.72),
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  color: FarmColors.deepGreen,
                  size: 20,
                ),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Nothing ready for immediate order today. '
                    'See Coming Soon for what this farm is preparing.',
                    style: TextStyle(
                      color: FarmColors.mutedText,
                      fontSize: 10,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          )
        else if (products.length == 1)
          _availableProductWideCard(products.first)
        else
          LayoutBuilder(
            builder: (context, constraints) {
              if (products.length == 2) {
                final twoCardWidth = (constraints.maxWidth - 8) / 2;

                if (twoCardWidth < 122) {
                  return SizedBox(
                    height: 196,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: 2,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, index) => SizedBox(
                        width: 132,
                        child: _availableProductCard(
                          visible[index],
                        ),
                      ),
                    ),
                  );
                }

                return SizedBox(
                  height: 196,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _availableProductCard(visible[0]),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _availableProductCard(visible[1]),
                      ),
                    ],
                  ),
                );
              }

              final cardWidth = (constraints.maxWidth - 16) / 3;

              if (cardWidth < 104) {
                return SizedBox(
                  height: 196,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: visible.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, index) => SizedBox(
                      width: 118,
                      child: _availableProductCard(
                        visible[index],
                      ),
                    ),
                  ),
                );
              }

              return SizedBox(
                height: 196,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < visible.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(
                        child: _availableProductCard(
                          visible[i],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Product? _linkedProductForSupply(
    PublicFarmSupplyItem item,
    List<Product> products,
  ) {
    final productId = item.linkedProductId?.trim();

    if (productId == null || productId.isEmpty) return null;

    for (final product in products) {
      if (product.id.trim() == productId) {
        return product;
      }
    }

    return null;
  }

  String _produceImageMatchKey(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('&', 'and')
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Product? _firstNamedProductWithImage(
    String cropName,
    Iterable<Product> products,
  ) {
    final cropKey = _produceImageMatchKey(cropName);
    if (cropKey.isEmpty) return null;

    for (final product in products) {
      if (_produceImageMatchKey(product.name) != cropKey) continue;
      if (cleanHostedImageUrl(product.imageUrl) == null) continue;
      return product;
    }

    return null;
  }

  Product? _comingSoonImageProductForSupply(
    PublicFarmSupplyItem item,
    List<Product> farmProducts,
  ) {
    // 1) Explicit Phase 045 supply → Product link remains the strongest source.
    final linked = _linkedProductForSupply(item, farmProducts);
    if (linked != null && cleanHostedImageUrl(linked.imageUrl) != null) {
      return linked;
    }

    // 2) Same-farm exact crop-name match. This is still the farmer's own HPJ
    // product data and does not change any marketplace relationship.
    final sameFarm = _firstNamedProductWithImage(
      item.cropName,
      farmProducts,
    );
    if (sameFarm != null) return sameFarm;

    // 3) Visual-only fallback to HPJ's existing produce catalogue. The image
    // is borrowed by exact normalized name only. The row still represents the
    // original Farmer Supply record and does NOT link to this fallback product.
    return _firstNamedProductWithImage(
      item.cropName,
      _hpjProduceImageCatalog,
    );
  }

  Product? _comingSoonImageProductForProduct(Product product) {
    if (cleanHostedImageUrl(product.imageUrl) != null) {
      return product;
    }

    return _firstNamedProductWithImage(
      product.name,
      _hpjProduceImageCatalog,
    );
  }

  void _openLinkedSupplyProduct({
    required PublicFarmSupplyItem item,
    required List<Product> products,
    required FarmPublicProfileRecord farm,
  }) {
    final product = _linkedProductForSupply(item, products);

    if (product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${item.cropName} is being supplied through HPJ, '
            'but its marketplace product is not linked yet.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final workspace = widget.sourceWorkspace.trim().toLowerCase();

    if (workspace == 'wholesale' && widget.wholesaleAccount != null) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => WholesaleSupplierRequestScreen(
            account: widget.wholesaleAccount!,
            farm: farm,
            initialProduct: product,
          ),
        ),
      );
      return;
    }

    _openProduct(product);
  }

  Widget _comingSoonProductCard(Product product) {
    final imageProduct = _comingSoonImageProductForProduct(product);
    final imageUrl = imageProduct?.imageUrl;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openProduct(product),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: cleanHostedImageUrl(imageUrl) == null
                      ? const ColoredBox(
                          color: Color(0xFFF8F4EA),
                          child: Icon(
                            Icons.eco_outlined,
                            color: FarmColors.deepGreen,
                            size: 22,
                          ),
                        )
                      : productImagePreviewFromUrl(
                          imageUrl: imageUrl,
                          height: 48,
                        ),
                ),
              ),
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
                        fontSize: 11.3,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      product.readySoonLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: FarmColors.mutedText,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: FarmColors.mutedText,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _comingSoonSupplyCard(
    PublicFarmSupplyItem item,
    List<Product> products,
    FarmPublicProfileRecord farm,
  ) {
    final date = _supplyDateLabel(item.expectedHarvestDate);
    final imageProduct = _comingSoonImageProductForSupply(
      item,
      products,
    );
    final imageUrl = imageProduct?.imageUrl;

    final leading = cleanHostedImageUrl(imageUrl) != null
        ? ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 48,
              height: 48,
              child: productImagePreviewFromUrl(
                imageUrl: imageUrl,
                height: 48,
              ),
            ),
          )
        : Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F4EA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.eco_outlined,
              color: FarmColors.deepGreen,
              size: 22,
            ),
          );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openLinkedSupplyProduct(
          item: item,
          products: products,
          farm: farm,
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.cropName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: FarmColors.ink,
                        fontSize: 11.3,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      date.isEmpty ? item.stageLabel : 'Expected $date',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: FarmColors.mutedText,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: FarmColors.mutedText,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAllComingSoon({
    required List<Product> readySoonProducts,
    required List<PublicFarmSupplyItem> supply,
    required List<Product> allProducts,
    required FarmPublicProfileRecord farm,
  }) {
    final rows = <Widget>[];
    final usedProductIds = <String>{
      ...readySoonProducts.map((item) => item.id.trim()),
    };

    for (final product in readySoonProducts) {
      rows.add(_comingSoonProductCard(product));
    }

    for (final item in supply) {
      if (item.isReadyNow) continue;

      final linked = _linkedProductForSupply(item, allProducts);
      if (linked != null && usedProductIds.contains(linked.id.trim())) {
        continue;
      }

      rows.add(
        _comingSoonSupplyCard(
          item,
          allProducts,
          farm,
        ),
      );
    }

    if (rows.isEmpty) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(26),
        ),
      ),
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: .78,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: FarmColors.line,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 12, 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Coming Soon',
                        style: TextStyle(
                          color: FarmColors.deepGreen,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                  itemCount: rows.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: FarmColors.line),
                  itemBuilder: (_, index) => rows[index],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _comingSoonSection({
    required List<Product> readySoonProducts,
    required List<PublicFarmSupplyItem> supply,
    required List<Product> allProducts,
    required FarmPublicProfileRecord farm,
  }) {
    final rows = <Widget>[];
    final usedProductIds = <String>{
      ...readySoonProducts.map((item) => item.id.trim()),
    };

    for (final product in readySoonProducts) {
      if (rows.length >= 3) break;
      rows.add(_comingSoonProductCard(product));
    }

    for (final item in supply) {
      if (rows.length >= 3) break;
      if (item.isReadyNow) continue;

      final linked = _linkedProductForSupply(item, allProducts);
      if (linked != null && usedProductIds.contains(linked.id.trim())) {
        continue;
      }

      rows.add(_comingSoonSupplyCard(item, allProducts, farm));
    }

    final totalUnique = readySoonProducts.length +
        supply.where((item) {
          if (item.isReadyNow) return false;
          final linked = _linkedProductForSupply(item, allProducts);
          return linked == null || !usedProductIds.contains(linked.id.trim());
        }).length;

    if (rows.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          'Coming Soon',
          onAction: totalUnique > rows.length
              ? () => _showAllComingSoon(
                    readySoonProducts: readySoonProducts,
                    supply: supply,
                    allProducts: allProducts,
                    farm: farm,
                  )
              : null,
        ),
        const SizedBox(height: 2),
        for (var i = 0; i < rows.length; i++) ...[
          rows[i],
          if (i < rows.length - 1)
            const Divider(height: 1, color: FarmColors.line),
        ],
      ],
    );
  }

  void _openFarmPhotoViewer(
    String imageUrl, {
    String caption = '',
  }) {
    final cleanUrl = cleanHostedImageUrl(imageUrl);
    if (cleanUrl == null) return;

    final cleanCaption = caption.trim();

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 0,
            title: Text(
              cleanCaption.isEmpty ? 'Farm photo' : cleanCaption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          body: SafeArea(
            top: false,
            child: Center(
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Image.network(
                  cleanUrl,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;

                    final expected = progress.expectedTotalBytes;
                    final value = expected == null || expected == 0
                        ? null
                        : progress.cumulativeBytesLoaded / expected;

                    return Center(
                      child: CircularProgressIndicator(
                        value: value,
                        color: Colors.white,
                      ),
                    );
                  },
                  errorBuilder: (_, __, ___) => const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.broken_image_outlined,
                          color: Colors.white70,
                          size: 46,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Photo unavailable',
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAllPhotos(List<FarmPublicPhoto> photos) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(26),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: FractionallySizedBox(
            heightFactor: .80,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: FarmColors.line,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Farm photos',
                          style: TextStyle(
                            color: FarmColors.deepGreen,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.35,
                    ),
                    itemCount: photos.length,
                    itemBuilder: (_, index) {
                      final photo = photos[index];

                      return GestureDetector(
                        onTap: () => _openFarmPhotoViewer(
                          photo.imageUrl,
                          caption: photo.caption,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            photo.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const ColoredBox(
                              color: FarmColors.primarySoft,
                              child: Center(
                                child: Icon(
                                  Icons.photo_outlined,
                                  color: FarmColors.green,
                                ),
                              ),
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
      },
    );
  }

  Widget _farmPhotos(List<FarmPublicPhoto> photos) {
    if (photos.isEmpty) return const SizedBox.shrink();

    final visible = photos.take(3).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          'Farm photos',
          onAction: photos.length > 3 ? () => _showAllPhotos(photos) : null,
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 92,
          child: Row(
            children: [
              for (var i = 0; i < visible.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openFarmPhotoViewer(
                      visible[i].imageUrl,
                      caption: visible[i].caption,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        visible[i].imageUrl,
                        width: double.infinity,
                        height: 92,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.medium,
                        errorBuilder: (_, __, ___) => const ColoredBox(
                          color: FarmColors.primarySoft,
                          child: Center(
                            child: Icon(
                              Icons.photo_outlined,
                              color: FarmColors.green,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _trustReason({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 9, 6, 9),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: FarmColors.gold.withOpacity(.13),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Icon(icon, color: FarmColors.deepGreen, size: 21),
          const SizedBox(height: 6),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: FarmColors.deepGreen,
              fontSize: 9.6,
              height: 1.1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: FarmColors.mutedText,
              fontSize: 8,
              height: 1.18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _whyOrderThroughHpj() {
    final items = <Widget>[
      _trustReason(
        icon: Icons.shopping_cart_outlined,
        title: 'One checkout',
        subtitle: 'Buy from many farms',
      ),
      _trustReason(
        icon: Icons.lock_outline_rounded,
        title: 'Secure payment',
        subtitle: 'Handled by HPJ',
      ),
      _trustReason(
        icon: Icons.local_shipping_outlined,
        title: 'HPJ delivery',
        subtitle: 'Reliable island-wide',
      ),
      _trustReason(
        icon: Icons.chat_bubble_outline_rounded,
        title: 'Support',
        subtitle: 'Help when you need it',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Why order through HPJ?',
          style: TextStyle(
            color: FarmColors.deepGreen,
            fontSize: 17.5,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 330) {
              final width = (constraints.maxWidth - 8) / 2;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: items
                    .map((item) => SizedBox(width: width, child: item))
                    .toList(growable: false),
              );
            }

            return SizedBox(
              height: 112,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    if (i > 0) const SizedBox(width: 6),
                    Expanded(child: items[i]),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _primaryActions(FarmPublicProfileRecord profile) {
    final wholesale =
        widget.sourceWorkspace.trim().toLowerCase() == 'wholesale' &&
            widget.wholesaleAccount != null;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 46,
          child: OutlinedButton.icon(
            onPressed: wholesale
                ? () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => WholesaleSupplierRequestScreen(
                          account: widget.wholesaleAccount!,
                          farm: profile,
                        ),
                      ),
                    );
                  }
                : () => _openSupport(
                      'Produce request — ${profile.publicName}',
                    ),
            icon: const Icon(Icons.eco_outlined, size: 18),
            label: Text(
              wholesale ? 'Request Wholesale Supply' : 'Request Produce',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: FarmColors.deepGreen,
              side: const BorderSide(
                color: FarmColors.deepGreen,
                width: 1.2,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        TextButton(
          onPressed: () => _openSupport(
            'Farm enquiry — ${profile.publicName}',
          ),
          style: TextButton.styleFrom(
            foregroundColor: FarmColors.deepGreen,
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.chat_bubble_outline_rounded, size: 17),
              SizedBox(width: 6),
              Text(
                'Ask HPJ about this farmer',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(width: 5),
              Icon(Icons.arrow_forward_rounded, size: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _hpjTrustNotice() {
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: FarmColors.gold.withOpacity(.18),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: FarmColors.gold,
            size: 22,
          ),
          SizedBox(width: 9),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Ordering through HPJ\n',
                    style: TextStyle(
                      color: FarmColors.deepGreen,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  TextSpan(
                    text:
                        'Payments, requests, delivery and support are handled by HPJ.',
                    style: TextStyle(
                      color: FarmColors.ink,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              style: TextStyle(fontSize: 10.2, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stickyShopBar(FarmPublicProfileRecord profile) {
    final wholesale =
        widget.sourceWorkspace.trim().toLowerCase() == 'wholesale' &&
            widget.wholesaleAccount != null;
    final farmName = profile.publicName.trim().isEmpty
        ? 'this Farm'
        : profile.publicName.trim();

    return Material(
      color: FarmColors.deepGreen,
      elevation: 10,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 9, 16, 9),
          child: SizedBox(
            height: 46,
            child: ElevatedButton.icon(
              onPressed: _scrollToProducts,
              icon: Icon(
                wholesale
                    ? Icons.shopping_bag_outlined
                    : Icons.shopping_cart_outlined,
                size: 20,
              ),
              label: Text(
                wholesale ? 'View $farmName Supply' : 'Shop $farmName',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: FarmColors.deepGreen,
                foregroundColor: Colors.white,
                elevation: 0,
                side: BorderSide(
                  color: Colors.white.withOpacity(.18),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _notAvailable() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Farm Profile'),
      ),
      body: FarmPage(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 28, 18, 120),
          children: const [
            FarmEmptyState(
              icon: Icons.agriculture_outlined,
              title: 'Farm profile coming soon',
              message: 'HPJ is preparing this farmer’s public page. '
                  'Private farmer contact details are never shown here.',
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FarmPublicProfileBundle>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            snapshot.data == null) {
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: FarmColors.deepGreen,
              foregroundColor: Colors.white,
              iconTheme: const IconThemeData(color: Colors.white),
              actionsIconTheme: const IconThemeData(color: Colors.white),
              elevation: 0,
              centerTitle: true,
              leading: IconButton(
                tooltip: 'Back',
                color: Colors.white,
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              title: const Text(
                'Farm Profile',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final data = snapshot.data;
        final profile = data?.profile;

        if (data == null || profile == null) {
          return _notAvailable();
        }

        _currentProfile = profile;

        final isWholesaleContext =
            widget.sourceWorkspace.trim().toLowerCase() == 'wholesale' &&
                widget.wholesaleAccount != null;

        final available = data.products
            .where(
              (product) => isWholesaleContext
                  ? !product.isReadySoon
                  : product.canAddToCart,
            )
            .toList();

        final comingSoon = data.products
            .where(
              (product) =>
                  product.isReadySoon ||
                  (!isWholesaleContext &&
                      product.isCustomerVisible &&
                      !product.canAddToCart),
            )
            .toList();

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: FarmColors.deepGreen,
            foregroundColor: Colors.white,
            surfaceTintColor: FarmColors.deepGreen,
            iconTheme: const IconThemeData(color: Colors.white),
            actionsIconTheme: const IconThemeData(color: Colors.white),
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              tooltip: 'Back',
              color: Colors.white,
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
              ),
            ),
            title: const Text(
              'Farm Profile',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            actions: [
              IconButton(
                tooltip: 'Share farm',
                color: Colors.white,
                onPressed: () => _shareFarm(profile),
                icon: const Icon(
                  Icons.ios_share_outlined,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          bottomNavigationBar: _stickyShopBar(profile),
          body: SafeArea(
            top: false,
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                children: [
                  _profileHero(
                    profile,
                    data.products,
                    data.photos,
                  ),
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(
                      18,
                      0,
                      18,
                      32,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _availableProductsSection(available),
                        const SizedBox(height: 18),
                        _comingSoonSection(
                          readySoonProducts: comingSoon,
                          supply: data.growingSupply,
                          allProducts: data.products,
                          farm: profile,
                        ),
                        if (comingSoon.isNotEmpty ||
                            data.growingSupply.any(
                              (item) => !item.isReadyNow,
                            ))
                          const SizedBox(height: 18),
                        if (data.photos.isNotEmpty) ...[
                          _farmPhotos(data.photos),
                          const SizedBox(height: 18),
                        ],
                        _whyOrderThroughHpj(),
                        const SizedBox(height: 18),
                        _primaryActions(profile),
                        const SizedBox(height: 10),
                        _hpjTrustNotice(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// =====================================================
// HPJ PHASE 041 — FARMER PUBLIC PAGE EDITOR
// =====================================================

class FarmerPublicProfileEditorScreen extends StatefulWidget {
  final FarmerProfile farmer;

  const FarmerPublicProfileEditorScreen({
    super.key,
    required this.farmer,
  });

  @override
  State<FarmerPublicProfileEditorScreen> createState() =>
      _FarmerPublicProfileEditorScreenState();
}

class _FarmerPublicProfileEditorScreenState
    extends State<FarmerPublicProfileEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _publicNameController = TextEditingController();
  final _communityController = TextEditingController();
  final _bioController = TextEditingController();
  final _tagsController = TextEditingController();
  final _practicesController = TextEditingController();

  bool loading = true;
  bool saving = false;
  bool uploadingCover = false;
  bool uploadingLogo = false;
  bool uploadingGallery = false;

  FarmPublicProfileRecord? profile;
  String? coverImageUrl;
  String? logoImageUrl;
  List<FarmPublicPhoto> photos = const <FarmPublicPhoto>[];

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _publicNameController.dispose();
    _communityController.dispose();
    _bioController.dispose();
    _tagsController.dispose();
    _practicesController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final values = await Future.wait<dynamic>([
        fetchFarmPublicProfile(
          widget.farmer.id,
          includeUnpublished: true,
        ),
        fetchFarmPublicPhotos(
          widget.farmer.id,
          includeInactive: true,
        ),
      ]);

      final record = values[0] as FarmPublicProfileRecord?;
      final gallery = values[1] as List<FarmPublicPhoto>;

      if (!mounted) return;

      final fallbackName = widget.farmer.farmName.trim().isEmpty
          ? widget.farmer.farmerName
          : widget.farmer.farmName;

      _publicNameController.text = record?.publicName ?? fallbackName;
      _communityController.text = record?.community ?? '';
      _bioController.text = record?.publicBio ?? '';
      _tagsController.text = (record?.tags ?? const <String>[]).join(', ');
      _practicesController.text =
          (record?.farmingPractices ?? const <String>[]).join(', ');

      setState(() {
        profile = record;
        coverImageUrl = record?.coverImageUrl;
        logoImageUrl = record?.logoImageUrl;
        photos = gallery;
        loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyAppError(error))),
      );
    }
  }

  List<String> _csv(TextEditingController controller) {
    return controller.text
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  Future<String?> _pickAndUpload(String slot) async {
    final picked = await pickProductImageFromDevice();
    if (picked == null) return null;

    return farmerUploadOwnPublicFarmImage(
      farmerId: widget.farmer.id,
      slot: slot,
      image: picked,
    );
  }

  Future<void> _uploadCover() async {
    if (uploadingCover) return;
    setState(() => uploadingCover = true);
    try {
      final url = await _pickAndUpload('cover');
      if (url == null || !mounted) return;
      setState(() => coverImageUrl = url);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyAppError(error))),
        );
      }
    } finally {
      if (mounted) setState(() => uploadingCover = false);
    }
  }

  Future<void> _uploadLogo() async {
    if (uploadingLogo) return;
    setState(() => uploadingLogo = true);
    try {
      final url = await _pickAndUpload('logo');
      if (url == null || !mounted) return;
      setState(() => logoImageUrl = url);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyAppError(error))),
        );
      }
    } finally {
      if (mounted) setState(() => uploadingLogo = false);
    }
  }

  Future<void> _addGalleryPhoto() async {
    if (uploadingGallery) return;

    if (photos.length >= 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Six farm photos are enough for the MVP page. Remove one before adding another.',
          ),
        ),
      );
      return;
    }

    setState(() => uploadingGallery = true);

    try {
      final url = await _pickAndUpload('gallery');
      if (url == null) return;

      await farmerAddOwnPublicFarmPhoto(imageUrl: url);

      final latest = await fetchFarmPublicPhotos(
        widget.farmer.id,
        includeInactive: true,
      );

      if (mounted) setState(() => photos = latest);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyAppError(error))),
        );
      }
    } finally {
      if (mounted) setState(() => uploadingGallery = false);
    }
  }

  Future<void> _deletePhoto(FarmPublicPhoto photo) async {
    try {
      await farmerDeleteOwnPublicFarmPhoto(photo.id);
      if (!mounted) return;
      setState(() {
        photos = photos.where((item) => item.id != photo.id).toList();
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyAppError(error))),
        );
      }
    }
  }

  Future<bool> _save({bool showMessage = true}) async {
    if (!_formKey.currentState!.validate() || saving) return false;

    setState(() => saving = true);

    try {
      await farmerSaveOwnPublicFarmProfile(
        publicName: _publicNameController.text,
        community: _communityController.text,
        publicBio: _bioController.text,
        tags: _csv(_tagsController),
        farmingPractices: _csv(_practicesController),
        coverImageUrl: coverImageUrl,
        logoImageUrl: logoImageUrl,
      );

      final latest = await fetchFarmPublicProfile(
        widget.farmer.id,
        includeUnpublished: true,
      );

      if (!mounted) return true;

      setState(() => profile = latest);

      if (showMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              latest?.isPublished == true
                  ? 'Farm page updated.'
                  : 'Farm page saved. HPJ controls when the public page goes live.',
            ),
          ),
        );
      }

      return true;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyAppError(error))),
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _preview() async {
    final saved = await _save(showMessage: false);
    if (!saved || !mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PublicFarmProfileScreen(
          farmerId: widget.farmer.id,
          previewUnpublished: true,
          sourceWorkspace: 'farmer',
        ),
      ),
    );
  }

  Widget _photoButton({
    required String label,
    required IconData icon,
    required bool busy,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: busy ? null : onPressed,
      icon: busy
          ? const SizedBox(
              width: 15,
              height: 15,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon, size: 18),
      label: Text(busy ? 'Uploading...' : label),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        backgroundColor: FarmColors.background,
        appBar: AppBar(title: const Text('Edit Farm Page')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final isLive = profile?.isPublished == true;
    final isVerified = profile?.hpjVerified == true;
    final cover = cleanHostedImageUrl(coverImageUrl);
    final logo = cleanHostedImageUrl(logoImageUrl);

    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: AppBar(
        title: const Text('Edit Farm Page'),
        actions: [
          IconButton(
            tooltip: 'Preview',
            onPressed: saving ? null : _preview,
            icon: const Icon(Icons.visibility_outlined),
          ),
        ],
      ),
      body: FarmPage(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
            children: [
              FarmCard(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 170,
                      width: double.infinity,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (cover != null)
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(24),
                              ),
                              child: Image.network(
                                cover,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: FarmColors.primarySoft,
                                ),
                              ),
                            )
                          else
                            Container(
                              decoration: const BoxDecoration(
                                color: FarmColors.primarySoft,
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(24),
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.landscape_outlined,
                                  color: FarmColors.primary,
                                  size: 44,
                                ),
                              ),
                            ),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(24),
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(.48),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            left: 14,
                            right: 14,
                            bottom: 12,
                            child: Row(
                              children: [
                                Container(
                                  width: 54,
                                  height: 54,
                                  clipBehavior: Clip.antiAlias,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: logo != null
                                      ? Image.network(
                                          logo,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(
                                            Icons.agriculture_rounded,
                                            color: FarmColors.primary,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.agriculture_rounded,
                                          color: FarmColors.primary,
                                        ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _publicNameController.text.trim().isEmpty
                                        ? 'My Farm'
                                        : _publicNameController.text.trim(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                if (isVerified)
                                  const Icon(
                                    Icons.verified_rounded,
                                    color: FarmColors.gold,
                                    size: 22,
                                  ),
                              ],
                            ),
                          ),
                        ],
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: isLive
                                      ? FarmColors.success.withOpacity(.10)
                                      : FarmColors.warning.withOpacity(.10),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: Text(
                                  isLive ? 'LIVE' : 'DRAFT',
                                  style: TextStyle(
                                    color: isLive
                                        ? FarmColors.success
                                        : FarmColors.warning,
                                    fontSize: 9.4,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  isLive
                                      ? 'Customers and businesses can see this page.'
                                      : 'Build your page. HPJ controls publishing and verification.',
                                  style: const TextStyle(
                                    color: FarmColors.mutedText,
                                    fontSize: 10.4,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 13),
                          Row(
                            children: [
                              Expanded(
                                child: _photoButton(
                                  label: cover == null
                                      ? 'Add Cover'
                                      : 'Change Cover',
                                  icon: Icons.add_photo_alternate_outlined,
                                  busy: uploadingCover,
                                  onPressed: _uploadCover,
                                ),
                              ),
                              const SizedBox(width: 9),
                              Expanded(
                                child: _photoButton(
                                  label: logo == null
                                      ? 'Add Profile'
                                      : 'Change Profile',
                                  icon: Icons.account_circle_outlined,
                                  busy: uploadingLogo,
                                  onPressed: _uploadLogo,
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
              const SizedBox(height: 14),
              FarmCard(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Farm story',
                      style: TextStyle(
                        color: FarmColors.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Keep it simple — customers mainly need to know who you are, where you farm and what makes your farm special.',
                      style: TextStyle(
                        color: FarmColors.mutedText,
                        fontSize: 10.5,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 13),
                    TextFormField(
                      controller: _publicNameController,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Farm name',
                        prefixIcon: Icon(Icons.agriculture_outlined),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Enter your farm name.'
                              : null,
                    ),
                    const SizedBox(height: 11),
                    TextFormField(
                      controller: _communityController,
                      decoration: InputDecoration(
                        labelText: 'Community',
                        hintText: 'Example: Mountainside',
                        helperText: 'Parish: ${widget.farmer.parish}',
                        prefixIcon: const Icon(Icons.location_on_outlined),
                      ),
                    ),
                    const SizedBox(height: 11),
                    TextFormField(
                      controller: _bioController,
                      minLines: 3,
                      maxLines: 5,
                      maxLength: 350,
                      decoration: const InputDecoration(
                        labelText: 'About your farm',
                        hintText:
                            'Example: Family farm growing fresh Jamaican produce for over 15 years.',
                        alignLabelWithHint: true,
                        prefixIcon: Icon(Icons.eco_outlined),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              FarmCard(
                padding: const EdgeInsets.all(15),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: FarmColors.primarySoft,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.shopping_basket_outlined,
                        color: FarmColors.primary,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Produce',
                            style: TextStyle(
                              color: FarmColors.ink,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            'Your public page uses My Supply automatically. Update what you are growing once — HPJ reuses it here.',
                            style: TextStyle(
                              color: FarmColors.mutedText,
                              fontSize: 10.4,
                              height: 1.35,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => FarmerSupplyScreen(
                                    profile: widget.farmer,
                                    refreshKey: 0,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.grass_rounded,
                              size: 17,
                            ),
                            label: const Text('Manage My Supply'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              FarmCard(
                padding: const EdgeInsets.all(15),
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
                                'Farm photos',
                                style: TextStyle(
                                  color: FarmColors.ink,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Add up to 6 real photos of your farm, produce or harvesting.',
                                style: TextStyle(
                                  color: FarmColors.mutedText,
                                  fontSize: 10.2,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _photoButton(
                          label: 'Add Photo',
                          icon: Icons.add_photo_alternate_outlined,
                          busy: uploadingGallery,
                          onPressed: _addGalleryPhoto,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (photos.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 20,
                        ),
                        decoration: BoxDecoration(
                          color: FarmColors.primarySoft,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Column(
                          children: [
                            Icon(
                              Icons.photo_library_outlined,
                              color: FarmColors.primary,
                              size: 28,
                            ),
                            SizedBox(height: 7),
                            Text(
                              'No farm photos yet',
                              style: TextStyle(
                                color: FarmColors.ink,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      SizedBox(
                        height: 112,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: photos.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 9),
                          itemBuilder: (context, index) {
                            final photo = photos[index];
                            return Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: SizedBox(
                                    width: 146,
                                    height: 108,
                                    child: Image.network(
                                      photo.imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: FarmColors.primarySoft,
                                        child: const Icon(
                                          Icons.broken_image_outlined,
                                          color: FarmColors.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 5,
                                  right: 5,
                                  child: Material(
                                    color: Colors.black.withOpacity(.62),
                                    shape: const CircleBorder(),
                                    child: InkWell(
                                      customBorder: const CircleBorder(),
                                      onTap: () => _deletePhoto(photo),
                                      child: const Padding(
                                        padding: EdgeInsets.all(6),
                                        child: Icon(
                                          Icons.close_rounded,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              FarmCard(
                padding: const EdgeInsets.all(15),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: EdgeInsets.zero,
                  title: const Text(
                    'Optional farm details',
                    style: TextStyle(
                      color: FarmColors.ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  subtitle: const Text(
                    'Tags and farming practices',
                    style: TextStyle(
                      color: FarmColors.mutedText,
                      fontSize: 10.2,
                    ),
                  ),
                  children: [
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _tagsController,
                      decoration: const InputDecoration(
                        labelText: 'Farm tags',
                        hintText: 'Local, Family Farm',
                        helperText: 'Separate tags with commas.',
                      ),
                    ),
                    const SizedBox(height: 11),
                    TextFormField(
                      controller: _practicesController,
                      decoration: const InputDecoration(
                        labelText: 'Farming practices',
                        hintText: 'Open Field, Greenhouse',
                        helperText: 'Only add practices that accurately apply.',
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              PrimaryFarmButton(
                label: saving ? 'Saving...' : 'Save Farm Page',
                icon: Icons.save_outlined,
                onPressed: saving ? null : () => _save(),
              ),
              const SizedBox(height: 9),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: saving ? null : _preview,
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Preview as Customer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FarmPublicProfileAdminScreen extends StatefulWidget {
  final FarmerProfile farmer;

  const FarmPublicProfileAdminScreen({
    super.key,
    required this.farmer,
  });

  @override
  State<FarmPublicProfileAdminScreen> createState() =>
      _FarmPublicProfileAdminScreenState();
}

class _FarmPublicProfileAdminScreenState
    extends State<FarmPublicProfileAdminScreen> {
  final _formKey = GlobalKey<FormState>();
  final _publicNameController = TextEditingController();
  final _communityController = TextEditingController();
  final _bioController = TextEditingController();
  final _tagsController = TextEditingController();
  final _practicesController = TextEditingController();

  bool loading = true;
  bool saving = false;
  bool uploadingCover = false;
  bool uploadingLogo = false;
  bool uploadingGallery = false;
  bool isPublished = false;
  bool hpjVerified = false;
  String? coverImageUrl;
  String? logoImageUrl;
  List<FarmPublicPhoto> photos = const <FarmPublicPhoto>[];

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _publicNameController.dispose();
    _communityController.dispose();
    _bioController.dispose();
    _tagsController.dispose();
    _practicesController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final record = await fetchFarmPublicProfile(
      widget.farmer.id,
      includeUnpublished: true,
    );
    final gallery = await fetchFarmPublicPhotos(
      widget.farmer.id,
      includeInactive: true,
    );

    if (!mounted) return;

    final defaultName = widget.farmer.farmName.trim().isEmpty
        ? widget.farmer.farmerName
        : widget.farmer.farmName;

    _publicNameController.text = record?.publicName ?? defaultName;
    _communityController.text = record?.community ?? '';
    _bioController.text = record?.publicBio ?? widget.farmer.bio;
    _tagsController.text = (record?.tags ?? const <String>[]).join(', ');
    _practicesController.text =
        (record?.farmingPractices ?? const <String>[]).join(', ');

    setState(() {
      coverImageUrl = record?.coverImageUrl;
      logoImageUrl = record?.logoImageUrl;
      isPublished = record?.isPublished ?? false;
      hpjVerified = record?.hpjVerified ?? widget.farmer.isApproved;
      photos = gallery;
      loading = false;
    });
  }

  List<String> _csv(TextEditingController controller) {
    return controller.text
        .split(',')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  Future<String?> _pickAndUpload(String slot) async {
    final picked = await pickProductImageFromDevice();
    if (picked == null) return null;

    return adminUploadFarmPublicImage(
      farmerId: widget.farmer.id,
      slot: slot,
      image: picked,
    );
  }

  Future<void> _uploadCover() async {
    setState(() => uploadingCover = true);
    try {
      final url = await _pickAndUpload('cover');
      if (url != null && mounted) setState(() => coverImageUrl = url);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyAppError(error))),
        );
      }
    } finally {
      if (mounted) setState(() => uploadingCover = false);
    }
  }

  Future<void> _uploadLogo() async {
    setState(() => uploadingLogo = true);
    try {
      final url = await _pickAndUpload('logo');
      if (url != null && mounted) setState(() => logoImageUrl = url);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyAppError(error))),
        );
      }
    } finally {
      if (mounted) setState(() => uploadingLogo = false);
    }
  }

  Future<void> _uploadGalleryPhoto() async {
    setState(() => uploadingGallery = true);
    try {
      final url = await _pickAndUpload('gallery');
      if (url == null) return;

      await adminAddFarmPublicPhoto(
        farmerId: widget.farmer.id,
        imageUrl: url,
      );

      final latest = await fetchFarmPublicPhotos(
        widget.farmer.id,
        includeInactive: true,
      );

      if (mounted) setState(() => photos = latest);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyAppError(error))),
        );
      }
    } finally {
      if (mounted) setState(() => uploadingGallery = false);
    }
  }

  Future<void> _deletePhoto(FarmPublicPhoto photo) async {
    try {
      await adminDeleteFarmPublicPhoto(photo.id);
      if (!mounted) return;
      setState(() {
        photos = photos.where((item) => item.id != photo.id).toList();
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyAppError(error))),
        );
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || saving) return;

    setState(() => saving = true);
    try {
      await adminSaveFarmPublicProfile(
        farmer: widget.farmer,
        publicName: _publicNameController.text,
        community: _communityController.text,
        publicBio: _bioController.text,
        tags: _csv(_tagsController),
        farmingPractices: _csv(_practicesController),
        isPublished: isPublished,
        hpjVerified: hpjVerified,
        coverImageUrl: coverImageUrl,
        logoImageUrl: logoImageUrl,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isPublished
                ? 'Public farm page saved and published.'
                : 'Farm page saved as a draft.',
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyAppError(error))),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _preview() async {
    await _save();
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PublicFarmProfileScreen(
          farmerId: widget.farmer.id,
          previewUnpublished: true,
        ),
      ),
    );
  }

  Widget _imageEditor({
    required String title,
    required String subtitle,
    required String? imageUrl,
    required bool busy,
    required VoidCallback onUpload,
    required double height,
  }) {
    return FarmCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: FarmColors.deepGreen,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: FarmColors.mutedText,
              fontSize: 11.5,
              height: 1.3,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 11),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              height: height,
              width: double.infinity,
              child: cleanHostedImageUrl(imageUrl) == null
                  ? const ColoredBox(
                      color: FarmColors.primarySoft,
                      child: Center(
                        child: Icon(
                          Icons.photo_outlined,
                          color: FarmColors.green,
                          size: 38,
                        ),
                      ),
                    )
                  : Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const ColoredBox(
                        color: FarmColors.primarySoft,
                        child: Center(
                          child: Icon(
                            Icons.photo_outlined,
                            color: FarmColors.green,
                            size: 38,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: busy ? null : onUpload,
              icon: busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_rounded),
              label: Text(busy ? 'Uploading...' : 'Upload / Replace'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        backgroundColor: FarmColors.background,
        appBar: AppBar(title: const Text('Public Farm Page')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: AppBar(
        title: const Text('Public Farm Page'),
        actions: [
          IconButton(
            tooltip: 'Preview',
            onPressed: saving ? null : _preview,
            icon: const Icon(Icons.visibility_outlined),
          ),
        ],
      ),
      body: FarmPage(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 130),
            children: [
              FarmCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Marketplace-safe farm identity',
                      style: TextStyle(
                        color: FarmColors.deepGreen,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Customers can see the farm story, parish/community, photos and HPJ products. Phone, email, exact address and payout details remain private. Use privacy-safe photos without contact details or precise location information.',
                      style: TextStyle(
                        color: FarmColors.mutedText,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _publicNameController,
                      decoration: const InputDecoration(
                        labelText: 'Public farm name',
                        prefixIcon: Icon(Icons.agriculture_outlined),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Enter the public farm name.'
                              : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _communityController,
                      decoration: InputDecoration(
                        labelText: 'Community (optional)',
                        helperText:
                            'Example: Mountainside. Parish remains ${widget.farmer.parish}.',
                        prefixIcon: const Icon(Icons.location_on_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _bioController,
                      minLines: 3,
                      maxLines: 6,
                      maxLength: 500,
                      decoration: const InputDecoration(
                        labelText: 'About this farm',
                        alignLabelWithHint: true,
                        prefixIcon: Icon(Icons.eco_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _tagsController,
                      decoration: const InputDecoration(
                        labelText: 'Public tags',
                        helperText:
                            'Comma separated: Local, Family Farm, Small Farm',
                        prefixIcon: Icon(Icons.sell_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _practicesController,
                      decoration: const InputDecoration(
                        labelText: 'Farming practices',
                        helperText: 'Comma separated: Open Field, Greenhouse',
                        prefixIcon: Icon(Icons.grass_rounded),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _imageEditor(
                title: 'Cover image',
                subtitle: 'A real, wide farm photo works best.',
                imageUrl: coverImageUrl,
                busy: uploadingCover,
                onUpload: _uploadCover,
                height: 180,
              ),
              const SizedBox(height: 14),
              _imageEditor(
                title: 'Farm logo / profile image',
                subtitle: 'Use the farm logo or a clear farm identity image.',
                imageUrl: logoImageUrl,
                busy: uploadingLogo,
                onUpload: _uploadLogo,
                height: 130,
              ),
              const SizedBox(height: 14),
              FarmCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Farm photos',
                            style: TextStyle(
                              color: FarmColors.deepGreen,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed:
                              uploadingGallery ? null : _uploadGalleryPhoto,
                          icon: uploadingGallery
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.add_photo_alternate_outlined),
                          label: const Text('Add'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (photos.isEmpty)
                      const Text(
                        'No gallery photos yet.',
                        style: TextStyle(color: FarmColors.mutedText),
                      )
                    else
                      SizedBox(
                        height: 118,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: photos.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 9),
                          itemBuilder: (context, index) {
                            final photo = photos[index];
                            return Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: SizedBox(
                                    width: 154,
                                    height: 112,
                                    child: Image.network(
                                      photo.imageUrl,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 5,
                                  right: 5,
                                  child: Material(
                                    color: Colors.black.withOpacity(0.62),
                                    shape: const CircleBorder(),
                                    child: InkWell(
                                      customBorder: const CircleBorder(),
                                      onTap: () => _deletePhoto(photo),
                                      child: const Padding(
                                        padding: EdgeInsets.all(6),
                                        child: Icon(
                                          Icons.delete_outline_rounded,
                                          size: 17,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              FarmCard(
                padding: const EdgeInsets.all(15),
                child: Column(
                  children: [
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: hpjVerified,
                      onChanged: widget.farmer.isApproved
                          ? (value) => setState(() => hpjVerified = value)
                          : null,
                      title: const Text(
                        'HPJ Verified badge',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      subtitle: const Text(
                        'Only use this after HPJ has verified the farmer.',
                      ),
                    ),
                    const Divider(height: 1),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: isPublished,
                      onChanged: widget.farmer.isApproved
                          ? (value) => setState(() => isPublished = value)
                          : null,
                      title: const Text(
                        'Publish public farm page',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      subtitle: Text(
                        widget.farmer.isApproved
                            ? 'When on, customers can open this page from HPJ products.'
                            : 'Approve the farmer before publishing the page.',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              PrimaryFarmButton(
                label: saving ? 'Saving Farm Page...' : 'Save Farm Page',
                icon: Icons.save_outlined,
                onPressed: saving ? null : _save,
              ),
              const SizedBox(height: 9),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: saving ? null : _preview,
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Preview Public Page'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
