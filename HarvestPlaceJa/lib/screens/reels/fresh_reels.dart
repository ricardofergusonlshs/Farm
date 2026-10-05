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
      return 'Farmer Home Feed';
    case freshReelPlacementWholesaleFeed:
      return 'Business Home Feed';
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
      return 'Show in the Farmer Home HPJ Feed.';
    case freshReelPlacementWholesaleFeed:
      return 'Show in the Business Home HPJ Feed.';
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

const List<String> _freshReelAdminTypeOrder = <String>[
  'farming_tip',
  'market_update',
  'hpj_update',
  'produce_opportunity',
  'farmer_story',
  'success_story',
  'farm_update',
  'harvest',
  'new_arrival',
  'behind_the_scenes',
  'recipe',
  'nutrition',
  'promotion',
  'general',
];

const List<String> _freshReelFarmerTypeOrder = <String>[
  'farm_update',
  'harvest',
  'new_arrival',
  'produce_opportunity',
  'farming_tip',
  'farmer_story',
  'success_story',
  'behind_the_scenes',
  'recipe',
  'general',
];

String freshReelTypeLabel(String reelType) {
  switch (reelType) {
    case 'farming_tip':
      return 'Farming tip';
    case 'market_update':
      return 'Market update';
    case 'hpj_update':
      return 'HPJ update';
    case 'produce_opportunity':
      return 'Produce opportunity';
    case 'farmer_story':
      return 'Farmer story';
    case 'success_story':
      return 'Success story';
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
    case 'promotion':
      return 'Promotion';
    case 'general':
      return 'General';
    default:
      return 'Farm update';
  }
}

String freshReelTypeDescription(String reelType) {
  switch (reelType) {
    case 'farming_tip':
      return 'Practical growing, harvesting or farm-management advice.';
    case 'market_update':
      return 'Official HPJ market-price, demand or seasonal market information.';
    case 'hpj_update':
      return 'Official HPJ announcement, collection notice or platform update.';
    case 'produce_opportunity':
      return 'A current buying, selling or supply opportunity involving produce.';
    case 'farmer_story':
      return 'A farmer, farm or day-in-the-field story.';
    case 'success_story':
      return 'A positive farmer, buyer or HPJ outcome worth highlighting.';
    case 'harvest':
      return 'A harvest that is ready, being picked or coming soon.';
    case 'new_arrival':
      return 'Fresh produce or a new product that has just become available.';
    case 'behind_the_scenes':
      return 'Behind-the-scenes farm, packing or HPJ activity.';
    case 'recipe':
      return 'Food preparation, serving or recipe content.';
    case 'nutrition':
      return 'Nutrition or healthy-eating information.';
    case 'promotion':
      return 'A promotional or sponsored reel.';
    case 'general':
      return 'General agriculture or HPJ content.';
    default:
      return 'A general update from the farm.';
  }
}

Set<String> recommendedFreshReelPlacementsForType(String reelType) {
  switch (reelType.trim().toLowerCase()) {
    case 'farming_tip':
      return <String>{
        freshReelPlacementViewer,
        freshReelPlacementFarmerFeed,
      };
    case 'market_update':
      return <String>{
        freshReelPlacementViewer,
        freshReelPlacementFarmerFeed,
        freshReelPlacementWholesaleFeed,
      };
    case 'hpj_update':
      return <String>{
        freshReelPlacementViewer,
        freshReelPlacementCustomerFeed,
        freshReelPlacementFarmerFeed,
        freshReelPlacementWholesaleFeed,
      };
    case 'produce_opportunity':
      return <String>{
        freshReelPlacementViewer,
        freshReelPlacementFarmerFeed,
        freshReelPlacementWholesaleFeed,
      };
    case 'farmer_story':
      return <String>{
        freshReelPlacementViewer,
        freshReelPlacementCustomerFeed,
        freshReelPlacementFarmerFeed,
      };
    case 'success_story':
      return <String>{
        freshReelPlacementViewer,
        freshReelPlacementCustomerFeed,
        freshReelPlacementFarmerFeed,
        freshReelPlacementWholesaleFeed,
      };
    case 'farm_update':
    case 'harvest':
    case 'behind_the_scenes':
      return <String>{
        freshReelPlacementViewer,
        freshReelPlacementCustomerFeed,
        freshReelPlacementFarmerFeed,
      };
    case 'new_arrival':
      return <String>{
        freshReelPlacementViewer,
        freshReelPlacementCustomerFeed,
        freshReelPlacementFarmerFeed,
        freshReelPlacementShop,
      };
    case 'recipe':
      return <String>{
        freshReelPlacementViewer,
        freshReelPlacementCustomerFeed,
        freshReelPlacementMealPlanner,
      };
    case 'nutrition':
      return <String>{
        freshReelPlacementViewer,
        freshReelPlacementCustomerFeed,
        freshReelPlacementFreshBox,
      };
    case 'promotion':
      return <String>{
        freshReelPlacementViewer,
        freshReelPlacementCustomerFeed,
        freshReelPlacementShop,
      };
    case 'general':
    default:
      return <String>{
        freshReelPlacementViewer,
        freshReelPlacementCustomerFeed,
      };
  }
}

Set<String> _defaultPlacementsForReel(HpjFreshReel reel) =>
    recommendedFreshReelPlacementsForType(reel.reelType);

class _FreshReelPlacementSelector extends StatelessWidget {
  final Set<String> selected;
  final bool enabled;
  final void Function(String placement, bool selected) onChanged;

  const _FreshReelPlacementSelector({
    required this.selected,
    required this.enabled,
    required this.onChanged,
  });

  static const _primaryPlacements = <String>[
    freshReelPlacementFarmerFeed,
    freshReelPlacementWholesaleFeed,
    freshReelPlacementCustomerFeed,
    freshReelPlacementViewer,
  ];

  static const _secondaryPlacements = <String>[
    freshReelPlacementShop,
    freshReelPlacementFreshBox,
    freshReelPlacementMealPlanner,
  ];

  Widget _placementRow(String placement) {
    final isSelected = selected.contains(placement);
    return InkWell(
      onTap: enabled ? () => onChanged(placement, !isSelected) : null,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Row(
          children: [
            SizedBox(
              width: 34,
              height: 34,
              child: Checkbox(
                value: isSelected,
                onChanged: enabled
                    ? (value) => onChanged(placement, value ?? false)
                    : null,
                activeColor: FarmColors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFEAF5E9)
                    : const Color(0xFFF5F6F4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                freshReelPlacementIcon(placement),
                size: 17,
                color: isSelected ? FarmColors.green : FarmColors.mutedText,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    freshReelPlacementLabel(placement),
                    style: const TextStyle(
                      color: FarmColors.ink,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    freshReelPlacementDescription(placement),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: FarmColors.mutedText,
                      fontSize: 8.8,
                      fontWeight: FontWeight.w600,
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

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFB65CE3),
          width: 2.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Show this Reel in *',
            style: TextStyle(
              color: FarmColors.ink,
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Select where this Reel will appear.',
            style: TextStyle(
              color: FarmColors.mutedText,
              fontSize: 9.3,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ..._primaryPlacements.map(_placementRow),
          const SizedBox(height: 5),
          ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 4),
            childrenPadding: EdgeInsets.zero,
            dense: true,
            visualDensity: VisualDensity.compact,
            title: const Text(
              'More HPJ destinations',
              style: TextStyle(
                color: FarmColors.deepGreen,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
            children: _secondaryPlacements.map(_placementRow).toList(),
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

Future<String?> showFreshReelCategoryDialog(
  BuildContext context, {
  required String initial,
}) async {
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => SimpleDialog(
      title: const Text('Choose Reel category'),
      children: _freshReelAdminTypeOrder
          .map(
            (type) => SimpleDialogOption(
              onPressed: () => Navigator.of(dialogContext).pop(type),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    child: Icon(
                      type == initial
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      size: 18,
                      color: type == initial
                          ? FarmColors.green
                          : FarmColors.mutedText,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          freshReelTypeLabel(type),
                          style: const TextStyle(
                            color: FarmColors.ink,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          freshReelTypeDescription(type),
                          style: const TextStyle(
                            color: FarmColors.mutedText,
                            fontSize: 10.5,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(growable: false),
    ),
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

  String get typeLabel => freshReelTypeLabel(reelType);

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
      <String>{
        'farm_update',
        'harvest',
        'new_arrival',
        'behind_the_scenes',
        'farming_tip',
        'market_update',
        'produce_opportunity',
        'farmer_story',
        'success_story',
        'general',
      }.contains(reel.reelType)) {
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
          (reel) =>
              cleanPlacement.isEmpty ||
              reel.placements.contains(cleanPlacement),
        )
        .take(limit)
        .toList();

    return reels;
  } catch (error) {
    farmDebugLog('Published Fresh Reels unavailable: $error');
    // Do not misrepresent an unavailable database, relation, or permission
    // error as a genuinely empty feed. The viewer will show a retry prompt.
    rethrow;
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
  final cleanReelId = reelId.trim();
  if (user == null || cleanReelId.isEmpty) return;
  try {
    await supabase.from('fresh_reel_views').upsert(
      {
        'reel_id': cleanReelId,
        'user_id': user.id,
        'viewed_on': DateTime.now().toIso8601String().substring(0, 10),
      },
      onConflict: 'reel_id,user_id,viewed_on',
      ignoreDuplicates: true,
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
    throw Exception(
        'Farmer verification must be approved before submitting reels.');
  }

  final cleanTitle = title.trim();
  if (cleanTitle.length < 3) {
    throw Exception('Add a short title for your reel.');
  }

  final cleanReelType = reelType.trim().toLowerCase();
  if (!_freshReelFarmerTypeOrder.contains(cleanReelType)) {
    throw Exception('Choose a valid Farmer Reel category.');
  }

  final bytes = await video.readAsBytes();
  if (bytes.isEmpty) throw Exception('The selected video is empty.');
  if (bytes.length > _freshReelMaxBytes) {
    throw Exception(
        'Keep Fresh Reels under 30 MB. Shorter videos upload faster.');
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
      'reel_type': cleanReelType,
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
  String status = 'published',
  XFile? coverImage,
  String? linkedProductId,
}) async {
  await requireAdminAccess();
  final user = supabase.auth.currentUser;
  if (user == null) throw Exception('Please sign in again.');

  final cleanTitle = title.trim();
  if (cleanTitle.length < 3) {
    throw Exception('Add a short title for your reel.');
  }

  final cleanReelType = reelType.trim().toLowerCase();
  if (!_freshReelAdminTypeOrder.contains(cleanReelType)) {
    throw Exception('Choose a valid HPJ Reel category.');
  }

  final cleanStatus = status.trim().toLowerCase();
  if (!const <String>{'published', 'pending'}.contains(cleanStatus)) {
    throw Exception('Choose Published or Draft.');
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

  String coverPath = '';
  String thumbnailUrl = '';
  if (coverImage != null) {
    final coverBytes = await coverImage.readAsBytes();
    if (coverBytes.isEmpty) {
      try {
        await supabase.storage.from(_freshReelsBucket).remove([path]);
      } catch (_) {}
      throw Exception('The selected Reel cover image is empty.');
    }
    if (coverBytes.length > 8 * 1024 * 1024) {
      try {
        await supabase.storage.from(_freshReelsBucket).remove([path]);
      } catch (_) {}
      throw Exception('Keep the Reel cover image under 8 MB.');
    }

    final coverName = _safeFreshReelFileName(coverImage.name);
    coverPath =
        'covers/${user.id}/${DateTime.now().microsecondsSinceEpoch}_$coverName';
    final lowerCoverName = coverImage.name.toLowerCase();
    final declaredCoverMime = (coverImage.mimeType ?? '').trim().toLowerCase();
    final coverMime = declaredCoverMime.startsWith('image/')
        ? declaredCoverMime
        : lowerCoverName.endsWith('.png')
            ? 'image/png'
            : lowerCoverName.endsWith('.webp')
                ? 'image/webp'
                : 'image/jpeg';

    try {
      await supabase.storage.from(_freshReelsBucket).uploadBinary(
            coverPath,
            coverBytes,
            fileOptions: FileOptions(
              contentType: coverMime,
              upsert: false,
            ),
          );
      thumbnailUrl =
          supabase.storage.from(_freshReelsBucket).getPublicUrl(coverPath);
    } catch (error) {
      try {
        await supabase.storage.from(_freshReelsBucket).remove([path]);
      } catch (_) {}
      rethrow;
    }
  }

  final cleanPlacements =
      placements.where(_freshReelPlacementOrder.contains).toSet();
  if (cleanPlacements.isEmpty) {
    try {
      final cleanup = <String>[path];
      if (coverPath.isNotEmpty) cleanup.add(coverPath);
      await supabase.storage.from(_freshReelsBucket).remove(cleanup);
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
          'thumbnail_url': thumbnailUrl,
          'linked_product_id': linkedProductId?.trim().isEmpty == true
              ? null
              : linkedProductId?.trim(),
          'reel_type': cleanReelType,
          'status': cleanStatus,
          if (cleanStatus == 'published')
            'published_at': DateTime.now().toIso8601String(),
          'is_featured': false,
          if (cleanStatus == 'published') 'moderated_by': user.id,
          if (cleanStatus == 'published')
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
      final cleanup = <String>[path];
      if (coverPath.isNotEmpty) cleanup.add(coverPath);
      await supabase.storage.from(_freshReelsBucket).remove(cleanup);
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

Future<void> setFreshReelType({
  required String reelId,
  required String reelType,
}) async {
  await requireAdminAccess();

  final cleanId = reelId.trim();
  final cleanType = reelType.trim().toLowerCase();
  if (cleanId.isEmpty) {
    throw Exception('Reel ID is missing.');
  }
  if (!_freshReelAdminTypeOrder.contains(cleanType)) {
    throw Exception('Choose a valid Reel category.');
  }

  await supabase.from('fresh_reels').update({
    'reel_type': cleanType,
    'updated_at': DateTime.now().toIso8601String(),
  }).eq('id', cleanId);
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
    'moderation_note':
        moderationNote.trim().isEmpty ? null : moderationNote.trim(),
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

Future<void> deleteFreshReelPermanently(HpjFreshReel reel) async {
  await requireAdminAccess();
  final role = normalizeStaffRole(await fetchCurrentStaffRole());
  if (role != 'owner') {
    throw Exception('Only Owner can permanently delete a Fresh Reel.');
  }
  if (!const <String>{'archived', 'rejected'}.contains(reel.status)) {
    throw Exception('Archive or reject the reel before permanent deletion.');
  }

  final deleted = await supabase
      .from('fresh_reels')
      .delete()
      .eq('id', reel.id)
      .select('id')
      .maybeSingle();
  if (deleted == null) {
    throw Exception('Reel was not deleted. Check Owner permissions.');
  }

  final storagePath = reel.storagePath.trim();
  if (storagePath.isNotEmpty) {
    try {
      await supabase.storage.from(_freshReelsBucket).remove([storagePath]);
    } catch (error) {
      // The database row is already gone. Keep deletion successful and log
      // storage cleanup separately so an orphan file never blocks Admin.
      farmDebugLog('Fresh Reel storage cleanup skipped: $error');
    }
  }
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

class _FreshReelFeedPreviewCardState extends State<FreshReelFeedPreviewCard> {
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
        if (snapshot.hasError) {
          return _HpjInlineRetryState(
            title: 'Fresh Reels unavailable',
            message: 'Videos could not be loaded. Tap Retry to check again.',
            onRetry: () {
              if (mounted) setState(() => _future = _load());
            },
          );
        }
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

  bool get _dataSaver => widget.preferences.feedImageMode == 'data_saver';

  bool get _autoplay => widget.preferences.reelsAutoplay && !_dataSaver;

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

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFDDE6DA),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _openReel,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                          size: 48,
                          shadows: [
                            Shadow(
                              color: Colors.black45,
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                    Positioned(
                      top: 9,
                      left: 9,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(.55),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          widget.reel.typeLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8.7,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 10,
                      right: 10,
                      bottom: 8,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.reel.creatorLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                shadows: [
                                  Shadow(
                                    color: Colors.black54,
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            width: 30,
                            height: 30,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(.92),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: FarmColors.primary,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 11),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.reel.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: FarmColors.ink,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (widget.reel.caption.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              widget.reel.caption,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                    const SizedBox(width: 10),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.visibility_outlined,
                          size: 14,
                          color: FarmColors.mutedText,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${widget.reel.viewCount}',
                          style: const TextStyle(
                            color: FarmColors.mutedText,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 9),
                        const Icon(
                          Icons.favorite_border_rounded,
                          size: 14,
                          color: FarmColors.mutedText,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '${widget.reel.likeCount}',
                          style: const TextStyle(
                            color: FarmColors.mutedText,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (customerView &&
                  product != null &&
                  product.canAddToCart &&
                  widget.onAddToCart != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 11),
                  child: SizedBox(
                    width: double.infinity,
                    height: 38,
                    child: FilledButton.icon(
                      onPressed: () => widget.onAddToCart!(product),
                      icon: const Icon(
                        Icons.add_shopping_cart_rounded,
                        size: 16,
                      ),
                      label: const Text('Add to Box'),
                      style: FilledButton.styleFrom(
                        backgroundColor: FarmColors.green,
                        foregroundColor: Colors.white,
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
}

class HpjFreshReelsEntryScreen extends StatelessWidget {
  final ValueChanged<Product>? onAddToCart;
  final String initialReelId;
  final String placement;

  const HpjFreshReelsEntryScreen({
    super.key,
    this.onAddToCart,
    this.initialReelId = '',
    this.placement = freshReelPlacementViewer,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserExperiencePreferences>(
      future: fetchCurrentUserExperiencePreferences(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFF7F9F5),
            body: SafeArea(
              child: Center(
                child: CircularProgressIndicator(
                  color: FarmColors.primary,
                ),
              ),
            ),
          );
        }
        return FreshReelsScreen(
          preferences: snapshot.data ?? UserExperiencePreferences.defaults,
          onAddToCart: onAddToCart,
          initialReelId: initialReelId,
          placement: placement,
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
    // Browser autoplay is much more reliable when reels start muted.
    // On Flutter Web we also require a user tap before playback starts.
    _muted = kIsWeb ? true : widget.preferences.reelsMutedByDefault;
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
      appBar: kIsWeb
          ? AppBar(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                tooltip: 'Back',
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              title: const Text(
                'HPJ Feed',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            )
          : null,
      body: SafeArea(
        top: !kIsWeb,
        child: FutureBuilder<List<HpjFreshReel>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: FarmColors.primary),
              );
            }

            if (snapshot.hasError) {
              return _FreshReelsEmptyState(
                onRefresh: _refresh,
                message: 'Could not load videos. Check your connection and '
                    'the Fresh Reels database setup, then try again.',
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
                      // Flutter Web browsers can block programmatic video
                      // playback. Let the user tap the reel to start it there.
                      autoplay: !kIsWeb &&
                          widget.preferences.reelsAutoplay &&
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
                if (!kIsWeb)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: _ReelCircleButton(
                      icon: Icons.arrow_back_rounded,
                      tooltip: 'Back',
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                if (!kIsWeb)
                  Positioned(
                    top: 8,
                    left: 58,
                    right: 58,
                    child: IgnorePointer(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(.94),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white.withOpacity(.78),
                              ),
                            ),
                            child: Image.asset(
                              'lib/assets/images/logo.png',
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.eco_rounded,
                                color: FarmColors.primary,
                                size: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'HPJ Feed',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 8,
                                      color: Colors.black54,
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${_activeIndex + 1} of ${reels.length}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
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
  final String? message;

  const _FreshReelsEmptyState({
    required this.onRefresh,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = (message ?? '').trim().isNotEmpty;

    return ColoredBox(
      color: const Color(0xFFF7F9F5),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: FarmColors.ink,
                    ),
                  ),
                  Container(
                    width: 38,
                    height: 38,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(
                        color: const Color(0xFFDDE6DA),
                      ),
                    ),
                    child: Image.asset(
                      'lib/assets/images/logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.eco_rounded,
                        color: FarmColors.primary,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'HPJ Feed',
                          style: TextStyle(
                            color: FarmColors.ink,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 1),
                        Text(
                          'Fresh from Jamaican farms',
                          style: TextStyle(
                            color: FarmColors.mutedText,
                            fontSize: 8.7,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 440),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFDDE6DA),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 62,
                          height: 62,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEAF3E6),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            hasError
                                ? Icons.refresh_rounded
                                : Icons.play_arrow_rounded,
                            color: FarmColors.primary,
                            size: 34,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          hasError ? 'Feed unavailable' : 'No reels yet',
                          style: const TextStyle(
                            color: FarmColors.ink,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hasError
                              ? message!
                              : 'New farm videos, harvests and HPJ updates will appear here.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: FarmColors.mutedText,
                            fontSize: 9.2,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 40,
                          child: FilledButton.icon(
                            onPressed: () => onRefresh(),
                            icon: const Icon(
                              Icons.refresh_rounded,
                              size: 17,
                            ),
                            label: Text(
                              hasError ? 'Try again' : 'Refresh feed',
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: FarmColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FreshFeedTypeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color background;

  const _FreshFeedTypeCard({
    required this.icon,
    required this.label,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFE1E8DE),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: FarmColors.primary,
            size: 22,
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(
              color: FarmColors.ink,
              fontSize: 9.2,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
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
      await controller.initialize().timeout(const Duration(seconds: 15));
      if (!mounted) {
        await controller.dispose();
        return;
      }
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
          likeCount: (widget.reel.likeCount + (next ? 1 : -1))
              .clamp(0, 999999)
              .toInt(),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', ''))),
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
      ..write(
          'Watch fresh Jamaican farm content on ${AppConfig.appName}: ${AppConfig.shareableAppLink}');
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
    final creator = widget.reel.creatorLabel.trim().isEmpty
        ? 'The Harvest Place Ja'
        : widget.reel.creatorLabel.trim();

    final captionText = widget.reel.caption.trim().isNotEmpty
        ? widget.reel.caption.trim()
        : widget.reel.title.trim();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _togglePlayback,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: Colors.black),

          if (_loading)
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          else if (_videoFailed ||
              controller == null ||
              !controller.value.isInitialized)
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
                colors: [
                  Color(0x66000000),
                  Colors.transparent,
                  Colors.transparent,
                  Color(0xDD000000),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0, .20, .55, 1],
              ),
            ),
          ),

          // Right-side reel actions.
          Positioned(
            right: 12,
            bottom: canShop ? 178 : 118,
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

          // Creator + caption area.
          Positioned(
            left: 14,
            right: 72,
            bottom: canShop ? 112 : 48,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 1.5,
                        ),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'lib/assets/images/logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.eco_rounded,
                            color: FarmColors.primary,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        creator,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13.2,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (widget.reel.isFeatured)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.18),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withOpacity(.55),
                          ),
                        ),
                        child: const Text(
                          'FEATURED',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 7.2,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 9),
                if (captionText.isNotEmpty)
                  Text(
                    captionText,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.2,
                      height: 1.25,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                const SizedBox(height: 7),
                Row(
                  children: [
                    const Icon(
                      Icons.music_note_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Original sound • $creator',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(.90),
                          fontSize: 9.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Product action remains when a linked product can be bought.
          if (canShop)
            Positioned(
              left: 14,
              right: 14,
              bottom: 42,
              child: _ReelProductBar(
                product: product,
                onAdd: _addProduct,
              ),
            ),

          // Video progress bar across the bottom.
          if (!_loading &&
              !_videoFailed &&
              controller != null &&
              controller.value.isInitialized)
            Positioned(
              left: 14,
              right: 14,
              bottom: 12,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: VideoProgressIndicator(
                  controller,
                  allowScrubbing: true,
                  padding: EdgeInsets.zero,
                  colors: const VideoProgressColors(
                    playedColor: Colors.white,
                    bufferedColor: Colors.white38,
                    backgroundColor: Colors.white24,
                  ),
                ),
              ),
            ),

          if (!_loading &&
              !_videoFailed &&
              controller != null &&
              controller.value.isInitialized &&
              !controller.value.isPlaying)
            Center(
              child: Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(.42),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(.75),
                    width: 1.4,
                  ),
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 44,
                ),
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
        child:
            Icon(Icons.videocam_off_outlined, color: Colors.white70, size: 58),
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
          BoxShadow(
              color: Colors.black26, blurRadius: 18, offset: Offset(0, 8)),
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
        builder: (_) =>
            FarmerFreshReelSubmissionScreen(profile: widget.profile),
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
            if (snapshot.connectionState == ConnectionState.waiting &&
                reels.isEmpty) {
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
                child: Icon(Icons.play_circle_outline_rounded,
                    color: _statusColor),
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
                    builder: (_) =>
                        FreshReelModerationPreviewScreen(reel: reel),
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
                Text('${reel.viewCount} views',
                    style: const TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w700)),
                Text('${reel.likeCount} likes',
                    style: const TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w700)),
                Text('${reel.shareCount} shares',
                    style: const TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w700)),
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
        SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', ''))),
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
            title: 'Create a Farmer Reel',
            subtitle:
                'Choose the Reel type so viewers immediately know what the video is about. HPJ reviews Farmer Reels before publishing.',
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
              hintText: 'Tell farmers and buyers what they are seeing.',
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _reelType,
            decoration: InputDecoration(
              labelText: 'What kind of Reel is this?',
              helperText: freshReelTypeDescription(_reelType),
              helperMaxLines: 2,
            ),
            items: _freshReelFarmerTypeOrder
                .map(
                  (type) => DropdownMenuItem<String>(
                    value: type,
                    child: Text(freshReelTypeLabel(type)),
                  ),
                )
                .toList(growable: false),
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
                  labelText: 'Link produce (optional)',
                  helperText: 'Customers can add this produce from the reel.',
                ),
                items: [
                  const DropdownMenuItem(
                      value: '', child: Text('No linked product')),
                  ...products.map(
                    (product) => DropdownMenuItem(
                      value: product.id,
                      child:
                          Text(product.name, overflow: TextOverflow.ellipsis),
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
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.send_rounded),
            label: Text(_submitting ? 'Uploading...' : 'Submit for review'),
          ),
        ],
      ),
    );
  }
}

class _HpjAdminSelectedVideoPreview extends StatefulWidget {
  final XFile? video;

  const _HpjAdminSelectedVideoPreview({
    required this.video,
  });

  @override
  State<_HpjAdminSelectedVideoPreview> createState() =>
      _HpjAdminSelectedVideoPreviewState();
}

class _HpjAdminSelectedVideoPreviewState
    extends State<_HpjAdminSelectedVideoPreview> {
  VideoPlayerController? _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void didUpdateWidget(covariant _HpjAdminSelectedVideoPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.video?.path != widget.video?.path) {
      _controller?.dispose();
      _controller = null;
      _failed = false;
      unawaited(_load());
    }
  }

  Future<void> _load() async {
    final video = widget.video;
    if (video == null || !kIsWeb) {
      if (mounted) setState(() {});
      return;
    }

    try {
      final uri = Uri.parse(video.path);
      final controller = VideoPlayerController.networkUrl(uri);
      await controller.initialize();
      await controller.setLooping(true);
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
    final hasVideo = widget.video != null;

    return AspectRatio(
      aspectRatio: 9 / 13,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (controller != null && controller.value.isInitialized)
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: controller.value.size.width,
                  height: controller.value.size.height,
                  child: VideoPlayer(controller),
                ),
              )
            else
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF315E3A), Color(0xFF91B86D)],
                  ),
                ),
              ),
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x10000000),
                      Color(0x00000000),
                      Color(0x8F000000),
                    ],
                  ),
                ),
              ),
            ),
            Center(
              child: Material(
                color: Colors.white.withOpacity(.90),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: controller == null || !controller.value.isInitialized
                      ? null
                      : () async {
                          if (controller.value.isPlaying) {
                            await controller.pause();
                          } else {
                            await controller.play();
                          }
                          if (mounted) setState(() {});
                        },
                  child: SizedBox(
                    width: 58,
                    height: 58,
                    child: Icon(
                      controller?.value.isPlaying == true
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: FarmColors.deepGreen,
                      size: 38,
                    ),
                  ),
                ),
              ),
            ),
            if (!hasVideo)
              const Positioned(
                left: 16,
                right: 16,
                bottom: 18,
                child: Text(
                  'Choose a Reel video to preview it here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              )
            else
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Text(
                  widget.video!.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9.5,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            if (_failed)
              const Positioned(
                right: 9,
                top: 9,
                child: Tooltip(
                  message:
                      'Live preview unavailable. The selected file can still be published.',
                  child: Icon(
                    Icons.info_outline_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HpjReelAdminTopTabs extends StatelessWidget {
  final bool createSelected;
  final VoidCallback? onAll;
  final VoidCallback? onCreate;
  final VoidCallback? onPending;

  const _HpjReelAdminTopTabs({
    required this.createSelected,
    this.onAll,
    this.onCreate,
    this.onPending,
  });

  Widget _tab({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback? onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? FarmColors.green : Colors.transparent,
              width: 2.5,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? FarmColors.green : FarmColors.mutedText,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? FarmColors.deepGreen : FarmColors.mutedText,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 7),
              trailing,
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8DF)),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _tab(
              label: 'All Reels',
              icon: Icons.video_library_outlined,
              selected: !createSelected,
              onTap: onAll,
            ),
            _tab(
              label: 'Create Reel',
              icon: Icons.video_call_outlined,
              selected: createSelected,
              onTap: onCreate,
            ),
            FutureBuilder<List<HpjFreshReel>>(
              future: fetchAdminFreshReels(status: 'pending'),
              builder: (context, snapshot) {
                final count = (snapshot.data ?? const <HpjFreshReel>[])
                    .where((reel) => reel.creatorRole == 'farmer')
                    .length;
                return _tab(
                  label: 'Pending (Farmer)',
                  icon: Icons.agriculture_outlined,
                  selected: false,
                  onTap: onPending,
                  trailing: count <= 0
                      ? null
                      : Container(
                          constraints: const BoxConstraints(minWidth: 22),
                          height: 22,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: const BoxDecoration(
                            color: Color(0xFFE91E4D),
                            borderRadius: BorderRadius.all(Radius.circular(99)),
                          ),
                          child: Text(
                            '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                );
              },
            ),
          ],
        ),
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
  XFile? _coverImage;
  String _reelType = 'hpj_update';
  String _linkedProductId = '';
  String _status = 'published';
  final Set<String> _placements =
      recommendedFreshReelPlacementsForType('hpj_update');
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

  Future<void> _pickCoverImage() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 88,
    );
    if (picked == null || !mounted) return;
    setState(() => _coverImage = picked);
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
          content: Text('Choose at least one place for this Reel to appear.'),
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
        status: _status,
        coverImage: _coverImage,
        linkedProductId: _linkedProductId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _status == 'published'
                ? 'HPJ Reel published.'
                : 'HPJ Reel saved to the pending queue.',
          ),
        ),
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

  Widget _categoryField() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFFFC400),
          width: 2.2,
        ),
      ),
      child: DropdownButtonFormField<String>(
        value: _reelType,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: 'Reel Category *',
          helperText: freshReelTypeDescription(_reelType),
          helperMaxLines: 2,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
        ),
        items: _freshReelAdminTypeOrder
            .map(
              (type) => DropdownMenuItem<String>(
                value: type,
                child: Row(
                  children: [
                    const Icon(
                      Icons.eco_rounded,
                      size: 17,
                      color: FarmColors.green,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        freshReelTypeLabel(type),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(growable: false),
        onChanged: _submitting
            ? null
            : (value) {
                final nextType = value ?? 'hpj_update';
                setState(() {
                  _reelType = nextType;
                  _placements
                    ..clear()
                    ..addAll(
                      recommendedFreshReelPlacementsForType(nextType),
                    );
                });
              },
      ),
    );
  }

  Widget _statusField() {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF37AEE2),
          width: 2.2,
        ),
      ),
      child: DropdownButtonFormField<String>(
        value: _status,
        decoration: InputDecoration(
          labelText: 'Status *',
          helperText: _status == 'published'
              ? 'Reel will be visible immediately in selected feeds.'
              : 'Save it for review before making it visible.',
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
        ),
        items: const [
          DropdownMenuItem(
            value: 'published',
            child: Text('Published'),
          ),
          DropdownMenuItem(
            value: 'pending',
            child: Text('Draft / Pending'),
          ),
        ],
        onChanged: _submitting
            ? null
            : (value) => setState(() => _status = value ?? 'published'),
      ),
    );
  }

  Widget _formFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _titleController,
          maxLength: 80,
          decoration: const InputDecoration(
            labelText: 'Title *',
            hintText: 'e.g. How to improve cucumber yield',
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _captionController,
          maxLength: 280,
          minLines: 3,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Description',
            hintText:
                'Tell farmers or buyers what they will learn from this Reel.',
          ),
        ),
        const SizedBox(height: 10),
        _categoryField(),
        const SizedBox(height: 11),
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
        const SizedBox(height: 11),
        _statusField(),
        const SizedBox(height: 11),
        FutureBuilder<List<Product>>(
          future: _productsFuture,
          builder: (context, snapshot) {
            final products = (snapshot.data ?? const <Product>[])
                .where(isVisibleCustomerProduct)
                .toList();
            return DropdownButtonFormField<String>(
              value: _linkedProductId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Linked produce (optional)',
                helperText:
                    'Use when this Reel is about a specific HPJ product.',
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
                  : (value) => setState(() => _linkedProductId = value ?? ''),
            );
          },
        ),
      ],
    );
  }

  Widget _videoPanel() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FBF8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDDE6DA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HpjAdminSelectedVideoPreview(video: _video),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _submitting ? null : _pickVideo,
            icon: const Icon(Icons.video_camera_back_outlined),
            label: Text(_video == null ? 'Choose Video' : 'Change Video'),
          ),
          const SizedBox(height: 7),
          TextButton.icon(
            onPressed: _submitting ? null : _pickCoverImage,
            icon: const Icon(Icons.image_outlined, size: 17),
            label: Text(
              _coverImage == null ? 'Add Reel Cover' : 'Change Reel Cover',
            ),
          ),
          if (_coverImage != null)
            Text(
              _coverImage!.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: FarmColors.mutedText,
                fontSize: 8.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          const SizedBox(height: 5),
          const Text(
            'Max 60 seconds • MP4, MOV or WebM • under 30 MB',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: FarmColors.mutedText,
              fontSize: 8.7,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 850;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          tooltip: 'Back to Reels',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.eco_rounded, color: FarmColors.green, size: 21),
            SizedBox(width: 8),
            Text('HPJ Admin  ›  Fresh Reels'),
          ],
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1040),
            child: Column(
              children: [
                _HpjReelAdminTopTabs(
                  createSelected: true,
                  onAll: () => Navigator.of(context).maybePop(),
                  onCreate: null,
                  onPending: () => Navigator.of(context).maybePop(),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 28),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFDDE5DA)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x11000000),
                            blurRadius: 18,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: Color(0xFFEAF5E9),
                                child: Icon(
                                  Icons.video_camera_back_outlined,
                                  color: FarmColors.green,
                                  size: 21,
                                ),
                              ),
                              SizedBox(width: 11),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Create HPJ Reel',
                                      style: TextStyle(
                                        color: FarmColors.ink,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Share updates, tips, opportunities and stories with farmers, businesses and customers.',
                                      style: TextStyle(
                                        color: FarmColors.mutedText,
                                        fontSize: 10.5,
                                        height: 1.3,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          const Divider(height: 1),
                          const SizedBox(height: 15),
                          if (wide)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 245,
                                  child: _videoPanel(),
                                ),
                                const SizedBox(width: 18),
                                Expanded(child: _formFields()),
                              ],
                            )
                          else ...[
                            _videoPanel(),
                            const SizedBox(height: 15),
                            _formFields(),
                          ],
                          const SizedBox(height: 16),
                          const Divider(height: 1),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Wrap(
                              spacing: 10,
                              runSpacing: 8,
                              children: [
                                OutlinedButton(
                                  onPressed: _submitting
                                      ? null
                                      : () => Navigator.of(context).maybePop(),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton.icon(
                                  onPressed: _submitting ? null : _submit,
                                  icon: _submitting
                                      ? const SizedBox(
                                          width: 17,
                                          height: 17,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.cloud_upload_outlined),
                                  label: Text(
                                    _submitting
                                        ? 'Saving…'
                                        : _status == 'published'
                                            ? 'Create Reel'
                                            : 'Save Draft',
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
              ],
            ),
          ),
        ),
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
      // Refresh this queue without recreating the parent Admin shell.
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
      // Refresh this queue without recreating the parent Admin shell.
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

  Future<void> _editCategory(HpjFreshReel reel) async {
    final next = await showFreshReelCategoryDialog(
      context,
      initial: reel.reelType,
    );
    if (!mounted || next == null || next == reel.reelType) return;

    try {
      await setFreshReelType(
        reelId: reel.id,
        reelType: next,
      );

      if (reel.placements.isEmpty) {
        await setFreshReelPlacements(
          reelId: reel.id,
          placements: recommendedFreshReelPlacementsForType(next),
        );
      }

      _reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Reel category changed to ${freshReelTypeLabel(next)}.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update Reel category: $error')),
      );
    }
  }

  Future<void> _editPlacements(HpjFreshReel reel) async {
    final next = await showFreshReelPlacementDialog(
      context,
      initial: reel.placements.isEmpty
          ? _defaultPlacementsForReel(reel)
          : reel.placements,
      title: 'Show this reel in',
    );
    if (!mounted || next == null) return;

    try {
      await setFreshReelPlacements(
        reelId: reel.id,
        placements: next,
      );
      // Refresh this queue without recreating the parent Admin shell.
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

  Future<void> _deletePermanently(HpjFreshReel reel) async {
    if (!const <String>{'archived', 'rejected'}.contains(reel.status)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Archive or reject the reel before deleting it.')),
      );
      return;
    }

    final role = normalizeStaffRole(await fetchCurrentStaffRole());
    if (!mounted) return;
    if (role != 'owner') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Only Owner can permanently delete reels. Managers can archive them.'),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Permanently delete reel?'),
        content: Text(
          '“${reel.title}” and its placements, likes and view history will be permanently removed. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: FarmColors.error),
            child: const Text('Delete permanently'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await deleteFreshReelPermanently(reel);
      _reload();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fresh Reel permanently deleted.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete reel: $error')),
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
      // Refresh this queue without recreating the parent Admin shell.
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
                title: 'HPJ Feed & Fresh Reels',
                subtitle:
                    'Create, categorize, route and moderate the videos shown across Customer, Farmer and Business feeds.',
              ),
              const SizedBox(height: 10),
              _HpjReelAdminTopTabs(
                createSelected: false,
                onAll: () {
                  setState(() {
                    _status = 'all';
                    _future = fetchAdminFreshReels(status: 'all');
                  });
                },
                onCreate: _createHpjReel,
                onPending: () {
                  setState(() {
                    _status = 'pending';
                    _future = fetchAdminFreshReels(status: 'pending');
                  });
                },
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    ['all', 'pending', 'published', 'rejected', 'archived']
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
              if (snapshot.connectionState == ConnectionState.waiting &&
                  reels.isEmpty)
                const Center(
                    child: Padding(
                  padding: EdgeInsets.all(28),
                  child: CircularProgressIndicator(),
                ))
              else if (snapshot.hasError)
                FarmCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Could not load reels. Check the database setup and permissions.',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _reload,
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              else if (reels.isEmpty)
                const FarmCard(
                  child: Text('No reels in this queue.',
                      style: TextStyle(fontWeight: FontWeight.w800)),
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
                      onDelete: () => _deletePermanently(reel),
                      onFeature: () => _toggleFeatured(reel),
                      onCategory: () => _editCategory(reel),
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
  final VoidCallback onDelete;
  final VoidCallback onFeature;
  final VoidCallback onCategory;
  final VoidCallback onPlacement;

  const _AdminFreshReelCard({
    required this.reel,
    required this.onPublish,
    required this.onReject,
    required this.onArchive,
    required this.onDelete,
    required this.onFeature,
    required this.onCategory,
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
                child: const Icon(Icons.play_circle_outline_rounded,
                    color: FarmColors.green),
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
                    builder: (_) =>
                        FreshReelModerationPreviewScreen(reel: reel),
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
                onPressed: onCategory,
                icon: const Icon(Icons.label_outline_rounded, size: 17),
                label: const Text('Category'),
              ),
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
                  icon:
                      const Icon(Icons.check_circle_outline_rounded, size: 17),
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
                  icon: Icon(
                      reel.isFeatured
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      size: 17),
                  label: Text(reel.isFeatured ? 'Unfeature' : 'Feature'),
                ),
              if (reel.status != 'archived')
                TextButton.icon(
                  onPressed: onArchive,
                  icon: const Icon(Icons.archive_outlined, size: 17),
                  label: const Text('Archive'),
                ),
              if (const <String>{'archived', 'rejected'}.contains(reel.status))
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(
                    Icons.delete_forever_outlined,
                    size: 17,
                    color: FarmColors.error,
                  ),
                  label: const Text(
                    'Delete',
                    style: TextStyle(color: FarmColors.error),
                  ),
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
      final controller =
          VideoPlayerController.networkUrl(Uri.parse(widget.reel.videoUrl));
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
        title: Text(widget.reel.title,
            maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: Center(
        child: _failed
            ? const Text('Video preview unavailable.',
                style: TextStyle(color: Colors.white))
            : controller == null || !controller.value.isInitialized
                ? const CircularProgressIndicator(color: Colors.white)
                : AspectRatio(
                    aspectRatio: controller.value.aspectRatio == 0
                        ? 9 / 16
                        : controller.value.aspectRatio,
                    child: VideoPlayer(controller),
                  ),
      ),
      floatingActionButton:
          controller == null || !controller.value.isInitialized
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
                  child: Icon(controller.value.isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded),
                ),
    );
  }
}
