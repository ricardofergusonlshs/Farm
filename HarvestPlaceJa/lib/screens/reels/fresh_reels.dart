part of harvest_place_app;

const String _freshReelsBucket = 'fresh-reels';
const int _freshReelMaxBytes = 30 * 1024 * 1024;

const String freshReelPlacementViewer = 'reels_viewer';
const String freshReelPlacementCustomerFeed = 'customer_feed';
const String freshReelPlacementFarmerFeed = 'farmer_feed';
const String freshReelPlacementWholesaleFeed = 'wholesale_feed';
const String freshReelPlacementShop = 'shop';
const String freshReelPlacementFreshBox = 'fresh_box';
const String freshReelPlacementMealPlanner = 'meal_planner';

const List<String> _freshReelPlacementOrder = <String>[
  freshReelPlacementViewer,
  freshReelPlacementCustomerFeed,
  freshReelPlacementShop,
  freshReelPlacementFreshBox,
  freshReelPlacementMealPlanner,
  freshReelPlacementFarmerFeed,
  freshReelPlacementWholesaleFeed,
];

String freshReelPlacementLabel(String placement) {
  switch (placement) {
    case freshReelPlacementViewer:
      return 'Fresh Reels Viewer';
    case freshReelPlacementCustomerFeed:
      return 'Customer Home Feed';
    case freshReelPlacementFarmerFeed:
      return 'Farmer Feed';
    case freshReelPlacementWholesaleFeed:
      return 'Wholesale Feed';
    case freshReelPlacementShop:
      return 'Customer Shop';
    case freshReelPlacementFreshBox:
      return 'Fresh Box';
    case freshReelPlacementMealPlanner:
      return 'Meal Planner';
    default:
      return placement;
  }
}

String freshReelPlacementDescription(String placement) {
  switch (placement) {
    case freshReelPlacementViewer:
      return 'Show in the full vertical swipe viewer.';
    case freshReelPlacementCustomerFeed:
      return 'Insert naturally in the customer Home feed.';
    case freshReelPlacementFarmerFeed:
      return 'Show in the farmer For You feed.';
    case freshReelPlacementWholesaleFeed:
      return 'Show in the wholesale For You feed.';
    case freshReelPlacementShop:
      return 'Show near the top of the customer Shop.';
    case freshReelPlacementFreshBox:
      return 'Show inside the Fresh Box builder.';
    case freshReelPlacementMealPlanner:
      return 'Show inside What’s Cooking This Week.';
    default:
      return '';
  }
}

IconData freshReelPlacementIcon(String placement) {
  switch (placement) {
    case freshReelPlacementViewer:
      return Icons.smart_display_outlined;
    case freshReelPlacementCustomerFeed:
      return Icons.home_outlined;
    case freshReelPlacementFarmerFeed:
      return Icons.agriculture_outlined;
    case freshReelPlacementWholesaleFeed:
      return Icons.business_outlined;
    case freshReelPlacementShop:
      return Icons.storefront_outlined;
    case freshReelPlacementFreshBox:
      return Icons.shopping_basket_outlined;
    case freshReelPlacementMealPlanner:
      return Icons.restaurant_menu_outlined;
    default:
      return Icons.place_outlined;
  }
}

Set<String> _defaultPlacementsForReel(HpjFreshReel reel) {
  final placements = <String>{
    freshReelPlacementViewer,
    freshReelPlacementCustomerFeed,
  };
  if (<String>{
    'farm_update',
    'harvest',
    'new_arrival',
    'behind_the_scenes',
    'hpj_update',
    'nutrition',
  }.contains(reel.reelType)) {
    placements.add(freshReelPlacementFarmerFeed);
  }
  return placements;
}


class _FreshReelPlacementSelector extends StatelessWidget {
  final Set<String> selected;
  final bool enabled;
  final void Function(String placement, bool selected) onChanged;

  const _FreshReelPlacementSelector({
    required this.selected,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return FarmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.place_outlined, color: FarmColors.green, size: 21),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Where should this reel show?',
                  style: TextStyle(
                    color: FarmColors.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          const Text(
            'Select one or more placements. You can change them later from Reels management.',
            style: TextStyle(
              color: FarmColors.mutedText,
              fontSize: 11,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _freshReelPlacementOrder.map((placement) {
              final isSelected = selected.contains(placement);
              return FilterChip(
                selected: isSelected,
                avatar: Icon(
                  freshReelPlacementIcon(placement),
                  size: 17,
                  color: isSelected ? FarmColors.green : FarmColors.mutedText,
                ),
                label: Text(freshReelPlacementLabel(placement)),
                onSelected: enabled
                    ? (value) => onChanged(placement, value)
                    : null,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

Future<Set<String>?> showFreshReelPlacementDialog(
  BuildContext context, {
  required Set<String> initial,
  String title = 'Reel placements',
}) async {
  final selected = Set<String>.from(initial);

  return showDialog<Set<String>>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(title),
            content: SizedBox(
              width: 430,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _freshReelPlacementOrder.map((placement) {
                    final checked = selected.contains(placement);
                    return CheckboxListTile(
                      value: checked,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      secondary: Icon(
                        freshReelPlacementIcon(placement),
                        color: FarmColors.green,
                      ),
                      title: Text(
                        freshReelPlacementLabel(placement),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        freshReelPlacementDescription(placement),
                        style: const TextStyle(fontSize: 11),
                      ),
                      onChanged: (value) {
                        setDialogState(() {
                          if (value == true) {
                            selected.add(placement);
                          } else {
                            selected.remove(placement);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: selected.isEmpty
                    ? null
                    : () => Navigator.of(dialogContext).pop(
                          Set<String>.from(selected),
                        ),
                child: const Text('Save placements'),
              ),
            ],
          );
        },
      );
    },
  );
}


class HpjFreshReel {
  final String id;
  final String creatorUserId;
  final String creatorRole;
  final String farmerId;
  final String creatorName;
  final String farmName;
  final String title;
  final String caption;
  final String videoUrl;
  final String storagePath;
  final String thumbnailUrl;
  final String linkedProductId;
  final String reelType;
  final String status;
  final bool isFeatured;
  final int viewCount;
  final int likeCount;
  final int shareCount;
  final String moderationNote;
  final Set<String> placements;
  final DateTime? publishedAt;
  final DateTime? createdAt;
  final bool likedByCurrentUser;

  const HpjFreshReel({
    required this.id,
    required this.creatorUserId,
    required this.creatorRole,
    required this.farmerId,
    required this.creatorName,
    required this.farmName,
    required this.title,
    required this.caption,
    required this.videoUrl,
    required this.storagePath,
    required this.thumbnailUrl,
    required this.linkedProductId,
    required this.reelType,
    required this.status,
    required this.isFeatured,
    required this.viewCount,
    required this.likeCount,
    required this.shareCount,
    required this.moderationNote,
    this.placements = const <String>{},
    required this.publishedAt,
    required this.createdAt,
    this.likedByCurrentUser = false,
  });

  factory HpjFreshReel.fromSupabase(
    Map<String, dynamic> data, {
    bool likedByCurrentUser = false,
  }) {
    final rawPlacements = data['fresh_reel_placements'];
    final placements = rawPlacements is List
        ? rawPlacements
            .map((row) {
              if (row is Map) {
                return (row['placement'] ?? '').toString().trim();
              }
              return '';
            })
            .where((placement) => placement.isNotEmpty)
            .toSet()
        : <String>{};

    return HpjFreshReel(
      id: (data['id'] ?? '').toString(),
      creatorUserId: (data['creator_user_id'] ?? '').toString(),
      creatorRole: (data['creator_role'] ?? 'farmer').toString(),
      farmerId: (data['farmer_id'] ?? '').toString(),
      creatorName: (data['creator_name'] ?? 'HPJ Partner').toString().trim(),
      farmName: (data['farm_name'] ?? '').toString().trim(),
      title: (data['title'] ?? 'Fresh from the farm').toString().trim(),
      caption: (data['caption'] ?? '').toString().trim(),
      videoUrl: (data['video_url'] ?? '').toString().trim(),
      storagePath: (data['storage_path'] ?? '').toString().trim(),
      thumbnailUrl: (data['thumbnail_url'] ?? '').toString().trim(),
      linkedProductId: (data['linked_product_id'] ?? '').toString().trim(),
      reelType: (data['reel_type'] ?? 'farm_update').toString().trim(),
      status: (data['status'] ?? 'pending').toString().trim(),
      isFeatured: data['is_featured'] == true,
      viewCount: Product._toInt(data['view_count']),
      likeCount: Product._toInt(data['like_count']),
      shareCount: Product._toInt(data['share_count']),
      moderationNote: (data['moderation_note'] ?? '').toString().trim(),
      placements: placements,
      publishedAt: parseProductDate(data['published_at']),
      createdAt: parseProductDate(data['created_at']),
      likedByCurrentUser: likedByCurrentUser,
    );
  }

  HpjFreshReel copyWith({
    String? status,
    bool? isFeatured,
    int? viewCount,
    int? likeCount,
    int? shareCount,
    bool? likedByCurrentUser,
    String? moderationNote,
    Set<String>? placements,
  }) {
    return HpjFreshReel(
      id: id,
      creatorUserId: creatorUserId,
      creatorRole: creatorRole,
      farmerId: farmerId,
      creatorName: creatorName,
      farmName: farmName,
      title: title,
      caption: caption,
      videoUrl: videoUrl,
      storagePath: storagePath,
      thumbnailUrl: thumbnailUrl,
      linkedProductId: linkedProductId,
      reelType: reelType,
      status: status ?? this.status,
      isFeatured: isFeatured ?? this.isFeatured,
      viewCount: viewCount ?? this.viewCount,
      likeCount: likeCount ?? this.likeCount,
      shareCount: shareCount ?? this.shareCount,
      moderationNote: moderationNote ?? this.moderationNote,
      placements: placements ?? this.placements,
      publishedAt: publishedAt,
      createdAt: createdAt,
      likedByCurrentUser: likedByCurrentUser ?? this.likedByCurrentUser,
    );
  }

  String get typeLabel {
    switch (reelType) {
      case 'harvest':
        return 'Harvest';
      case 'new_arrival':
        return 'New arrival';
      case 'recipe':
        return 'Recipe';
      case 'nutrition':
        return 'Nutrition';
      case 'behind_the_scenes':
        return 'Behind the scenes';
      case 'hpj_update':
        return 'HPJ update';
      case 'promotion':
        return 'Promotion';
      default:
        return 'Farm update';
    }
  }

  String get creatorLabel {
    if (farmName.isNotEmpty) return farmName;
    if (creatorName.isNotEmpty) return creatorName;
    return 'The Harvest Place Ja';
  }
}

const String _freshReelSelectFields =
    'id, creator_user_id, creator_role, farmer_id, creator_name, farm_name, title, caption, video_url, storage_path, thumbnail_url, linked_product_id, reel_type, status, is_featured, view_count, like_count, share_count, moderation_note, published_at, created_at, fresh_reel_placements(placement)';

Future<Set<String>> _fetchCurrentUserFreshReelLikes() async {
  final user = supabase.auth.currentUser;
  if (user == null) return <String>{};

  try {
    final response = await supabase
        .from('fresh_reel_likes')
        .select('reel_id')
        .eq('user_id', user.id);
    return (response as List)
        .map((row) => (row as Map)['reel_id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
  } catch (error) {
    farmDebugLog('Fresh reel likes unavailable: $error');
    return <String>{};
  }
}

bool _freshReelMatchesPreferences(
  HpjFreshReel reel,
  UserExperiencePreferences preferences,
) {
  if (!preferences.showFreshReels) return false;
  if ((!preferences.showPromotions || !preferences.showPromotionalReels) &&
      reel.reelType == 'promotion') {
    return false;
  }
  if (!preferences.showRecipeReels && reel.reelType == 'recipe') {
    return false;
  }
  if (!preferences.showNutritionReels && reel.reelType == 'nutrition') {
    return false;
  }
  if (!preferences.showFarmerReels &&
      <String>{'farm_update', 'harvest', 'new_arrival', 'behind_the_scenes'}
          .contains(reel.reelType)) {
    return false;
  }
  return true;
}

Future<List<HpjFreshReel>> fetchPublishedFreshReels({
  UserExperiencePreferences preferences = UserExperiencePreferences.defaults,
  int limit = 40,
  String placement = freshReelPlacementViewer,
}) async {
  try {
    final backendLimit = limit < 40 ? 120 : limit * 3;
    final results = await Future.wait<dynamic>([
      supabase
          .from('fresh_reels')
          .select(_freshReelSelectFields)
          .eq('status', 'published')
          .order('is_featured', ascending: false)
          .order('published_at', ascending: false)
          .limit(backendLimit),
      _fetchCurrentUserFreshReelLikes(),
    ]);

    final likes = results[1] as Set<String>;
    final cleanPlacement = placement.trim();
    final reels = (results[0] as List)
        .map(
          (row) => HpjFreshReel.fromSupabase(
            Map<String, dynamic>.from(row as Map),
            likedByCurrentUser:
                likes.contains((row as Map)['id']?.toString() ?? ''),
          ),
        )
        .where((reel) => reel.videoUrl.isNotEmpty)
        .where((reel) => _freshReelMatchesPreferences(reel, preferences))
        .where(
          (reel) => cleanPlacement.isEmpty ||
              reel.placements.contains(cleanPlacement),
        )
        .take(limit)
        .toList();

    return reels;
  } catch (error) {
    farmDebugLog('Published Fresh Reels unavailable: $error');
    return const <HpjFreshReel>[];
  }
}

Future<List<HpjFreshReel>> fetchFarmerFreshReels() async {
  final user = supabase.auth.currentUser;
  if (user == null) return const <HpjFreshReel>[];

  try {
    final response = await supabase
        .from('fresh_reels')
        .select(_freshReelSelectFields)
        .eq('creator_user_id', user.id)
        .order('created_at', ascending: false)
        .limit(80);

    return (response as List)
        .map((row) => HpjFreshReel.fromSupabase(
              Map<String, dynamic>.from(row as Map),
            ))
        .toList();
  } catch (error) {
    farmDebugLog('Farmer Fresh Reels unavailable: $error');
    return const <HpjFreshReel>[];
  }
}

Future<List<HpjFreshReel>> fetchAdminFreshReels({
  String status = 'all',
}) async {
  await requireAdminAccess();

  dynamic query = supabase.from('fresh_reels').select(_freshReelSelectFields);
  final cleanStatus = status.trim().toLowerCase();
  if (cleanStatus != 'all') {
    query = query.eq('status', cleanStatus);
  }

  final response = await query
      .order('status', ascending: true)
      .order('is_featured', ascending: false)
      .order('created_at', ascending: false)
      .limit(150);

  return (response as List)
      .map((row) => HpjFreshReel.fromSupabase(
            Map<String, dynamic>.from(row as Map),
          ))
      .toList();
}

Future<void> recordFreshReelView(String reelId) async {
  final user = supabase.auth.currentUser;
  if (user == null || reelId.trim().isEmpty) return;
  try {
    await supabase.from('fresh_reel_views').insert(
      {
        'reel_id': reelId,
        'user_id': user.id,
        'viewed_on': DateTime.now().toIso8601String().substring(0, 10),
      },
    );
  } catch (error) {
    farmDebugLog('Fresh reel view tracking skipped: $error');
  }
}

Future<bool> setFreshReelLiked({
  required String reelId,
  required bool liked,
}) async {
  final user = supabase.auth.currentUser;
  if (user == null) {
    throw Exception('Sign in to like Fresh Reels.');
  }

  if (liked) {
    await supabase.from('fresh_reel_likes').insert(
      {
        'reel_id': reelId,
        'user_id': user.id,
      },
    );
  } else {
    await supabase
        .from('fresh_reel_likes')
        .delete()
        .eq('reel_id', reelId)
        .eq('user_id', user.id);
  }
  return liked;
}

Future<void> recordFreshReelShare(String reelId) async {
  if (reelId.trim().isEmpty) return;
  try {
    await supabase.rpc(
      'record_fresh_reel_share',
      params: {'p_reel_id': reelId},
    );
  } catch (error) {
    farmDebugLog('Fresh reel share tracking skipped: $error');
  }
}

String _safeFreshReelFileName(String raw) {
  final clean = raw
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9._-]+'), '_')
      .replaceAll(RegExp(r'_+'), '_');
  if (clean.isEmpty) return 'reel.mp4';
  return clean.length > 80 ? clean.substring(clean.length - 80) : clean;
}

Future<void> submitFarmerFreshReel({
  required FarmerProfile profile,
  required XFile video,
  required String title,
  required String caption,
  required String reelType,
  String? linkedProductId,
}) async {
  final user = supabase.auth.currentUser;
  if (user == null) throw Exception('Please sign in again.');
  if (!profile.isApproved) {
    throw Exception('Farmer verification must be approved before submitting reels.');
  }

  final cleanTitle = title.trim();
  if (cleanTitle.length < 3) {
    throw Exception('Add a short title for your reel.');
  }

  final bytes = await video.readAsBytes();
  if (bytes.isEmpty) throw Exception('The selected video is empty.');
  if (bytes.length > _freshReelMaxBytes) {
    throw Exception('Keep Fresh Reels under 30 MB. Shorter videos upload faster.');
  }

  final fileName = _safeFreshReelFileName(video.name);
  final path = '${user.id}/${DateTime.now().microsecondsSinceEpoch}_$fileName';
  final mimeType = (video.mimeType ?? '').trim().isNotEmpty
      ? video.mimeType!.trim()
      : 'video/mp4';

  await supabase.storage.from(_freshReelsBucket).uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(
          contentType: mimeType,
          upsert: false,
        ),
      );

  final videoUrl = supabase.storage.from(_freshReelsBucket).getPublicUrl(path);

  try {
    await supabase.from('fresh_reels').insert({
      'creator_user_id': user.id,
      'creator_role': 'farmer',
      'farmer_id': profile.id,
      'creator_name': profile.farmerName,
      'farm_name': profile.farmName,
      'title': cleanTitle,
      'caption': caption.trim(),
      'video_url': videoUrl,
      'storage_path': path,
      'linked_product_id': linkedProductId?.trim().isEmpty == true
          ? null
          : linkedProductId?.trim(),
      'reel_type': reelType,
      'status': 'pending',
      'is_featured': false,
    });
  } catch (error) {
    try {
      await supabase.storage.from(_freshReelsBucket).remove([path]);
    } catch (_) {}
    rethrow;
  }
}

Future<void> submitAdminFreshReel({
  required XFile video,
  required String title,
  required String caption,
  required String reelType,
  required Set<String> placements,
  String? linkedProductId,
}) async {
  await requireAdminAccess();
  final user = supabase.auth.currentUser;
  if (user == null) throw Exception('Please sign in again.');

  final cleanTitle = title.trim();
  if (cleanTitle.length < 3) {
    throw Exception('Add a short title for your reel.');
  }

  final bytes = await video.readAsBytes();
  if (bytes.isEmpty) throw Exception('The selected video is empty.');
  if (bytes.length > _freshReelMaxBytes) {
    throw Exception('Keep Fresh Reels under 30 MB.');
  }

  final fileName = _safeFreshReelFileName(video.name);
  final path = '${user.id}/${DateTime.now().microsecondsSinceEpoch}_$fileName';
  final mimeType = (video.mimeType ?? '').trim().isNotEmpty
      ? video.mimeType!.trim()
      : 'video/mp4';

  await supabase.storage.from(_freshReelsBucket).uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(
          contentType: mimeType,
          upsert: false,
        ),
      );

  final videoUrl = supabase.storage.from(_freshReelsBucket).getPublicUrl(path);

  final cleanPlacements = placements
      .where(_freshReelPlacementOrder.contains)
      .toSet();
  if (cleanPlacements.isEmpty) {
    try {
      await supabase.storage.from(_freshReelsBucket).remove([path]);
    } catch (_) {}
    throw Exception('Choose at least one place for this reel to appear.');
  }

  String createdReelId = '';
  try {
    final inserted = await supabase
        .from('fresh_reels')
        .insert({
          'creator_user_id': user.id,
          'creator_role': 'hpj',
          'creator_name': AppConfig.appName,
          'farm_name': AppConfig.appName,
          'title': cleanTitle,
          'caption': caption.trim(),
          'video_url': videoUrl,
          'storage_path': path,
          'linked_product_id': linkedProductId?.trim().isEmpty == true
              ? null
              : linkedProductId?.trim(),
          'reel_type': reelType,
          'status': 'published',
          'published_at': DateTime.now().toIso8601String(),
          'is_featured': false,
          'moderated_by': user.id,
          'moderated_at': DateTime.now().toIso8601String(),
        })
        .select('id')
        .single();

    createdReelId = (inserted['id'] ?? '').toString();
    if (createdReelId.isEmpty) {
      throw Exception('The reel was created without an ID.');
    }

    await setFreshReelPlacements(
      reelId: createdReelId,
      placements: cleanPlacements,
    );
  } catch (error) {
    if (createdReelId.isNotEmpty) {
      try {
        await supabase.from('fresh_reels').update({
          'status': 'archived',
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', createdReelId);
      } catch (_) {}
    }
    try {
      await supabase.storage.from(_freshReelsBucket).remove([path]);
    } catch (_) {}
    rethrow;
  }
}


Future<void> setFreshReelPlacements({
  required String reelId,
  required Set<String> placements,
}) async {
  await requireAdminAccess();

  final clean = placements
      .map((placement) => placement.trim())
      .where(_freshReelPlacementOrder.contains)
      .toSet()
      .toList()
    ..sort(
      (a, b) => _freshReelPlacementOrder
          .indexOf(a)
          .compareTo(_freshReelPlacementOrder.indexOf(b)),
    );

  if (clean.isEmpty) {
    throw Exception('Choose at least one place for this reel to appear.');
  }

  await supabase.rpc(
    'hpj_set_fresh_reel_placements',
    params: {
      'p_reel_id': reelId,
      'p_placements': clean,
    },
  );
}

Future<void> moderateFreshReel({
  required String reelId,
  required String status,
  String moderationNote = '',
}) async {
  await requireAdminAccess();
  final user = supabase.auth.currentUser;
  final cleanStatus = status.trim().toLowerCase();
  if (!<String>{'pending', 'published', 'rejected', 'archived'}
      .contains(cleanStatus)) {
    throw Exception('Unsupported reel status.');
  }

  final payload = <String, dynamic>{
    'status': cleanStatus,
    'moderation_note': moderationNote.trim().isEmpty
        ? null
        : moderationNote.trim(),
    'moderated_by': user?.id,
    'moderated_at': DateTime.now().toIso8601String(),
    'updated_at': DateTime.now().toIso8601String(),
  };
  if (cleanStatus == 'published') {
    payload['published_at'] = DateTime.now().toIso8601String();
  }

  await supabase.from('fresh_reels').update(payload).eq('id', reelId);
}

Future<void> setFreshReelFeatured({
  required String reelId,
  required bool isFeatured,
}) async {
  await requireAdminAccess();
  await supabase.from('fresh_reels').update({
    'is_featured': isFeatured,
    'updated_at': DateTime.now().toIso8601String(),
  }).eq('id', reelId);
}


class FreshReelFeedPreviewCard extends StatefulWidget {
  final UserExperiencePreferences preferences;
  final String audience;
  final String placement;
  final int refreshKey;
  final ValueChanged<Product>? onAddToCart;

  const FreshReelFeedPreviewCard({
    super.key,
    required this.preferences,
    required this.audience,
    required this.placement,
    this.refreshKey = 0,
    this.onAddToCart,
  });

  @override
  State<FreshReelFeedPreviewCard> createState() =>
      _FreshReelFeedPreviewCardState();
}

class _FreshReelFeedPreviewCardState
    extends State<FreshReelFeedPreviewCard> {
  late Future<List<HpjFreshReel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant FreshReelFeedPreviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.refreshKey != widget.refreshKey ||
        oldWidget.audience != widget.audience ||
        oldWidget.placement != widget.placement ||
        oldWidget.preferences.showFreshReels !=
            widget.preferences.showFreshReels ||
        oldWidget.preferences.showFarmerReels !=
            widget.preferences.showFarmerReels ||
        oldWidget.preferences.showRecipeReels !=
            widget.preferences.showRecipeReels ||
        oldWidget.preferences.showNutritionReels !=
            widget.preferences.showNutritionReels ||
        oldWidget.preferences.showPromotionalReels !=
            widget.preferences.showPromotionalReels ||
        oldWidget.preferences.showPromotions !=
            widget.preferences.showPromotions) {
      _future = _load();
    }
  }

  Future<List<HpjFreshReel>> _load() async {
    final reels = await fetchPublishedFreshReels(
      preferences: widget.preferences,
      placement: widget.placement,
      limit: 12,
    );

    if (widget.audience != 'farmer' || reels.length < 2) {
      return reels;
    }

    const farmerPriorityTypes = <String>{
      'harvest',
      'farm_update',
      'new_arrival',
      'behind_the_scenes',
      'hpj_update',
      'nutrition',
    };

    final priority =
        reels.where((reel) => farmerPriorityTypes.contains(reel.reelType));
    return <HpjFreshReel>[
      ...priority,
      ...reels.where((reel) => !farmerPriorityTypes.contains(reel.reelType)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.preferences.showFreshReels) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<List<HpjFreshReel>>(
      future: _future,
      builder: (context, snapshot) {
        final reels = snapshot.data ?? const <HpjFreshReel>[];
        if (snapshot.connectionState == ConnectionState.waiting ||
            reels.isEmpty) {
          return const SizedBox.shrink();
        }

        return _FreshReelInlineFeedPost(
          reel: reels.first,
          preferences: widget.preferences,
          audience: widget.audience,
          onAddToCart: widget.onAddToCart,
          placement: widget.placement,
        );
      },
    );
  }
}

class _FreshReelInlineFeedPost extends StatefulWidget {
  final HpjFreshReel reel;
  final UserExperiencePreferences preferences;
  final String audience;
  final ValueChanged<Product>? onAddToCart;
  final String placement;

  const _FreshReelInlineFeedPost({
    required this.reel,
    required this.preferences,
    required this.audience,
    required this.placement,
    this.onAddToCart,
  });

  @override
  State<_FreshReelInlineFeedPost> createState() =>
      _FreshReelInlineFeedPostState();
}

class _FreshReelInlineFeedPostState extends State<_FreshReelInlineFeedPost> {
  VideoPlayerController? _controller;
  Product? _linkedProduct;
  bool _videoReady = false;
  int _prepareGeneration = 0;

  bool get _dataSaver =>
      widget.preferences.feedImageMode == 'data_saver';

  bool get _autoplay =>
      widget.preferences.reelsAutoplay && !_dataSaver;

  @override
  void initState() {
    super.initState();
    unawaited(_prepare());
  }

  @override
  void didUpdateWidget(covariant _FreshReelInlineFeedPost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reel.id != widget.reel.id ||
        oldWidget.preferences.reelsAutoplay !=
            widget.preferences.reelsAutoplay ||
        oldWidget.preferences.feedImageMode !=
            widget.preferences.feedImageMode) {
      unawaited(_prepare());
    }
  }

  Future<void> _prepare() async {
    final generation = ++_prepareGeneration;
    final previous = _controller;
    _controller = null;
    _videoReady = false;
    await previous?.dispose();

    Product? linkedProduct;
    if (widget.reel.linkedProductId.isNotEmpty &&
        widget.audience == 'customer') {
      try {
        linkedProduct = await fetchProductById(widget.reel.linkedProductId);
      } catch (error) {
        farmDebugLog('Fresh Reel feed product unavailable: $error');
      }
    }

    VideoPlayerController? controller;
    if (!_dataSaver && widget.reel.videoUrl.isNotEmpty) {
      try {
        controller = VideoPlayerController.networkUrl(
          Uri.parse(widget.reel.videoUrl),
        );
        await controller.initialize();
        await controller.setLooping(true);
        await controller.setVolume(0);
        if (_autoplay) {
          await controller.play();
        }
      } catch (error) {
        farmDebugLog('Fresh Reel feed preview unavailable: $error');
        await controller?.dispose();
        controller = null;
      }
    }

    if (!mounted || generation != _prepareGeneration) {
      await controller?.dispose();
      return;
    }

    setState(() {
      _linkedProduct = linkedProduct;
      _controller = controller;
      _videoReady = controller?.value.isInitialized == true;
    });
  }

  @override
  void dispose() {
    _prepareGeneration++;
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _openReel() async {
    await _controller?.pause();
    unawaited(recordFreshReelView(widget.reel.id));

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FreshReelsScreen(
          preferences: widget.preferences,
          onAddToCart: widget.onAddToCart,
          initialReelId: widget.reel.id,
          placement: widget.placement,
        ),
      ),
    );

    if (!mounted || !_autoplay) return;
    try {
      await _controller?.play();
    } catch (_) {}
  }

  Widget _media() {
    final thumbnail = widget.reel.thumbnailUrl.trim();

    if (_videoReady && _controller != null) {
      final controller = _controller!;
      final size = controller.value.size;
      if (size.width > 0 && size.height > 0) {
        return FittedBox(
          fit: BoxFit.cover,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: VideoPlayer(controller),
          ),
        );
      }
    }

    if (thumbnail.isNotEmpty && !_dataSaver) {
      return Image.network(
        thumbnail,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (_, __, ___) => _mediaFallback(),
      );
    }

    return _mediaFallback();
  }

  Widget _mediaFallback() {
    return Container(
      color: FarmColors.deepGreen,
      alignment: Alignment.center,
      child: Icon(
        Icons.play_circle_fill_rounded,
        color: Colors.white.withOpacity(0.92),
        size: 58,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = _linkedProduct;
    final customerView = widget.audience == 'customer';

    return FarmCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Material(
          color: Colors.white,
          child: InkWell(
            onTap: _openReel,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(15, 14, 12, 10),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: FarmColors.lightGreen,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Icon(
                          Icons.smart_display_outlined,
                          color: FarmColors.green,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.reel.creatorLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: FarmColors.ink,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${widget.reel.typeLabel} • Fresh Reel',
                              style: TextStyle(
                                color: FarmColors.mutedText,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: _openReel,
                        child: const Text('Watch'),
                      ),
                    ],
                  ),
                ),
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _media(),
                      if (!_autoplay || !_videoReady)
                        const Center(
                          child: Icon(
                            Icons.play_circle_fill_rounded,
                            color: Colors.white,
                            size: 52,
                            shadows: [
                              Shadow(
                                color: Colors.black45,
                                blurRadius: 12,
                              ),
                            ],
                          ),
                        ),
                      Positioned(
                        left: 12,
                        bottom: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.58),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'FRESH REEL',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.7,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(15, 13, 15, 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.reel.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: FarmColors.ink,
                          fontSize: 16,
                          height: 1.2,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (widget.reel.caption.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          widget.reel.caption,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: FarmColors.mutedText,
                            fontSize: 12,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 11),
                      Row(
                        children: [
                          Icon(
                            Icons.visibility_outlined,
                            size: 16,
                            color: FarmColors.mutedText,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.reel.viewCount}',
                            style: TextStyle(
                              color: FarmColors.mutedText,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 13),
                          Icon(
                            Icons.favorite_border_rounded,
                            size: 16,
                            color: FarmColors.mutedText,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.reel.likeCount}',
                            style: TextStyle(
                              color: FarmColors.mutedText,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          if (customerView &&
                              product != null &&
                              product.canAddToCart &&
                              widget.onAddToCart != null)
                            FilledButton.icon(
                              onPressed: () {
                                widget.onAddToCart!(product);
                              },
                              icon: const Icon(
                                Icons.add_shopping_cart_rounded,
                                size: 17,
                              ),
                              label: const Text('Add to Box'),
                              style: FilledButton.styleFrom(
                                backgroundColor: FarmColors.green,
                                foregroundColor: Colors.white,
                                visualDensity: VisualDensity.compact,
                              ),
                            )
                          else
                            TextButton.icon(
                              onPressed: _openReel,
                              icon: const Icon(
                                Icons.play_arrow_rounded,
                                size: 18,
                              ),
                              label: const Text('Open Reels'),
                            ),
                        ],
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

class HpjFreshReelsEntryScreen extends StatelessWidget {
  final ValueChanged<Product>? onAddToCart;

  const HpjFreshReelsEntryScreen({
    super.key,
    this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserExperiencePreferences>(
      future: fetchCurrentUserExperiencePreferences(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: SafeArea(
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          );
        }
        return FreshReelsScreen(
          preferences: snapshot.data ?? UserExperiencePreferences.defaults,
          onAddToCart: onAddToCart,
        );
      },
    );
  }
}

class FreshReelsScreen extends StatefulWidget {
  final UserExperiencePreferences preferences;
  final ValueChanged<Product>? onAddToCart;
  final String initialReelId;
  final String placement;

  const FreshReelsScreen({
    super.key,
    this.preferences = UserExperiencePreferences.defaults,
    this.onAddToCart,
    this.initialReelId = '',
    this.placement = freshReelPlacementViewer,
  });

  @override
  State<FreshReelsScreen> createState() => _FreshReelsScreenState();
}

class _FreshReelsScreenState extends State<FreshReelsScreen> {
  late Future<List<HpjFreshReel>> _future;
  int _activeIndex = 0;
  bool _muted = true;

  @override
  void initState() {
    super.initState();
    _muted = widget.preferences.reelsMutedByDefault;
    _future = _loadReels();
  }

  Future<List<HpjFreshReel>> _loadReels() async {
    final reels = await fetchPublishedFreshReels(
      preferences: widget.preferences,
      placement: widget.placement,
    );

    final requestedId = widget.initialReelId.trim();
    if (requestedId.isEmpty || reels.length < 2) return reels;

    final requestedIndex = reels.indexWhere((reel) => reel.id == requestedId);
    if (requestedIndex <= 0) return reels;

    final ordered = List<HpjFreshReel>.of(reels);
    final requested = ordered.removeAt(requestedIndex);
    ordered.insert(0, requested);
    return ordered;
  }

  Future<void> _refresh() async {
    final next = _loadReels();
    setState(() {
      _future = next;
      _activeIndex = 0;
    });
    await next;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: FutureBuilder<List<HpjFreshReel>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }

            final reels = snapshot.data ?? const <HpjFreshReel>[];
            if (reels.isEmpty) {
              return _FreshReelsEmptyState(onRefresh: _refresh);
            }

            return Stack(
              children: [
                PageView.builder(
                  scrollDirection: Axis.vertical,
                  itemCount: reels.length,
                  onPageChanged: (index) {
                    setState(() => _activeIndex = index);
                    unawaited(recordFreshReelView(reels[index].id));
                  },
                  itemBuilder: (context, index) {
                    return _FreshReelPage(
                      reel: reels[index],
                      active: index == _activeIndex,
                      muted: _muted,
                      autoplay: widget.preferences.reelsAutoplay &&
                          widget.preferences.feedImageMode != 'data_saver',
                      onMuteChanged: (value) => setState(() => _muted = value),
                      onAddToCart: widget.onAddToCart,
                      onReelChanged: (updated) {
                        final current = snapshot.data;
                        if (current == null || index >= current.length) return;
                        current[index] = updated;
                        if (mounted) setState(() {});
                      },
                    );
                  },
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: _ReelCircleButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: 'Back',
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 64,
                  right: 64,
                  child: IgnorePointer(
                    child: Column(
                      children: [
                        const Text(
                          'Fresh Reels',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            shadows: [Shadow(blurRadius: 8, color: Colors.black54)],
                          ),
                        ),
                        Text(
                          '${_activeIndex + 1} of ${reels.length}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FreshReelsEmptyState extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const _FreshReelsEmptyState({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: FarmColors.deepGreen,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.video_library_outlined,
                color: Colors.white.withOpacity(0.88),
                size: 54,
              ),
              const SizedBox(height: 14),
              const Text(
                'Fresh Reels are coming in.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Approved farm, harvest and recipe videos will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Refresh'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54),
                ),
              ),
              TextButton.icon(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Back'),
                style: TextButton.styleFrom(foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FreshReelPage extends StatefulWidget {
  final HpjFreshReel reel;
  final bool active;
  final bool muted;
  final bool autoplay;
  final ValueChanged<bool> onMuteChanged;
  final ValueChanged<Product>? onAddToCart;
  final ValueChanged<HpjFreshReel> onReelChanged;

  const _FreshReelPage({
    required this.reel,
    required this.active,
    required this.muted,
    required this.autoplay,
    required this.onMuteChanged,
    required this.onAddToCart,
    required this.onReelChanged,
  });

  @override
  State<_FreshReelPage> createState() => _FreshReelPageState();
}

class _FreshReelPageState extends State<_FreshReelPage> {
  VideoPlayerController? _controller;
  bool _loading = true;
  bool _videoFailed = false;
  bool _busyLike = false;
  Product? _linkedProduct;

  @override
  void initState() {
    super.initState();
    unawaited(_prepare());
    if (widget.active) unawaited(recordFreshReelView(widget.reel.id));
  }

  @override
  void didUpdateWidget(covariant _FreshReelPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.muted != widget.muted) {
      _controller?.setVolume(widget.muted ? 0 : 1);
    }
    if (oldWidget.active != widget.active ||
        oldWidget.autoplay != widget.autoplay) {
      _syncPlayback();
    }
  }

  Future<void> _prepare() async {
    try {
      if (widget.reel.linkedProductId.isNotEmpty) {
        _linkedProduct = await fetchProductById(widget.reel.linkedProductId);
      }

      final controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.reel.videoUrl),
      );
      await controller.initialize();
      await controller.setLooping(true);
      await controller.setVolume(widget.muted ? 0 : 1);
      _controller = controller;
      _syncPlayback();
    } catch (error) {
      farmDebugLog('Fresh reel video failed: $error');
      _videoFailed = true;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _syncPlayback() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (widget.active && widget.autoplay) {
      unawaited(controller.play());
    } else {
      unawaited(controller.pause());
    }
  }

  Future<void> _togglePlayback() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      await controller.play();
    }
    if (mounted) setState(() {});
  }

  Future<void> _toggleLike() async {
    if (_busyLike) return;
    final next = !widget.reel.likedByCurrentUser;
    setState(() => _busyLike = true);
    try {
      await setFreshReelLiked(reelId: widget.reel.id, liked: next);
      widget.onReelChanged(
        widget.reel.copyWith(
          likedByCurrentUser: next,
          likeCount: (widget.reel.likeCount + (next ? 1 : -1)).clamp(0, 999999).toInt(),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _busyLike = false);
    }
  }

  Future<void> _share() async {
    final message = StringBuffer()
      ..writeln(widget.reel.title)
      ..writeln(widget.reel.creatorLabel)
      ..writeln()
      ..write('Watch fresh Jamaican farm content on ${AppConfig.appName}: ${AppConfig.shareableAppLink}');
    await Clipboard.setData(ClipboardData(text: message.toString()));
    unawaited(recordFreshReelShare(widget.reel.id));
    widget.onReelChanged(
      widget.reel.copyWith(shareCount: widget.reel.shareCount + 1),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reel details copied. Share it anywhere.')),
    );
  }

  void _addProduct() {
    final product = _linkedProduct;
    if (product == null || !product.canAddToCart) return;
    final callback = widget.onAddToCart;
    if (callback != null) {
      callback(product);
    } else {
      unawaited(saveCartItemForCurrentUser(product));
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${product.name} added to My Box.')),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final product = _linkedProduct;
    final canShop = product != null && product.canAddToCart;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _togglePlayback,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: Colors.black),
          if (_loading)
            const Center(child: CircularProgressIndicator(color: Colors.white))
          else if (_videoFailed || controller == null || !controller.value.isInitialized)
            _ReelVideoFallback(reel: widget.reel)
          else
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: controller.value.size.width <= 0
                      ? 360
                      : controller.value.size.width,
                  height: controller.value.size.height <= 0
                      ? 640
                      : controller.value.size.height,
                  child: VideoPlayer(controller),
                ),
              ),
            ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Colors.transparent, Colors.black87],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.55, 1.0],
              ),
            ),
          ),
          Positioned(
            right: 12,
            bottom: canShop ? 156 : 118,
            child: Column(
              children: [
                _ReelActionButton(
                  icon: widget.reel.likedByCurrentUser
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  label: _compactCount(widget.reel.likeCount),
                  active: widget.reel.likedByCurrentUser,
                  onTap: _toggleLike,
                ),
                const SizedBox(height: 13),
                _ReelActionButton(
                  icon: Icons.share_outlined,
                  label: widget.reel.shareCount > 0
                      ? _compactCount(widget.reel.shareCount)
                      : 'Share',
                  onTap: _share,
                ),
                const SizedBox(height: 13),
                _ReelActionButton(
                  icon: widget.muted
                      ? Icons.volume_off_rounded
                      : Icons.volume_up_rounded,
                  label: widget.muted ? 'Muted' : 'Sound',
                  onTap: () => widget.onMuteChanged(!widget.muted),
                ),
              ],
            ),
          ),
          Positioned(
            left: 16,
            right: 76,
            bottom: canShop ? 100 : 28,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: FarmColors.green.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        widget.reel.typeLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (widget.reel.isFeatured) ...[
                      const SizedBox(width: 7),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'FEATURED',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 9),
                Text(
                  widget.reel.creatorLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  widget.reel.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    height: 1.12,
                  ),
                ),
                if (widget.reel.caption.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    widget.reel.caption,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (canShop)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: _ReelProductBar(
                product: product,
                onAdd: _addProduct,
              ),
            ),
          if (!_loading &&
              !_videoFailed &&
              controller != null &&
              controller.value.isInitialized &&
              !controller.value.isPlaying)
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: const Icon(Icons.play_arrow_rounded,
                    color: Colors.white, size: 42),
              ),
            ),
        ],
      ),
    );
  }
}

String _compactCount(int value) {
  if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
  return '$value';
}

class _ReelVideoFallback extends StatelessWidget {
  final HpjFreshReel reel;

  const _ReelVideoFallback({required this.reel});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [FarmColors.deepGreen, FarmColors.green],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.videocam_off_outlined, color: Colors.white70, size: 58),
      ),
    );
  }
}

class _ReelActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  const _ReelActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: SizedBox(
        width: 58,
        child: Column(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.black45,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24),
              ),
              child: Icon(
                icon,
                color: active ? const Color(0xFFFF6B74) : Colors.white,
                size: 25,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                shadows: [Shadow(blurRadius: 6, color: Colors.black87)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReelCircleButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _ReelCircleButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.black45,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white24),
          ),
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }
}

class _ReelProductBar extends StatelessWidget {
  final Product product;
  final VoidCallback onAdd;

  const _ReelProductBar({required this.product, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 18, offset: Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: FarmColors.primarySoft,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(Icons.eco_outlined, color: FarmColors.green),
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
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'J\$${product.effectivePrice.toStringAsFixed(0)}${(product.unit ?? '').trim().isEmpty ? '' : ' • ${product.unit}'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: FarmColors.mutedText,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_shopping_cart_rounded, size: 17),
            label: const Text('Add'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class FarmerFreshReelsHubScreen extends StatefulWidget {
  final FarmerProfile profile;

  const FarmerFreshReelsHubScreen({
    super.key,
    required this.profile,
  });

  @override
  State<FarmerFreshReelsHubScreen> createState() =>
      _FarmerFreshReelsHubScreenState();
}

class _FarmerFreshReelsHubScreenState extends State<FarmerFreshReelsHubScreen> {
  late Future<List<HpjFreshReel>> _future;

  @override
  void initState() {
    super.initState();
    _future = fetchFarmerFreshReels();
  }

  void _reload() {
    if (!mounted) return;
    setState(() {
      _future = fetchFarmerFreshReels();
    });
  }

  Future<void> _submit() async {
    final submitted = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => FarmerFreshReelSubmissionScreen(profile: widget.profile),
      ),
    );
    if (submitted == true && mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back to Farmer Account',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Fresh Reels'),
      ),
      floatingActionButton: widget.profile.isApproved
          ? FloatingActionButton.extended(
              onPressed: _submit,
              backgroundColor: FarmColors.green,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.video_call_outlined),
              label: const Text('Submit Reel'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async {
          _reload();
          await _future;
        },
        child: FutureBuilder<List<HpjFreshReel>>(
          future: _future,
          builder: (context, snapshot) {
            final reels = snapshot.data ?? const <HpjFreshReel>[];
            if (snapshot.connectionState == ConnectionState.waiting && reels.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
              children: [
                const Header(
                  title: 'Your Fresh Reels',
                  subtitle: 'Share short farm videos for HPJ review.',
                ),
                const SizedBox(height: 12),
                FarmCard(
                  child: Text(
                    widget.profile.isApproved
                        ? 'Submit 15–60 second vertical videos. HPJ reviews every reel before customers see it.'
                        : 'Reel submission becomes available after your farmer profile is approved.',
                    style: const TextStyle(
                      color: FarmColors.mutedText,
                      height: 1.4,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                if (reels.isEmpty)
                  const FarmCard(
                    child: Text(
                      'No reels submitted yet.',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  )
                else
                  ...reels.map((reel) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _FarmerReelStatusCard(reel: reel),
                      )),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FarmerReelStatusCard extends StatelessWidget {
  final HpjFreshReel reel;

  const _FarmerReelStatusCard({required this.reel});

  Color get _statusColor {
    switch (reel.status) {
      case 'published':
        return FarmColors.green;
      case 'rejected':
        return FarmColors.error;
      case 'archived':
        return FarmColors.muted;
      default:
        return FarmColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FarmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(Icons.play_circle_outline_rounded, color: _statusColor),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reel.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: FarmColors.ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${reel.typeLabel} • ${reel.status.toUpperCase()}',
                      style: TextStyle(
                        color: _statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Preview',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => FreshReelModerationPreviewScreen(reel: reel),
                  ),
                ),
                icon: const Icon(Icons.visibility_outlined),
              ),
            ],
          ),
          if (reel.moderationNote.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'HPJ note: ${reel.moderationNote}',
              style: const TextStyle(
                color: FarmColors.mutedText,
                fontSize: 11,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (reel.status == 'published' && reel.placements.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 5,
              runSpacing: 5,
              children: _freshReelPlacementOrder
                  .where(reel.placements.contains)
                  .map(
                    (placement) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: FarmColors.primarySoft,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        freshReelPlacementLabel(placement),
                        style: const TextStyle(
                          color: FarmColors.green,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (reel.status == 'published') ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              children: [
                Text('${reel.viewCount} views', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                Text('${reel.likeCount} likes', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                Text('${reel.shareCount} shares', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class FarmerFreshReelSubmissionScreen extends StatefulWidget {
  final FarmerProfile profile;

  const FarmerFreshReelSubmissionScreen({
    super.key,
    required this.profile,
  });

  @override
  State<FarmerFreshReelSubmissionScreen> createState() =>
      _FarmerFreshReelSubmissionScreenState();
}

class _FarmerFreshReelSubmissionScreenState
    extends State<FarmerFreshReelSubmissionScreen> {
  final _titleController = TextEditingController();
  final _captionController = TextEditingController();
  XFile? _video;
  String _reelType = 'farm_update';
  String _linkedProductId = '';
  bool _submitting = false;
  late Future<List<Product>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _productsFuture = fetchProducts().then(
      (products) => products
          .where((product) => product.farmerId == widget.profile.id)
          .toList(),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    final picked = await ImagePicker().pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: 60),
    );
    if (picked == null || !mounted) return;
    setState(() => _video = picked);
  }

  Future<void> _submit() async {
    if (_video == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a short video first.')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await submitFarmerFreshReel(
        profile: widget.profile,
        video: _video!,
        title: _titleController.text,
        caption: _captionController.text,
        reelType: _reelType,
        linkedProductId: _linkedProductId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reel submitted to HPJ for review.')),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Submit Fresh Reel'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 110),
        children: [
          const Header(
            title: 'Show what is fresh',
            subtitle: '15–60 seconds • vertical works best • HPJ reviews before publishing',
          ),
          const SizedBox(height: 14),
          FarmCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  onPressed: _submitting ? null : _pickVideo,
                  icon: const Icon(Icons.video_library_outlined),
                  label: Text(_video == null ? 'Choose video' : 'Change video'),
                ),
                if (_video != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _video!.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: FarmColors.mutedText,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titleController,
            maxLength: 80,
            decoration: const InputDecoration(
              labelText: 'Title',
              hintText: 'e.g. Scotch bonnet ready this morning',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _captionController,
            maxLength: 280,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Caption',
              hintText: 'Tell customers what they are seeing.',
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _reelType,
            decoration: const InputDecoration(labelText: 'Reel type'),
            items: const [
              DropdownMenuItem(value: 'farm_update', child: Text('Farm update')),
              DropdownMenuItem(value: 'harvest', child: Text('Harvest')),
              DropdownMenuItem(value: 'new_arrival', child: Text('New arrival')),
              DropdownMenuItem(value: 'behind_the_scenes', child: Text('Behind the scenes')),
              DropdownMenuItem(value: 'recipe', child: Text('Recipe / preparation')),
            ],
            onChanged: _submitting
                ? null
                : (value) => setState(() => _reelType = value ?? 'farm_update'),
          ),
          const SizedBox(height: 10),
          FutureBuilder<List<Product>>(
            future: _productsFuture,
            builder: (context, snapshot) {
              final products = snapshot.data ?? const <Product>[];
              return DropdownButtonFormField<String>(
                value: _linkedProductId,
                decoration: const InputDecoration(
                  labelText: 'Linked produce (optional)',
                  helperText: 'Customers can add linked produce to My Box from the reel.',
                ),
                items: [
                  const DropdownMenuItem(value: '', child: Text('No linked product')),
                  ...products.map(
                    (product) => DropdownMenuItem(
                      value: product.id,
                      child: Text(product.name, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
                onChanged: _submitting
                    ? null
                    : (value) => setState(() => _linkedProductId = value ?? ''),
              );
            },
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: _submitting ? null : _submit,
            icon: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.send_rounded),
            label: Text(_submitting ? 'Uploading...' : 'Submit for review'),
          ),
        ],
      ),
    );
  }
}

class AdminFreshReelSubmissionScreen extends StatefulWidget {
  const AdminFreshReelSubmissionScreen({super.key});

  @override
  State<AdminFreshReelSubmissionScreen> createState() =>
      _AdminFreshReelSubmissionScreenState();
}

class _AdminFreshReelSubmissionScreenState
    extends State<AdminFreshReelSubmissionScreen> {
  final _titleController = TextEditingController();
  final _captionController = TextEditingController();
  XFile? _video;
  String _reelType = 'hpj_update';
  String _linkedProductId = '';
  final Set<String> _placements = <String>{
    freshReelPlacementViewer,
    freshReelPlacementCustomerFeed,
  };
  bool _submitting = false;
  late Future<List<Product>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _productsFuture = fetchProducts();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    final picked = await ImagePicker().pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: 60),
    );
    if (picked == null || !mounted) return;
    setState(() => _video = picked);
  }

  Future<void> _submit() async {
    if (_video == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a short video first.')),
      );
      return;
    }

    if (_placements.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choose at least one place for this reel to appear.'),
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await submitAdminFreshReel(
        video: _video!,
        title: _titleController.text,
        caption: _captionController.text,
        reelType: _reelType,
        placements: _placements,
        linkedProductId: _linkedProductId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('HPJ reel published.')),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back to Reels',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Create HPJ Reel'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 110),
        children: [
          const Header(
            title: 'Publish a Fresh Reel',
            subtitle:
                'Use for HPJ updates, recipes, nutrition, arrivals or promotions.',
          ),
          const SizedBox(height: 14),
          FarmCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  onPressed: _submitting ? null : _pickVideo,
                  icon: const Icon(Icons.video_library_outlined),
                  label: Text(_video == null ? 'Choose video' : 'Change video'),
                ),
                if (_video != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _video!.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: FarmColors.mutedText,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titleController,
            maxLength: 80,
            decoration: const InputDecoration(
              labelText: 'Title',
              hintText: 'e.g. Pumpkin soup in 30 seconds',
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _captionController,
            maxLength: 280,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Caption',
              hintText: 'Tell customers what they are seeing.',
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _reelType,
            decoration: const InputDecoration(labelText: 'Reel type'),
            items: const [
              DropdownMenuItem(value: 'hpj_update', child: Text('HPJ update')),
              DropdownMenuItem(value: 'new_arrival', child: Text('New arrival')),
              DropdownMenuItem(value: 'recipe', child: Text('Recipe')),
              DropdownMenuItem(value: 'nutrition', child: Text('Nutrition')),
              DropdownMenuItem(value: 'behind_the_scenes', child: Text('Behind the scenes')),
              DropdownMenuItem(value: 'promotion', child: Text('Promotion')),
              DropdownMenuItem(value: 'harvest', child: Text('Harvest')),
              DropdownMenuItem(value: 'farm_update', child: Text('Farm update')),
            ],
            onChanged: _submitting
                ? null
                : (value) => setState(() => _reelType = value ?? 'hpj_update'),
          ),
          const SizedBox(height: 12),
          _FreshReelPlacementSelector(
            selected: _placements,
            enabled: !_submitting,
            onChanged: (placement, selected) {
              setState(() {
                if (selected) {
                  _placements.add(placement);
                } else {
                  _placements.remove(placement);
                }
              });
            },
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<Product>>(
            future: _productsFuture,
            builder: (context, snapshot) {
              final products = (snapshot.data ?? const <Product>[])
                  .where(isVisibleCustomerProduct)
                  .toList();
              return DropdownButtonFormField<String>(
                value: _linkedProductId,
                decoration: const InputDecoration(
                  labelText: 'Linked produce (optional)',
                  helperText:
                      'Customers can add linked produce to My Box from the reel.',
                ),
                items: [
                  const DropdownMenuItem(
                    value: '',
                    child: Text('No linked product'),
                  ),
                  ...products.map(
                    (product) => DropdownMenuItem(
                      value: product.id,
                      child: Text(
                        product.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: _submitting
                    ? null
                    : (value) =>
                        setState(() => _linkedProductId = value ?? ''),
              );
            },
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: _submitting ? null : _submit,
            icon: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.publish_rounded),
            label: Text(_submitting ? 'Publishing...' : 'Publish Reel'),
          ),
        ],
      ),
    );
  }
}

class AdminFreshReelsTab extends StatefulWidget {
  final int refreshKey;
  final VoidCallback onChanged;

  const AdminFreshReelsTab({
    super.key,
    required this.refreshKey,
    required this.onChanged,
  });

  @override
  State<AdminFreshReelsTab> createState() => _AdminFreshReelsTabState();
}

class _AdminFreshReelsTabState extends State<AdminFreshReelsTab> {
  String _status = 'all';
  late Future<List<HpjFreshReel>> _future;

  @override
  void initState() {
    super.initState();
    _future = fetchAdminFreshReels(status: _status);
  }

  @override
  void didUpdateWidget(covariant AdminFreshReelsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshKey != widget.refreshKey) _reload();
  }

  void _reload() {
    if (!mounted) return;
    setState(() {
      _future = fetchAdminFreshReels(status: _status);
    });
  }

  Future<void> _createHpjReel() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const AdminFreshReelSubmissionScreen(),
      ),
    );
    if (created == true && mounted) {
      widget.onChanged();
      _reload();
    }
  }

  Future<void> _setStatus(HpjFreshReel reel, String status) async {
    String note = '';
    Set<String>? placementsToSave;

    if (status == 'rejected') {
      note = await _requestModerationNote() ?? '';
      if (!mounted) return;
      if (note.trim().isEmpty) return;
    }

    if (status == 'published' && reel.placements.isEmpty) {
      placementsToSave = await showFreshReelPlacementDialog(
        context,
        initial: _defaultPlacementsForReel(reel),
        title: 'Choose where this reel will show',
      );
      if (!mounted || placementsToSave == null) return;
    }

    try {
      if (placementsToSave != null) {
        await setFreshReelPlacements(
          reelId: reel.id,
          placements: placementsToSave,
        );
      }

      await moderateFreshReel(
        reelId: reel.id,
        status: status,
        moderationNote: note,
      );
      widget.onChanged();
      _reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'published' ? 'Reel published.' : 'Reel updated.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update reel: $error')),
      );
    }
  }

  Future<void> _editPlacements(HpjFreshReel reel) async {
    final next = await showFreshReelPlacementDialog(
      context,
      initial: reel.placements.isEmpty
          ? _defaultPlacementsForReel(reel)
          : reel.placements,
      title: 'Where should this reel show?',
    );
    if (!mounted || next == null) return;

    try {
      await setFreshReelPlacements(
        reelId: reel.id,
        placements: next,
      );
      widget.onChanged();
      _reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reel placements updated.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update placements: $error')),
      );
    }
  }

  Future<String?> _requestModerationNote() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rejection note'),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Tell the farmer what should be corrected.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Reject Reel'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<void> _toggleFeatured(HpjFreshReel reel) async {
    try {
      await setFreshReelFeatured(
        reelId: reel.id,
        isFeatured: !reel.isFeatured,
      );
      widget.onChanged();
      _reload();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update featured status: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        _reload();
        await _future;
      },
      child: FutureBuilder<List<HpjFreshReel>>(
        future: _future,
        builder: (context, snapshot) {
          final reels = snapshot.data ?? const <HpjFreshReel>[];
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
            children: [
              const Header(
                title: 'Fresh Reels',
                subtitle: 'Review farmer submissions and publish HPJ videos.',
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _createHpjReel,
                  icon: const Icon(Icons.video_call_outlined),
                  label: const Text('Create HPJ Reel'),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['all', 'pending', 'published', 'rejected', 'archived']
                    .map(
                      (status) => ChoiceChip(
                        label: Text(status == 'all'
                            ? 'All'
                            : '${status[0].toUpperCase()}${status.substring(1)}'),
                        selected: _status == status,
                        onSelected: (_) {
                          setState(() {
                            _status = status;
                            _future = fetchAdminFreshReels(status: status);
                          });
                        },
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 14),
              if (snapshot.connectionState == ConnectionState.waiting && reels.isEmpty)
                const Center(child: Padding(
                  padding: EdgeInsets.all(28),
                  child: CircularProgressIndicator(),
                ))
              else if (reels.isEmpty)
                const FarmCard(
                  child: Text('No reels in this queue.', style: TextStyle(fontWeight: FontWeight.w800)),
                )
              else
                ...reels.map(
                  (reel) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _AdminFreshReelCard(
                      reel: reel,
                      onPublish: () => _setStatus(reel, 'published'),
                      onReject: () => _setStatus(reel, 'rejected'),
                      onArchive: () => _setStatus(reel, 'archived'),
                      onFeature: () => _toggleFeatured(reel),
                      onPlacement: () => _editPlacements(reel),
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

class _AdminFreshReelCard extends StatelessWidget {
  final HpjFreshReel reel;
  final VoidCallback onPublish;
  final VoidCallback onReject;
  final VoidCallback onArchive;
  final VoidCallback onFeature;
  final VoidCallback onPlacement;

  const _AdminFreshReelCard({
    required this.reel,
    required this.onPublish,
    required this.onReject,
    required this.onArchive,
    required this.onFeature,
    required this.onPlacement,
  });

  @override
  Widget build(BuildContext context) {
    return FarmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: FarmColors.primarySoft,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.play_circle_outline_rounded, color: FarmColors.green),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reel.title,
                      style: const TextStyle(
                        color: FarmColors.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${reel.creatorLabel} • ${reel.typeLabel}',
                      style: const TextStyle(
                        color: FarmColors.mutedText,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      reel.status.toUpperCase(),
                      style: const TextStyle(
                        color: FarmColors.green,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Preview reel',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => FreshReelModerationPreviewScreen(reel: reel),
                  ),
                ),
                icon: const Icon(Icons.visibility_outlined),
              ),
            ],
          ),
          if (reel.caption.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              reel.caption,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: FarmColors.mutedText,
                fontSize: 11,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Icon(
                  Icons.place_outlined,
                  size: 17,
                  color: FarmColors.green,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: reel.placements.isEmpty
                    ? const Text(
                        'Placement not selected yet',
                        style: TextStyle(
                          color: FarmColors.warning,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      )
                    : Wrap(
                        spacing: 5,
                        runSpacing: 5,
                        children: _freshReelPlacementOrder
                            .where(reel.placements.contains)
                            .map(
                              (placement) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: FarmColors.primarySoft,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  freshReelPlacementLabel(placement),
                                  style: const TextStyle(
                                    color: FarmColors.green,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
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
                onPressed: onPlacement,
                icon: const Icon(Icons.place_outlined, size: 17),
                label: Text(
                  reel.placements.isEmpty ? 'Choose placement' : 'Placement',
                ),
              ),
              if (reel.status != 'published')
                ElevatedButton.icon(
                  onPressed: onPublish,
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 17),
                  label: const Text('Publish'),
                ),
              if (reel.status != 'rejected')
                OutlinedButton.icon(
                  onPressed: onReject,
                  icon: const Icon(Icons.close_rounded, size: 17),
                  label: const Text('Reject'),
                ),
              if (reel.status == 'published')
                OutlinedButton.icon(
                  onPressed: onFeature,
                  icon: Icon(reel.isFeatured ? Icons.star_rounded : Icons.star_border_rounded, size: 17),
                  label: Text(reel.isFeatured ? 'Unfeature' : 'Feature'),
                ),
              if (reel.status != 'archived')
                TextButton.icon(
                  onPressed: onArchive,
                  icon: const Icon(Icons.archive_outlined, size: 17),
                  label: const Text('Archive'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class FreshReelModerationPreviewScreen extends StatefulWidget {
  final HpjFreshReel reel;

  const FreshReelModerationPreviewScreen({
    super.key,
    required this.reel,
  });

  @override
  State<FreshReelModerationPreviewScreen> createState() =>
      _FreshReelModerationPreviewScreenState();
}

class _FreshReelModerationPreviewScreenState
    extends State<FreshReelModerationPreviewScreen> {
  VideoPlayerController? _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(widget.reel.videoUrl));
      await controller.initialize();
      await controller.setLooping(true);
      await controller.play();
      _controller = controller;
    } catch (_) {
      _failed = true;
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(widget.reel.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: Center(
        child: _failed
            ? const Text('Video preview unavailable.', style: TextStyle(color: Colors.white))
            : controller == null || !controller.value.isInitialized
                ? const CircularProgressIndicator(color: Colors.white)
                : AspectRatio(
                    aspectRatio: controller.value.aspectRatio == 0 ? 9 / 16 : controller.value.aspectRatio,
                    child: VideoPlayer(controller),
                  ),
      ),
      floatingActionButton: controller == null || !controller.value.isInitialized
          ? null
          : FloatingActionButton(
              onPressed: () async {
                if (controller.value.isPlaying) {
                  await controller.pause();
                } else {
                  await controller.play();
                }
                if (mounted) setState(() {});
              },
              child: Icon(controller.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
            ),
    );
  }
}
