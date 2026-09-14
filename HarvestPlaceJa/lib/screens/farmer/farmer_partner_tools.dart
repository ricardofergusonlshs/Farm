// HPJ PHASE 99–101 — TRUE FARM STORIES + FOLLOW FRESH + SMART NEAR YOU
// HPJ PHASE 98 — SMART MATCHING / FARMER MATCHED OPPORTUNITIES
// HPJ PHASE 93 — HARVEST DROP + OPERATIONAL GROW SIGNAL LINK
// HPJ PHASE 92 — HARVEST JOURNEY + RESCUE WATCH
part of harvest_place_app;
// HPJ PHASE 97 — GROW INTELLIGENCE + JAMAICA DEMAND MAP
// HPJ PHASE 96 — FARM STORY IMPACT
// HPJ PHASE 91 — GROWTOGETHER FARMER GROW SIGNALS
// HPJ PHASE 90 — MEAL PULSE SOFT DEMAND SIGNAL FOR FARMERS
// HPJ PHASE 59C — EMBEDDABLE FARMER DEMAND FOR WEB PORTAL
// HPJ PHASE 13 COMPILE COMPATIBILITY FIX — notification-focused Demand/Collections restored
// HPJ PREMIUM PHASE 13 — FARMER OPERATIONS / ORDERS / PAYMENTS / ACTIVITY
// HPJ PREMIUM PHASE 11 — FARMER DEMAND UI UPGRADE

// ============================================================================
// HPJ RELEASE CANDIDATE — FARMER PARTNER TOOLS
//
// Adds farmer-facing visibility into aggregated wholesale demand and the
// farmer's own HPJ collection schedule. It deliberately reuses the existing
// farmer supply workflow: "I Can Supply" creates a normal farmer supply report
// that HPJ staff can review/confirm in the existing Matching workflow.
// ============================================================================

class FarmerMarketDemandOpportunity {
  final String productName;
  final String unit;
  final int horizonDays;
  final double approvedDemand;
  final double planningDemand;
  final double standingDemand;
  final double visibleDemand;
  final double myReportedSupply;
  final double myHpjConfirmedSupply;
  final double opportunityGap;
  final DateTime? nextNeedBy;
  final String demandSignal;

  const FarmerMarketDemandOpportunity({
    required this.productName,
    required this.unit,
    required this.horizonDays,
    required this.approvedDemand,
    required this.planningDemand,
    required this.standingDemand,
    required this.visibleDemand,
    required this.myReportedSupply,
    required this.myHpjConfirmedSupply,
    required this.opportunityGap,
    required this.nextNeedBy,
    required this.demandSignal,
  });

  factory FarmerMarketDemandOpportunity.fromSupabase(
    Map<String, dynamic> data,
  ) {
    double number(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    return FarmerMarketDemandOpportunity(
      productName: (data['product_name'] ?? 'Produce').toString().trim(),
      unit: (data['unit'] ?? 'unit').toString().trim(),
      horizonDays: (data['horizon_days'] is num)
          ? (data['horizon_days'] as num).toInt()
          : int.tryParse((data['horizon_days'] ?? '').toString()) ?? 30,
      approvedDemand: number(data['approved_demand']),
      planningDemand: number(data['planning_demand']),
      standingDemand: number(data['standing_demand']),
      visibleDemand: number(data['visible_demand']),
      myReportedSupply: number(data['my_reported_supply']),
      myHpjConfirmedSupply: number(data['my_hpj_confirmed_supply']),
      opportunityGap: number(data['opportunity_gap']),
      nextNeedBy: parseProductDate(data['next_need_by']),
      demandSignal:
          (data['demand_signal'] ?? 'watch').toString().trim().toLowerCase(),
    );
  }

  String get signalLabel {
    switch (demandSignal) {
      case 'committed_need':
        return 'Committed Need';
      case 'urgent':
        return 'Needed Soon';
      case 'opportunity':
        return 'Opportunity';
      case 'covered_by_you':
        return 'Covered by Your Supply';
      default:
        return 'Watch';
    }
  }
}

class FarmerCollectionScheduleItem {
  final String id;
  final DateTime collectionDate;
  final String runStatus;
  final String stopStatus;
  final String productName;
  final double plannedQuantity;
  final double collectedQuantity;
  final String unit;
  final int sequenceNo;
  final String driverName;
  final String vehicleLabel;
  final String collectionMethod;
  final String receivingStatus;
  final String qualityGrade;
  final String note;

  const FarmerCollectionScheduleItem({
    required this.id,
    required this.collectionDate,
    required this.runStatus,
    required this.stopStatus,
    required this.productName,
    required this.plannedQuantity,
    required this.collectedQuantity,
    required this.unit,
    required this.sequenceNo,
    required this.driverName,
    required this.vehicleLabel,
    required this.collectionMethod,
    required this.receivingStatus,
    required this.qualityGrade,
    required this.note,
  });

  factory FarmerCollectionScheduleItem.fromSupabase(
    Map<String, dynamic> data,
  ) {
    double number(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    return FarmerCollectionScheduleItem(
      id: (data['collection_stop_id'] ?? '').toString(),
      collectionDate:
          parseProductDate(data['collection_date']) ?? DateTime.now(),
      runStatus: (data['run_status'] ?? '').toString().trim().toLowerCase(),
      stopStatus: (data['stop_status'] ?? '').toString().trim().toLowerCase(),
      productName: (data['product_name'] ?? 'Produce').toString().trim(),
      plannedQuantity: number(data['planned_quantity']),
      collectedQuantity: number(data['collected_quantity']),
      unit: (data['unit'] ?? 'unit').toString().trim(),
      sequenceNo: (data['sequence_no'] is num)
          ? (data['sequence_no'] as num).toInt()
          : int.tryParse((data['sequence_no'] ?? '').toString()) ?? 0,
      driverName: (data['driver_name'] ?? '').toString().trim(),
      vehicleLabel: (data['vehicle_label'] ?? '').toString().trim(),
      collectionMethod:
          (data['collection_method'] ?? '').toString().trim().toLowerCase(),
      receivingStatus:
          (data['receiving_status'] ?? '').toString().trim().toLowerCase(),
      qualityGrade: (data['quality_grade'] ?? '').toString().trim(),
      note: (data['note'] ?? '').toString().trim(),
    );
  }
}

Future<List<FarmerMarketDemandOpportunity>> fetchFarmerMarketDemandBoard(
  int horizonDays,
) async {
  final response = await supabase.rpc(
    'farmer_market_demand_board',
    params: {'p_horizon_days': horizonDays},
  );

  return (response as List)
      .map(
        (row) => FarmerMarketDemandOpportunity.fromSupabase(
          Map<String, dynamic>.from(row as Map),
        ),
      )
      .toList();
}

Future<List<FarmerCollectionScheduleItem>>
    fetchFarmerCollectionSchedule() async {
  final response = await supabase.rpc(
    'farmer_collection_schedule',
    params: {'p_limit': 150},
  );

  return (response as List)
      .map(
        (row) => FarmerCollectionScheduleItem.fromSupabase(
          Map<String, dynamic>.from(row as Map),
        ),
      )
      .toList();
}

String _farmerPartnerNumber(double value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value.toStringAsFixed(1);
}

String _farmerPartnerDate(DateTime? date) {
  if (date == null) return 'Not scheduled';
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
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

class _FarmerPartnerToolShell extends StatelessWidget {
  final String title;
  final Widget child;

  const _FarmerPartnerToolShell({
    required this.title,
    required this.child,
  });

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
        title: Text(title),
      ),
      body: child,
    );
  }
}

class FarmerPartnerToolsCard extends StatelessWidget {
  final FarmerProfile profile;

  const FarmerPartnerToolsCard({
    super.key,
    required this.profile,
  });

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }

  Widget _tool({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: FarmColors.cardSoft,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: FarmColors.line),
        ),
        child: Row(
          children: [
            Container(
              height: 38,
              width: 38,
              decoration: BoxDecoration(
                color: FarmColors.lightGreen,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: FarmColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: FarmColors.ink,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: FarmColors.mutedText,
                      fontWeight: FontWeight.w700,
                      fontSize: 9.5,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: FarmColors.mutedText),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FarmCard(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Farmer Partner Tools',
            style: TextStyle(
              color: FarmColors.ink,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Post Farm Stories, answer customers, build trust, see Story-to-Sale intelligence, Grow Signals, demand, collections and payouts.',
            style: TextStyle(
              color: FarmColors.mutedText,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          _tool(
            context: context,
            icon: Icons.spa_rounded,
            title: 'Grow Signals',
            subtitle:
                'See customer-backed Harvest Circle demand before committing supply.',
            onTap: () => _open(
              context,
              HpjFarmerGrowSignalsScreen(profile: profile),
            ),
          ),
          const SizedBox(height: 8),
          _tool(
            context: context,
            icon: Icons.insights_rounded,
            title: 'Grow Intelligence',
            subtitle:
                'Compare committed demand, recent buying and HPJ-confirmed supply with overplant safeguards.',
            onTap: () => _open(
              context,
              HpjFarmerGrowIntelligenceScreen(profile: profile),
            ),
          ),
          const SizedBox(height: 8),
          _tool(
            context: context,
            icon: Icons.route_outlined,
            title: 'Matched Opportunities',
            subtitle:
                'See explainable HPJ procurement matches for your confirmed supply.',
            onTap: () => _open(
              context,
              HpjFarmerMatchedOpportunitiesScreen(profile: profile),
            ),
          ),
          const SizedBox(height: 8),
          _tool(
            context: context,
            icon: Icons.auto_stories_outlined,
            title: 'Farm Stories',
            subtitle:
                'Post a quick planting, growing or harvest update for customers. Stories stay live for 24 hours.',
            onTap: () => _open(
              context,
              HpjFarmerStoriesScreen(profile: profile),
            ),
          ),
          const SizedBox(height: 8),
          _tool(
            context: context,
            icon: Icons.forum_outlined,
            title: 'Ask the Farmer Inbox',
            subtitle:
                'Answer customer and business crop questions inside HPJ without sharing private contact details.',
            onTap: () => _open(
              context,
              HpjFarmerQuestionsScreen(profile: profile),
            ),
          ),
          const SizedBox(height: 8),
          _tool(
            context: context,
            icon: Icons.shield_outlined,
            title: 'Trust & Reputation',
            subtitle:
                'See the verified HPJ activity customers use to understand your farm track record.',
            onTap: () => _open(
              context,
              HpjFarmerTrustScreen(profile: profile),
            ),
          ),
          const SizedBox(height: 8),
          _tool(
            context: context,
            icon: Icons.moving_rounded,
            title: 'Story → Sales',
            subtitle:
                'See Story views, product interest, Add-to-Box actions and transaction-attributed sales.',
            onTap: () => _open(
              context,
              HpjFarmerStorySalesInsightsScreen(profile: profile),
            ),
          ),
          const SizedBox(height: 8),
          _tool(
            context: context,
            icon: Icons.auto_graph_rounded,
            title: 'Story Impact',
            subtitle:
                'See Farm-to-Box scans, farm views, reorder actions and shares.',
            onTap: () => _open(
              context,
              HpjFarmerStoryImpactScreen(profile: profile),
            ),
          ),
          const SizedBox(height: 8),
          _tool(
            context: context,
            icon: Icons.restaurant_menu_rounded,
            title: 'Meal Intelligence',
            subtitle:
                'See what Jamaica is cooking, sharing and engaging with before deciding what to grow.',
            onTap: () => _open(
              context,
              const HpjFarmerMealIntelligenceScreen(),
            ),
          ),
          const SizedBox(height: 8),
          _tool(
            context: context,
            icon: Icons.handshake_outlined,
            title: 'Relationship Network',
            subtitle:
                'See repeat customer and business relationships plus how many people prefer your farm.',
            onTap: () => _open(
              context,
              HpjFarmerRelationshipNetworkScreen(profile: profile),
            ),
          ),
          const SizedBox(height: 8),
          _tool(
            context: context,
            icon: Icons.radar_rounded,
            title: 'Demand Radar',
            subtitle:
                'See Jamaica-wide demand gaps, with crops matching your reported supply ranked first.',
            onTap: () => _open(
              context,
              HpjFarmerDemandRadarScreen(profile: profile),
            ),
          ),
          const SizedBox(height: 8),
          _tool(
            context: context,
            icon: Icons.trending_up_outlined,
            title: 'Market Demand',
            subtitle:
                'See aggregated wholesale needs and report matching supply.',
            onTap: () => _open(
              context,
              FarmerDemandBoardScreen(profile: profile),
            ),
          ),
          const SizedBox(height: 8),
          _tool(
            context: context,
            icon: Icons.local_shipping_outlined,
            title: 'Collections',
            subtitle:
                'See HPJ collection dates, quantities and receiving status.',
            onTap: () => _open(
              context,
              FarmerCollectionScheduleScreen(profile: profile),
            ),
          ),
          const SizedBox(height: 8),
          _tool(
            context: context,
            icon: Icons.agriculture_outlined,
            title: 'My Supply',
            subtitle:
                'Report what you are growing and update harvest readiness.',
            onTap: () => _open(
              context,
              _FarmerPartnerToolShell(
                title: 'My Supply',
                child: FarmerSupplyScreen(
                  profile: profile,
                  refreshKey: 0,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _tool(
            context: context,
            icon: Icons.storefront_outlined,
            title: 'Products',
            subtitle: 'Submit marketplace listings, stock and harvest details.',
            onTap: () => _open(
              context,
              _FarmerPartnerToolShell(
                title: 'My Products',
                child: FarmerProductsScreen(
                  profile: profile,
                  refreshKey: 0,
                  onChanged: () {},
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _tool(
            context: context,
            icon: Icons.payments_outlined,
            title: 'Payouts',
            subtitle: 'Review pending, held and released farmer earnings.',
            onTap: () => _open(
              context,
              _FarmerPartnerToolShell(
                title: 'Payouts',
                child: FarmerEarningsScreen(
                  profile: profile,
                  refreshKey: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}



// ============================================================================
// HPJ PHASE 99 — TRUE FARM STORIES
// ============================================================================
// Lightweight 24-hour farmer updates. Uses the existing cross-platform image
// picker and a dedicated public storage bucket created by the Phase 99–101 SQL.
// ============================================================================

Future<String?> _hpjUploadFarmStoryPhoto() async {
  final user = supabase.auth.currentUser;
  if (user == null) throw Exception('Sign in before posting a Farm Story.');

  final picked = await pickProductImageFromDevice();
  if (picked == null) return null;
  if (picked.bytes.isEmpty) throw Exception('Choose a valid story photo.');

  const maxBytes = 8 * 1024 * 1024;
  if (picked.bytes.length > maxBytes) {
    throw Exception('Farm Story photo must be under 8 MB.');
  }

  final mime = picked.mimeType.trim().toLowerCase();
  if (!const <String>{
    'image/jpeg', 'image/jpg', 'image/png', 'image/webp',
  }.contains(mime)) {
    throw Exception('Use a JPG, PNG or WebP story photo.');
  }

  final rawName = picked.fileName.trim().isEmpty
      ? 'farm-story.jpg'
      : picked.fileName.trim();
  final safeName = rawName.replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '-');
  final path = '${user.id}/${DateTime.now().millisecondsSinceEpoch}-$safeName';

  await supabase.storage.from('farm-story-media').uploadBinary(
        path,
        picked.bytes,
        fileOptions: FileOptions(contentType: mime, upsert: false),
      );

  return supabase.storage.from('farm-story-media').getPublicUrl(path);
}

Future<List<HpjFarmStoryRecord>> fetchMyHpjFarmStories(
  FarmerProfile profile,
) async {
  if (supabase.auth.currentUser == null || profile.id.trim().isEmpty) {
    return const <HpjFarmStoryRecord>[];
  }
  try {
    final response = await supabase
        .from('hpj_farm_stories')
        .select()
        .eq('farmer_profile_id', profile.id)
        .order('created_at', ascending: false)
        .limit(30);
    return (response as List)
        .map((row) => HpjFarmStoryRecord.fromSupabase(
              Map<String, dynamic>.from(row as Map),
            ))
        .toList(growable: false);
  } catch (error) {
    farmDebugLog('My Farm Stories unavailable: $error');
    return const <HpjFarmStoryRecord>[];
  }
}

Future<void> deleteHpjFarmStory(String storyId) async {
  final user = supabase.auth.currentUser;
  if (user == null) throw Exception('Sign in first.');
  final id = storyId.trim();
  if (id.isEmpty) return;
  await supabase
      .from('hpj_farm_stories')
      .delete()
      .eq('id', id)
      .eq('farmer_user_id', user.id);
}

class HpjFarmerStoriesScreen extends StatefulWidget {
  final FarmerProfile profile;

  const HpjFarmerStoriesScreen({
    super.key,
    required this.profile,
  });

  @override
  State<HpjFarmerStoriesScreen> createState() => _HpjFarmerStoriesScreenState();
}

class _HpjFarmerStoriesScreenState extends State<HpjFarmerStoriesScreen> {
  late Future<List<HpjFarmStoryRecord>> _future;

  @override
  void initState() {
    super.initState();
    _future = fetchMyHpjFarmStories(widget.profile);
  }

  Future<void> _refresh() async {
    final next = fetchMyHpjFarmStories(widget.profile);
    if (mounted) setState(() => _future = next);
    await next;
  }

  Future<void> _postStory() async {
    if (!widget.profile.isApproved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('HPJ approval is required before posting Farm Stories.')),
      );
      return;
    }
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _HpjFarmStoryComposerSheet(profile: widget.profile),
    );
    if (saved == true) await _refresh();
  }

  Future<void> _remove(HpjFarmStoryRecord story) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove this Farm Story?'),
        content: const Text('Customers will no longer see this story.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await deleteHpjFarmStory(story.id);
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyAppError(error))),
      );
    }
  }

  String _timeLeft(HpjFarmStoryRecord story) {
    final diff = story.expiresAt.difference(DateTime.now());
    if (diff.isNegative) return 'Expired';
    if (diff.inHours < 1) return '${diff.inMinutes.clamp(1, 59)} min left';
    return '${diff.inHours.clamp(1, 24)}h left';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: AppBar(
        title: const Text('Farm Stories'),
        actions: [
          TextButton.icon(
            onPressed: _postStory,
            icon: const Icon(Icons.add_a_photo_outlined),
            label: const Text('Post Story'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<HpjFarmStoryRecord>>(
          future: _future,
          builder: (context, snapshot) {
            final stories = snapshot.data ?? const <HpjFarmStoryRecord>[];
            final active = stories
                .where((story) => story.expiresAt.isAfter(DateTime.now()))
                .toList(growable: false);
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF063D2A), Color(0xFF126445)],
                    ),
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 650;
                      final copy = const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'FARM STORIES',
                            style: TextStyle(
                              color: Color(0xFFFFD15A),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            ),
                          ),
                          SizedBox(height: 7),
                          Text(
                            'Show customers what is happening on your farm today.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              height: 1.08,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 7),
                          Text(
                            'Planting • Growing • Almost Ready • Harvesting • Available Now. Each story stays live for 24 hours.',
                            style: TextStyle(
                              color: Color(0xFFC9DDD4),
                              fontSize: 10,
                              height: 1.4,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      );
                      final button = FilledButton.icon(
                        onPressed: _postStory,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD15A),
                          foregroundColor: const Color(0xFF073F2C),
                        ),
                        icon: const Icon(Icons.add_a_photo_outlined),
                        label: const Text('Post Farm Story'),
                      );
                      return wide
                          ? Row(
                              children: [
                                Expanded(child: copy),
                                const SizedBox(width: 18),
                                button,
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [copy, const SizedBox(height: 14), button],
                            );
                    },
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Active Stories',
                        style: TextStyle(
                          color: FarmColors.deepGreen,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: FarmColors.primarySoft,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${active.length} live',
                        style: const TextStyle(
                          color: FarmColors.deepGreen,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 9),
                if (snapshot.connectionState == ConnectionState.waiting && stories.isEmpty)
                  const SizedBox(height: 220, child: Center(child: CircularProgressIndicator()))
                else if (active.isEmpty)
                  FarmEmptyState(
                    icon: Icons.auto_stories_outlined,
                    title: 'No active Farm Stories',
                    message: 'Post a quick field or harvest update and customers will see it on HPJ Home.',
                    actionLabel: 'Post Story',
                    onAction: _postStory,
                  )
                else
                  ...active.map((story) {
                    final image = cleanHostedImageUrl(story.imageUrl);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: FarmCard(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                width: 88,
                                height: 88,
                                color: FarmColors.primarySoft,
                                alignment: Alignment.center,
                                child: image == null
                                    ? const Icon(Icons.eco_outlined, color: FarmColors.primary, size: 30)
                                    : Image.network(image, fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => const Icon(
                                          Icons.eco_outlined,
                                          color: FarmColors.primary,
                                          size: 30,
                                        )),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFF3C7),
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          story.stageLabel,
                                          style: const TextStyle(
                                            color: Color(0xFF7A5A00),
                                            fontSize: 8.5,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _timeLeft(story),
                                        style: const TextStyle(
                                          color: FarmColors.mutedText,
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 7),
                                  if (story.productName.isNotEmpty)
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            story.productName,
                                            style: const TextStyle(
                                              color: FarmColors.deepGreen,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                        if (story.productId.isNotEmpty)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 7,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: FarmColors.primarySoft,
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                            child: const Text(
                                              'SHOP LINKED',
                                              style: TextStyle(
                                                color: FarmColors.deepGreen,
                                                fontSize: 7.2,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  if (story.productName.isNotEmpty) const SizedBox(height: 3),
                                  Text(
                                    story.caption.isEmpty ? 'Farm update' : story.caption,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: FarmColors.ink,
                                      fontSize: 10.5,
                                      height: 1.35,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Remove story',
                              onPressed: () => _remove(story),
                              icon: const Icon(Icons.delete_outline_rounded),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HpjFarmStoryComposerSheet extends StatefulWidget {
  final FarmerProfile profile;

  const _HpjFarmStoryComposerSheet({required this.profile});

  @override
  State<_HpjFarmStoryComposerSheet> createState() =>
      _HpjFarmStoryComposerSheetState();
}

class _HpjFarmStoryComposerSheetState extends State<_HpjFarmStoryComposerSheet> {
  static const _stages = <String, String>{
    'planting': 'Planting',
    'growing': 'Growing',
    'almost_ready': 'Almost Ready',
    'harvesting': 'Harvesting',
    'available_now': 'Available Now',
  };

  final captionController = TextEditingController();
  final productController = TextEditingController();
  late Future<List<Product>> _storyProductsFuture;
  String selectedProductId = '';
  String stage = 'growing';
  String imageUrl = '';
  bool uploading = false;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    _storyProductsFuture = fetchFarmerProducts(widget.profile.id);
  }

  @override
  void dispose() {
    captionController.dispose();
    productController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    if (uploading || saving) return;
    setState(() => uploading = true);
    try {
      final url = await _hpjUploadFarmStoryPhoto();
      if (!mounted) return;
      if (url != null && url.trim().isNotEmpty) {
        setState(() => imageUrl = url.trim());
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyAppError(error))),
      );
    } finally {
      if (mounted) setState(() => uploading = false);
    }
  }

  Future<void> _publish() async {
    if (saving || uploading) return;
    final user = supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in before posting a Farm Story.')),
      );
      return;
    }
    final caption = captionController.text.trim();
    if (caption.isEmpty && imageUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a short update or a farm photo.')),
      );
      return;
    }
    setState(() => saving = true);
    try {
      await supabase.from('hpj_farm_stories').insert({
        'farmer_profile_id': widget.profile.id,
        'farmer_user_id': user.id,
        'farm_name': widget.profile.farmName.trim(),
        'parish': widget.profile.parish.trim(),
        'stage': stage,
        'caption': caption,
        'image_url': imageUrl.trim().isEmpty ? null : imageUrl.trim(),
        'product_id':
            selectedProductId.trim().isEmpty ? null : selectedProductId.trim(),
        'product_name': productController.text.trim().isEmpty
            ? null
            : productController.text.trim(),
        'expires_at': DateTime.now().toUtc().add(const Duration(hours: 24)).toIso8601String(),
        'is_active': true,
      });
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyAppError(error))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final image = cleanHostedImageUrl(imageUrl);
    return AnimatedPadding(
      duration: const Duration(milliseconds: 160),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .92),
        decoration: const BoxDecoration(
          color: FarmColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: FarmColors.line,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Post a Farm Story',
              style: TextStyle(
                color: FarmColors.deepGreen,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Keep it quick and real. Customers see the update for 24 hours.',
              style: TextStyle(
                color: FarmColors.mutedText,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: uploading ? null : _pickPhoto,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                height: 210,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: FarmColors.primarySoft,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: FarmColors.line),
                ),
                child: uploading
                    ? const Center(child: CircularProgressIndicator())
                    : image == null
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo_outlined, size: 38, color: FarmColors.primary),
                              SizedBox(height: 8),
                              Text('Add a farm photo', style: TextStyle(fontWeight: FontWeight.w900)),
                              SizedBox(height: 3),
                              Text('JPG, PNG or WebP • max 8 MB',
                                  style: TextStyle(color: FarmColors.mutedText, fontSize: 9.5)),
                            ],
                          )
                        : Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(image, fit: BoxFit.cover),
                              Positioned(
                                right: 10,
                                top: 10,
                                child: FilledButton.tonalIcon(
                                  onPressed: _pickPhoto,
                                  icon: const Icon(Icons.refresh_rounded, size: 16),
                                  label: const Text('Change'),
                                ),
                              ),
                            ],
                          ),
              ),
            ),
            const SizedBox(height: 14),
            const Text('What stage is it?', style: TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: _stages.entries.map((entry) {
                return ChoiceChip(
                  label: Text(entry.value),
                  selected: stage == entry.key,
                  onSelected: (_) => setState(() => stage = entry.key),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            FutureBuilder<List<Product>>(
              future: _storyProductsFuture,
              builder: (context, snapshot) {
                final products = (snapshot.data ?? const <Product>[])
                    .where((product) =>
                        product.id.trim().isNotEmpty && !product.isHidden)
                    .toList(growable: false);

                if (snapshot.connectionState == ConnectionState.waiting &&
                    products.isEmpty) {
                  return const LinearProgressIndicator(minHeight: 2);
                }

                if (products.isEmpty) {
                  return TextField(
                    controller: productController,
                    enabled: !saving,
                    decoration: const InputDecoration(
                      labelText: 'Produce (optional)',
                      hintText: 'e.g. Avocado, Tomato, Scotch bonnet',
                      prefixIcon: Icon(Icons.eco_outlined),
                      helperText:
                          'No linked marketplace product found. This Story can still be posted.',
                    ),
                  );
                }

                return DropdownButtonFormField<String>(
                  value: selectedProductId.isEmpty ? null : selectedProductId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Link a marketplace product (recommended)',
                    prefixIcon: Icon(Icons.shopping_bag_outlined),
                    helperText:
                        'Linked Stories can show price, availability and Add to Box.',
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: '',
                      child: Text('No linked product'),
                    ),
                    ...products.map(
                      (product) => DropdownMenuItem<String>(
                        value: product.id.trim(),
                        child: Text(
                          '${product.name} • ${product.formattedPrice}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  onChanged: saving
                      ? null
                      : (value) {
                          final next = value?.trim() ?? '';
                          Product? selected;
                          for (final product in products) {
                            if (product.id.trim() == next) {
                              selected = product;
                              break;
                            }
                          }
                          setState(() {
                            selectedProductId = next;
                            productController.text = selected?.name ?? '';
                          });
                        },
                );
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: captionController,
              enabled: !saving,
              minLines: 3,
              maxLines: 5,
              maxLength: 240,
              decoration: const InputDecoration(
                labelText: 'Quick update',
                hintText: 'Tell customers what is happening on the farm today...',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 46,
              child: FilledButton.icon(
                onPressed: saving || uploading ? null : _publish,
                icon: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_stories_rounded),
                label: Text(saving ? 'Publishing…' : 'Publish for 24 hours'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// HPJ PHASE 96 — FARM STORY IMPACT
// ============================================================================
// Aggregate engagement only. A Buy Again action is a trace-page CTA tap, not a
// completed retail sale. Customer private information is never returned here.
// ============================================================================

class HpjFarmerStoryImpact {
  final int scans7d;
  final int scans30d;
  final int farmViews30d;
  final int buyAgain30d;
  final int shares30d;
  final int mealPulse30d;
  final int ratingCount;
  final double averageOverallRating;
  final String topProductName;
  final int topProductActions;

  const HpjFarmerStoryImpact({
    required this.scans7d,
    required this.scans30d,
    required this.farmViews30d,
    required this.buyAgain30d,
    required this.shares30d,
    required this.mealPulse30d,
    required this.ratingCount,
    required this.averageOverallRating,
    required this.topProductName,
    required this.topProductActions,
  });

  static const empty = HpjFarmerStoryImpact(
    scans7d: 0,
    scans30d: 0,
    farmViews30d: 0,
    buyAgain30d: 0,
    shares30d: 0,
    mealPulse30d: 0,
    ratingCount: 0,
    averageOverallRating: 0,
    topProductName: '',
    topProductActions: 0,
  );

  factory HpjFarmerStoryImpact.fromSupabase(Map<String, dynamic> data) {
    int whole(dynamic value) {
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    double number(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    return HpjFarmerStoryImpact(
      scans7d: whole(data['scans_7d']),
      scans30d: whole(data['scans_30d']),
      farmViews30d: whole(data['farm_views_30d']),
      buyAgain30d: whole(data['buy_again_30d']),
      shares30d: whole(data['shares_30d']),
      mealPulse30d: whole(data['meal_pulse_30d']),
      ratingCount: whole(data['rating_count']),
      averageOverallRating: number(data['avg_overall_rating']),
      topProductName: (data['top_product_name'] ?? '').toString().trim(),
      topProductActions: whole(data['top_product_actions']),
    );
  }
}

Future<HpjFarmerStoryImpact> fetchHpjFarmerStoryImpact(
  String farmerProfileId,
) async {
  final clean = farmerProfileId.trim();
  if (clean.isEmpty || supabase.auth.currentUser == null) {
    return HpjFarmerStoryImpact.empty;
  }

  final response = await supabase.rpc(
    'hpj_get_farmer_trace_impact',
    params: <String, dynamic>{'p_farmer_profile_id': clean},
  );

  if (response is List && response.isNotEmpty) {
    return HpjFarmerStoryImpact.fromSupabase(
      Map<String, dynamic>.from(response.first as Map),
    );
  }
  if (response is Map) {
    return HpjFarmerStoryImpact.fromSupabase(
      Map<String, dynamic>.from(response),
    );
  }
  return HpjFarmerStoryImpact.empty;
}

class HpjFarmerStoryImpactScreen extends StatefulWidget {
  final FarmerProfile profile;

  const HpjFarmerStoryImpactScreen({
    super.key,
    required this.profile,
  });

  @override
  State<HpjFarmerStoryImpactScreen> createState() =>
      _HpjFarmerStoryImpactScreenState();
}

class _HpjFarmerStoryImpactScreenState
    extends State<HpjFarmerStoryImpactScreen> {
  late Future<HpjFarmerStoryImpact> _future;

  @override
  void initState() {
    super.initState();
    _future = fetchHpjFarmerStoryImpact(widget.profile.id);
  }

  Future<void> _refresh() async {
    final next = fetchHpjFarmerStoryImpact(widget.profile.id);
    if (mounted) setState(() => _future = next);
    await next;
  }

  Widget _metric({
    required IconData icon,
    required String value,
    required String label,
    String note = '',
  }) {
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
          const SizedBox(height: 9),
          Text(
            value,
            style: const TextStyle(
              color: FarmColors.deepGreen,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: FarmColors.ink,
              fontSize: 10.2,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (note.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              note,
              style: const TextStyle(
                color: FarmColors.mutedText,
                fontSize: 8.5,
                height: 1.25,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: AppBar(title: const Text('Story Impact')),
      body: FutureBuilder<HpjFarmerStoryImpact>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(18),
                children: [
                  FarmEmptyState(
                    icon: Icons.query_stats_outlined,
                    title: 'Story Impact unavailable',
                    message: friendlyAppError(snapshot.error!),
                  ),
                ],
              ),
            );
          }

          final impact = snapshot.data ?? HpjFarmerStoryImpact.empty;
          final rating = impact.ratingCount <= 0
              ? '—'
              : impact.averageOverallRating.toStringAsFixed(1);

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF063D2A),
                        Color(0xFF126445),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF063D2A).withOpacity(.14),
                        blurRadius: 25,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'FARM STORY IMPACT',
                        style: TextStyle(
                          color: Color(0xFFFFD15A),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.05,
                        ),
                      ),
                      const SizedBox(height: 7),
                      const Text(
                        'See how your verified food story is reaching customers.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          height: 1.06,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        '${widget.profile.farmName} • Farm-to-Box QR and Passport engagement',
                        style: TextStyle(
                          color: Colors.white.withOpacity(.78),
                          fontSize: 10.3,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final columns = width >= 850 ? 4 : width >= 540 ? 2 : 1;
                    const gap = 10.0;
                    final cardWidth =
                        (width - (gap * (columns - 1))) / columns;
                    final cards = <Widget>[
                      _metric(
                        icon: Icons.qr_code_scanner_rounded,
                        value: '${impact.scans7d}',
                        label: 'Scans • 7 days',
                        note: 'Unique trace sessions',
                      ),
                      _metric(
                        icon: Icons.visibility_outlined,
                        value: '${impact.scans30d}',
                        label: 'Scans • 30 days',
                        note: 'Unique trace sessions',
                      ),
                      _metric(
                        icon: Icons.replay_rounded,
                        value: '${impact.buyAgain30d}',
                        label: 'Buy Again actions',
                        note: 'Not completed sales',
                      ),
                      _metric(
                        icon: Icons.share_outlined,
                        value: '${impact.shares30d}',
                        label: 'Story shares',
                        note: 'Last 30 days',
                      ),
                    ];

                    return Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: cards
                          .map((card) => SizedBox(width: cardWidth, child: card))
                          .toList(growable: false),
                    );
                  },
                ),
                const SizedBox(height: 14),
                FarmCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Customer connection',
                        style: TextStyle(
                          color: FarmColors.ink,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _HpjStoryImpactRow(
                        icon: Icons.storefront_outlined,
                        label: 'Farm page views',
                        value: '${impact.farmViews30d}',
                      ),
                      _HpjStoryImpactRow(
                        icon: Icons.restaurant_outlined,
                        label: 'Meal Pulse actions',
                        value: '${impact.mealPulse30d}',
                      ),
                      _HpjStoryImpactRow(
                        icon: Icons.star_rounded,
                        label: 'Experience rating',
                        value: impact.ratingCount <= 0
                            ? 'No ratings yet'
                            : '$rating / 5 • ${impact.ratingCount}',
                      ),
                      _HpjStoryImpactRow(
                        icon: Icons.eco_outlined,
                        label: 'Top traced produce',
                        value: impact.topProductName.isEmpty
                            ? 'Building data'
                            : '${impact.topProductName} • ${impact.topProductActions}',
                        isLast: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E8),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFF1DFAD)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xFF9A6A00),
                        size: 20,
                      ),
                      SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          'Story Impact measures QR and Passport engagement. “Buy Again” means a customer started that action from the trace page; only completed HPJ checkout counts as a sale. Customer private information is not shown here.',
                          style: TextStyle(
                            color: Color(0xFF755A1A),
                            fontSize: 9.7,
                            height: 1.4,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HpjStoryImpactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  const _HpjStoryImpactRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: FarmColors.line),
              ),
      ),
      child: Row(
        children: [
          Icon(icon, color: FarmColors.green, size: 19),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: FarmColors.ink,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: FarmColors.deepGreen,
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FarmerNotificationFocusNotice extends StatelessWidget {
  final bool found;
  final String foundMessage;
  final String missingMessage;

  const _FarmerNotificationFocusNotice({
    required this.found,
    required this.foundMessage,
    required this.missingMessage,
  });

  @override
  Widget build(BuildContext context) {
    final accent = found ? FarmColors.primary : FarmColors.warning;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: found ? FarmColors.primarySoft : const Color(0xFFFFF7E8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: accent.withOpacity(0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            found
                ? Icons.notifications_active_outlined
                : Icons.info_outline_rounded,
            size: 18,
            color: accent,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              found ? foundMessage : missingMessage,
              style: const TextStyle(
                color: FarmColors.mutedText,
                fontSize: 10,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}



// ============================================================================
// HPJ PHASE 91 — FARMER GROW SIGNALS
// Real customer Harvest Circle reservations are translated into a farmer-facing
// supply opportunity. Meal Pulse remains a separate soft/social signal.
// ============================================================================

class HpjGrowSignal {
  final String circleId;
  final String productName;
  final String category;
  final String imageUrl;
  final String parish;
  final String unit;
  final double targetQuantity;
  final DateTime? harvestStart;
  final DateTime? harvestEnd;
  final double reservedQuantity;
  final int householdCount;
  final double supplyCommitted;
  final int farmerCount;
  final double supplyGap;
  final String demandConfidence;
  final double myCommittedQuantity;
  final DateTime? myExpectedHarvestDate;
  final String myStatus;

  const HpjGrowSignal({
    required this.circleId,
    required this.productName,
    required this.category,
    required this.imageUrl,
    required this.parish,
    required this.unit,
    required this.targetQuantity,
    required this.harvestStart,
    required this.harvestEnd,
    required this.reservedQuantity,
    required this.householdCount,
    required this.supplyCommitted,
    required this.farmerCount,
    required this.supplyGap,
    required this.demandConfidence,
    required this.myCommittedQuantity,
    required this.myExpectedHarvestDate,
    required this.myStatus,
  });

  factory HpjGrowSignal.fromSupabase(Map<String, dynamic> data) {
    double number(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    int integer(dynamic value) {
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return HpjGrowSignal(
      circleId: (data['circle_id'] ?? '').toString(),
      productName: (data['product_name'] ?? 'Produce').toString().trim(),
      category: (data['category'] ?? '').toString().trim(),
      imageUrl: (data['image_url'] ?? '').toString().trim(),
      parish: (data['parish'] ?? '').toString().trim(),
      unit: (data['unit'] ?? 'unit').toString().trim(),
      targetQuantity: number(data['target_quantity']),
      harvestStart: parseProductDate(data['harvest_start']),
      harvestEnd: parseProductDate(data['harvest_end']),
      reservedQuantity: number(data['reserved_quantity']),
      householdCount: integer(data['household_count']),
      supplyCommitted: number(data['supply_committed']),
      farmerCount: integer(data['farmer_count']),
      supplyGap: number(data['supply_gap']),
      demandConfidence:
          (data['demand_confidence'] ?? 'building').toString().trim().toLowerCase(),
      myCommittedQuantity: number(data['my_committed_quantity']),
      myExpectedHarvestDate: parseProductDate(data['my_expected_harvest_date']),
      myStatus: (data['my_status'] ?? '').toString().trim().toLowerCase(),
    );
  }

  bool get hasMyCommitment => myCommittedQuantity > 0 && myStatus != 'cancelled';
}

Future<List<HpjGrowSignal>> fetchHpjGrowSignals({int limit = 40}) async {
  try {
    final response = await supabase.rpc(
      'hpj_get_grow_signals',
      params: {'p_limit': limit},
    );

    return (response as List)
        .map(
          (row) => HpjGrowSignal.fromSupabase(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .where((signal) => signal.circleId.isNotEmpty)
        .toList(growable: false);
  } catch (error) {
    farmDebugLog('Grow Signals unavailable: $error');
    return const <HpjGrowSignal>[];
  }
}

Future<void> saveHpjGrowSignalCommitment({
  required HpjGrowSignal signal,
  required FarmerProfile profile,
  required double quantity,
  required DateTime? expectedHarvestDate,
  required String notes,
}) async {
  if (!profile.isApproved) {
    throw Exception('Your farmer profile must be approved first.');
  }

  await supabase.rpc(
    'hpj_upsert_grow_signal_commitment',
    params: <String, dynamic>{
      'p_circle_id': signal.circleId,
      'p_farmer_profile_id': profile.id,
      'p_quantity': quantity,
      'p_expected_harvest_date':
          expectedHarvestDate?.toIso8601String().split('T').first,
      'p_notes': notes.trim().isEmpty ? null : notes.trim(),
    },
  );
}

Future<void> cancelHpjGrowSignalCommitment({
  required HpjGrowSignal signal,
  required FarmerProfile profile,
}) async {
  await supabase.rpc(
    'hpj_cancel_grow_signal_commitment',
    params: <String, dynamic>{
      'p_circle_id': signal.circleId,
      'p_farmer_profile_id': profile.id,
    },
  );
}

class HpjFarmerGrowSignalsScreen extends StatefulWidget {
  final FarmerProfile profile;

  const HpjFarmerGrowSignalsScreen({
    super.key,
    required this.profile,
  });

  @override
  State<HpjFarmerGrowSignalsScreen> createState() =>
      _HpjFarmerGrowSignalsScreenState();
}

class _HpjFarmerGrowSignalsScreenState
    extends State<HpjFarmerGrowSignalsScreen> {
  String filter = 'open';
  late Future<List<HpjGrowSignal>> future;
  late Future<List<HpjFarmerRescueWatch>> rescueFuture;

  @override
  void initState() {
    super.initState();
    future = fetchHpjGrowSignals();
    rescueFuture = fetchHpjFarmerRescueWatch(widget.profile.id);
  }

  Future<void> _refresh() async {
    final next = fetchHpjGrowSignals();
    final rescueNext = fetchHpjFarmerRescueWatch(widget.profile.id);
    if (mounted) {
      setState(() {
        future = next;
        rescueFuture = rescueNext;
      });
    }
    await Future.wait<dynamic>([next, rescueNext]);
  }

  List<HpjGrowSignal> _filtered(List<HpjGrowSignal> source) {
    switch (filter) {
      case 'high':
        return source
            .where((signal) => signal.demandConfidence == 'high')
            .toList(growable: false);
      case 'mine':
        return source
            .where((signal) => signal.hasMyCommitment)
            .toList(growable: false);
      case 'covered':
        return source
            .where((signal) => signal.supplyGap <= 0)
            .toList(growable: false);
      default:
        return source
            .where((signal) => signal.supplyGap > 0)
            .toList(growable: false);
    }
  }

  Future<void> _commit(HpjGrowSignal signal) async {
    if (!widget.profile.isApproved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your farmer profile must be approved first.')),
      );
      return;
    }

    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _HpjGrowSignalCommitSheet(
        signal: signal,
        profile: widget.profile,
      ),
    );

    if (changed == true && mounted) await _refresh();
  }

  Future<void> _cancel(HpjGrowSignal signal) async {
    try {
      await cancelHpjGrowSignalCommitment(
        signal: signal,
        profile: widget.profile,
      );
      if (!mounted) return;
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyAppError(error))),
      );
    }
  }

  Future<void> _postJourneyUpdate(HpjGrowSignal signal) async {
    if (!signal.hasMyCommitment) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Commit supply to this Grow Signal before posting crop updates.'),
        ),
      );
      return;
    }

    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _HpjHarvestJourneyUpdateSheet(
        signal: signal,
        profile: widget.profile,
      ),
    );

    if (changed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harvest Journey update shared.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final desktop = kIsWeb && MediaQuery.sizeOf(context).width >= 980;

    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          'Grow Signals',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<HpjGrowSignal>>(
          future: future,
          builder: (context, snapshot) {
            final all = snapshot.data ?? const <HpjGrowSignal>[];
            final rows = _filtered(all);
            final totalGap = all.fold<double>(
              0,
              (sum, item) => sum + (item.supplyGap > 0 ? item.supplyGap : 0),
            );

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                desktop ? 28 : 14,
                desktop ? 24 : 14,
                desktop ? 28 : 14,
                42,
              ),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1180),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HpjGrowSignalHero(
                          activeSignals: all.where((e) => e.supplyGap > 0).length,
                          totalGap: totalGap,
                        ),
                        const SizedBox(height: 12),
                        FutureBuilder<List<HpjFarmerRescueWatch>>(
                          future: rescueFuture,
                          builder: (context, rescueSnapshot) {
                            final rescueRows = rescueSnapshot.data ??
                                const <HpjFarmerRescueWatch>[];
                            if (rescueSnapshot.connectionState !=
                                    ConnectionState.waiting &&
                                rescueRows.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            return _HpjFarmerRescueWatchCard(
                              rows: rescueRows,
                              loading: rescueSnapshot.connectionState ==
                                      ConnectionState.waiting &&
                                  rescueRows.isEmpty,
                            );
                          },
                        ),
                        const SizedBox(height: 15),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _chip('open', 'Open gaps'),
                              const SizedBox(width: 7),
                              _chip('high', 'High confidence'),
                              const SizedBox(width: 7),
                              _chip('mine', 'My commitments'),
                              const SizedBox(width: 7),
                              _chip('covered', 'Covered'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (snapshot.connectionState == ConnectionState.waiting &&
                            all.isEmpty)
                          const SizedBox(
                            height: 250,
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (rows.isEmpty)
                          _emptyState(all.isEmpty)
                        else
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final columns = constraints.maxWidth >= 850 ? 2 : 1;
                              final gap = 12.0;
                              final width = columns == 1
                                  ? constraints.maxWidth
                                  : (constraints.maxWidth - gap) / 2;
                              return Wrap(
                                spacing: gap,
                                runSpacing: gap,
                                children: rows
                                    .map(
                                      (signal) => SizedBox(
                                        width: width,
                                        child: _HpjGrowSignalCard(
                                          signal: signal,
                                          onCommit: () => _commit(signal),
                                          onCancel: () => _cancel(signal),
                                          onJourneyUpdate: () =>
                                              _postJourneyUpdate(signal),
                                        ),
                                      ),
                                    )
                                    .toList(growable: false),
                              );
                            },
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

  Widget _chip(String value, String label) {
    final selected = filter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => filter = value),
      selectedColor: FarmColors.primary,
      backgroundColor: FarmColors.card,
      side: const BorderSide(color: FarmColors.line),
      labelStyle: TextStyle(
        color: selected ? Colors.white : FarmColors.ink,
        fontSize: 10,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _emptyState(bool noSignalsAtAll) {
    return FarmCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.spa_outlined, size: 38, color: FarmColors.primary),
          const SizedBox(height: 8),
          Text(
            noSignalsAtAll
                ? 'No customer-backed Grow Signals yet'
                : 'Nothing matches this view',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: FarmColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            noSignalsAtAll
                ? 'As customers reserve upcoming harvests, the confirmed quantity will appear here. Meal Pulse remains a separate social signal.'
                : 'Try another filter or pull to refresh.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: FarmColors.mutedText,
              fontSize: 10.2,
              height: 1.4,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HpjGrowSignalHero extends StatelessWidget {
  final int activeSignals;
  final double totalGap;

  const _HpjGrowSignalHero({
    required this.activeSignals,
    required this.totalGap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF073F2C), Color(0xFF176044)],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF073F2C).withOpacity(.14),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 650;
          final intro = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'HPJ GROW SIGNALS',
                style: TextStyle(
                  color: Color(0xFFFFD65B),
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: .8,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Grow into demand,\nnot into uncertainty.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  height: 1.08,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'These signals come from customer Harvest Circle reservations. The gap shows reserved demand not yet covered by farmer commitments.',
                style: TextStyle(
                  color: Colors.white.withOpacity(.78),
                  fontSize: 10,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );

          final stats = Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.085),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(.12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$activeSignals open signal${activeSignals == 1 ? '' : 's'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_farmerPartnerNumber(totalGap)} total reserved units still uncovered',
                  style: TextStyle(
                    color: Colors.white.withOpacity(.70),
                    fontSize: 9,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );

          if (!wide) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [intro, const SizedBox(height: 15), stats],
            );
          }
          return Row(
            children: [
              Expanded(flex: 3, child: intro),
              const SizedBox(width: 20),
              Expanded(flex: 2, child: stats),
            ],
          );
        },
      ),
    );
  }
}

class _HpjGrowSignalCard extends StatelessWidget {
  final HpjGrowSignal signal;
  final VoidCallback onCommit;
  final VoidCallback onCancel;
  final VoidCallback onJourneyUpdate;

  const _HpjGrowSignalCard({
    required this.signal,
    required this.onCommit,
    required this.onCancel,
    required this.onJourneyUpdate,
  });

  Color get confidenceColor {
    switch (signal.demandConfidence) {
      case 'high':
        return FarmColors.success;
      case 'medium':
        return const Color(0xFFD69A16);
      default:
        return FarmColors.mutedText;
    }
  }

  String get confidenceLabel {
    switch (signal.demandConfidence) {
      case 'high':
        return 'High confidence';
      case 'medium':
        return 'Building strongly';
      default:
        return 'Early demand';
    }
  }

  @override
  Widget build(BuildContext context) {
    final reserved = _farmerPartnerNumber(signal.reservedQuantity);
    final committed = _farmerPartnerNumber(signal.supplyCommitted);
    final gap = _farmerPartnerNumber(signal.supplyGap);
    final target = signal.reservedQuantity <= 0 ? 1 : signal.reservedQuantity;
    final supplyProgress = (signal.supplyCommitted / target).clamp(0, 1).toDouble();

    return FarmCard(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: FarmColors.primarySoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.spa_rounded,
                  color: FarmColors.primary,
                  size: 25,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      signal.productName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: FarmColors.ink,
                        fontSize: 15,
                        height: 1.15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (signal.parish.isNotEmpty) signal.parish,
                        _farmerPartnerDate(signal.harvestStart),
                      ].join(' • '),
                      style: const TextStyle(
                        color: FarmColors.mutedText,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: confidenceColor.withOpacity(.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  confidenceLabel,
                  style: TextStyle(
                    color: confidenceColor,
                    fontSize: 7.8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              _metric('$reserved ${signal.unit}', 'Reserved demand'),
              const SizedBox(width: 7),
              _metric('$committed ${signal.unit}', 'Farmer supply'),
              const SizedBox(width: 7),
              _metric('$gap ${signal.unit}', 'Still needed'),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: supplyProgress,
              minHeight: 8,
              backgroundColor: FarmColors.cardSoft,
              valueColor: const AlwaysStoppedAnimation<Color>(FarmColors.success),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${signal.farmerCount} farmer${signal.farmerCount == 1 ? '' : 's'} have committed supply against ${signal.householdCount} customer reservation${signal.householdCount == 1 ? '' : 's'}.',
            style: const TextStyle(
              color: FarmColors.mutedText,
              fontSize: 8.8,
              height: 1.35,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (signal.hasMyCommitment) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: FarmColors.primarySoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'Your commitment: ${_farmerPartnerNumber(signal.myCommittedQuantity)} ${signal.unit}${signal.myExpectedHarvestDate == null ? '' : ' • ${_farmerPartnerDate(signal.myExpectedHarvestDate)}'}',
                style: const TextStyle(
                  color: FarmColors.primary,
                  fontSize: 9.4,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onCommit,
                  icon: const Icon(Icons.agriculture_outlined, size: 18),
                  label: Text(signal.hasMyCommitment ? 'Edit commitment' : 'I can supply'),
                ),
              ),
              if (signal.hasMyCommitment) ...[
                const SizedBox(width: 7),
                IconButton(
                  tooltip: 'Cancel commitment',
                  onPressed: onCancel,
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ],
          ),
          if (signal.hasMyCommitment) ...[
            const SizedBox(height: 7),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onJourneyUpdate,
                icon: const Icon(Icons.add_a_photo_outlined, size: 17),
                label: const Text('Post crop update'),
              ),
            ),
          ],
          const SizedBox(height: 4),
          const Text(
            'Grow Signal uses actual Harvest Circle reservations. HPJ still verifies supply, quality and collection before fulfillment.',
            style: TextStyle(
              color: FarmColors.mutedText,
              fontSize: 8.2,
              height: 1.3,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: FarmColors.cardSoft,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: FarmColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: FarmColors.ink,
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: FarmColors.mutedText,
                fontSize: 7.3,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HpjGrowSignalCommitSheet extends StatefulWidget {
  final HpjGrowSignal signal;
  final FarmerProfile profile;

  const _HpjGrowSignalCommitSheet({
    required this.signal,
    required this.profile,
  });

  @override
  State<_HpjGrowSignalCommitSheet> createState() =>
      _HpjGrowSignalCommitSheetState();
}


// ============================================================================
// HPJ PHASE 93 — OPERATIONAL GROW SIGNAL LINK
//
// Grow Signals remain the customer-backed planning layer. The existing Farmer
// Supply Forecast remains HPJ's operational verification/matching layer.
// Phase 93 stores the exact link between the two so an HPJ-confirmed Farmer
// Supply quantity can safely become the confirmed GrowTogether quantity.
// ============================================================================

Future<void> linkHpjGrowSignalSupplyForecast({
  required HpjGrowSignal signal,
  required FarmerProfile profile,
  required FarmerSupplyForecast forecast,
}) async {
  if (!isLoggedIn) return;
  if (signal.circleId.trim().isEmpty ||
      profile.id.trim().isEmpty ||
      forecast.id.trim().isEmpty) {
    return;
  }

  await supabase.rpc(
    'hpj_link_grow_signal_supply_forecast',
    params: <String, dynamic>{
      'p_circle_id': signal.circleId,
      'p_farmer_profile_id': profile.id,
      'p_supply_forecast_id': forecast.id,
    },
  );
}

class _HpjGrowSignalCommitSheetState extends State<_HpjGrowSignalCommitSheet> {
  late final TextEditingController quantityController;
  late final TextEditingController notesController;
  DateTime? harvestDate;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    quantityController = TextEditingController(
      text: widget.signal.myCommittedQuantity > 0
          ? _farmerPartnerNumber(widget.signal.myCommittedQuantity)
          : widget.signal.supplyGap > 0
              ? _farmerPartnerNumber(widget.signal.supplyGap)
              : '',
    );
    notesController = TextEditingController(
      text: 'GrowTogether customer-backed Grow Signal.',
    );
    harvestDate = widget.signal.myExpectedHarvestDate ?? widget.signal.harvestStart;
  }

  @override
  void dispose() {
    quantityController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final first = DateTime(now.year, now.month, now.day);
    final initial = harvestDate == null || harvestDate!.isBefore(first)
        ? first.add(const Duration(days: 7))
        : harvestDate!;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: first.add(const Duration(days: 730)),
    );
    if (!mounted || picked == null) return;
    setState(() => harvestDate = picked);
  }

  Future<void> _save() async {
    if (saving) return;
    final quantity = double.tryParse(
      quantityController.text.trim().replaceAll(',', ''),
    );
    if (quantity == null || !quantity.isFinite || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the quantity you can supply.')),
      );
      return;
    }

    setState(() => saving = true);
    try {
      await saveHpjGrowSignalCommitment(
        signal: widget.signal,
        profile: widget.profile,
        quantity: quantity,
        expectedHarvestDate: harvestDate,
        notes: notesController.text,
      );

      // Keep the existing HPJ matching workflow informed as well. This is a
      // separate planning report; the Grow Signal remains the customer-backed
      // layer while Farmer Supply remains HPJ's operational matching layer.
      if (!widget.signal.hasMyCommitment) {
        try {
          final forecast = await createFarmerSupplyForecast(
            cropName: widget.signal.productName,
            expectedQuantity: quantity,
            unit: widget.signal.unit,
            expectedHarvestDate: harvestDate,
            status: 'expected',
            notes:
                'GrowTogether circle ${widget.signal.circleId}. ${notesController.text.trim()}',
          );

          try {
            await linkHpjGrowSignalSupplyForecast(
              signal: widget.signal,
              profile: widget.profile,
              forecast: forecast,
            );
          } catch (error) {
            // The Farmer Supply record remains valid even if the GrowTogether
            // link is temporarily unavailable. The Phase 93 migration also
            // backfills older records from their Harvest Circle note.
            farmDebugLog(
              'Grow Signal supply created; operational link skipped: $error',
            );
          }
        } catch (error) {
          farmDebugLog('Grow Signal saved; supply forecast sync skipped: $error');
        }
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyAppError(error))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Container(
      constraints: const BoxConstraints(maxWidth: 650),
      margin: EdgeInsets.only(top: 20, bottom: kIsWeb ? 18 : 0),
      padding: EdgeInsets.fromLTRB(20, 18, 20, bottom + 22),
      decoration: const BoxDecoration(
        color: FarmColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Commit to this Grow Signal',
              style: TextStyle(
                color: FarmColors.ink,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.signal.productName} • ${_farmerPartnerNumber(widget.signal.supplyGap)} ${widget.signal.unit} still uncovered',
              style: const TextStyle(
                color: FarmColors.mutedText,
                fontSize: 10.2,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: quantityController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'I can supply (${widget.signal.unit})',
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(15),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: FarmColors.cardSoft,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: FarmColors.line),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event_outlined, color: FarmColors.primary),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        harvestDate == null
                            ? 'Choose expected harvest date'
                            : 'Expected harvest: ${_farmerPartnerDate(harvestDate)}',
                        style: const TextStyle(
                          color: FarmColors.ink,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: FarmColors.mutedText),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              maxLines: 3,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Notes to HPJ',
                hintText: 'Variety, harvest timing, collection notes…',
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5D7),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'This is a planning commitment, not an automatic purchase order. HPJ will still verify quantity, quality, timing and collection before fulfillment.',
                style: TextStyle(
                  color: Color(0xFF6B5515),
                  fontSize: 9,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: saving ? null : _save,
                icon: saving
                    ? const SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.agriculture_outlined),
                label: Text(saving ? 'Saving...' : 'Commit supply'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ============================================================================
// HPJ PHASE 92 — FARMER HARVEST JOURNEY + RESCUE WATCH
// Farmers with active Grow Signal commitments can post real crop-stage updates.
// Rescue Watch only uses HPJ-confirmed supply, never unverified social interest.
// ============================================================================

class HpjFarmerRescueWatch {
  final String circleId;
  final String productName;
  final String unit;
  final DateTime? harvestStart;
  final DateTime? harvestEnd;
  final double reservedQuantity;
  final double confirmedSupply;
  final double rescueQuantity;
  final double myConfirmedQuantity;

  const HpjFarmerRescueWatch({
    required this.circleId,
    required this.productName,
    required this.unit,
    required this.harvestStart,
    required this.harvestEnd,
    required this.reservedQuantity,
    required this.confirmedSupply,
    required this.rescueQuantity,
    required this.myConfirmedQuantity,
  });

  factory HpjFarmerRescueWatch.fromSupabase(Map<String, dynamic> data) {
    double number(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    return HpjFarmerRescueWatch(
      circleId: (data['circle_id'] ?? '').toString(),
      productName: (data['product_name'] ?? 'Produce').toString().trim(),
      unit: (data['unit'] ?? 'unit').toString().trim(),
      harvestStart: parseProductDate(data['harvest_start']),
      harvestEnd: parseProductDate(data['harvest_end']),
      reservedQuantity: number(data['reserved_quantity']),
      confirmedSupply: number(data['confirmed_supply']),
      rescueQuantity: number(data['rescue_quantity']),
      myConfirmedQuantity: number(data['my_confirmed_quantity']),
    );
  }
}

Future<List<HpjFarmerRescueWatch>> fetchHpjFarmerRescueWatch(
  String farmerProfileId, {
  int daysAhead = 21,
}) async {
  final cleanId = farmerProfileId.trim();
  if (cleanId.isEmpty) return const <HpjFarmerRescueWatch>[];

  try {
    final response = await supabase.rpc(
      'hpj_get_farmer_rescue_watch',
      params: <String, dynamic>{
        'p_farmer_profile_id': cleanId,
        'p_days_ahead': daysAhead,
      },
    );

    return (response as List)
        .map(
          (row) => HpjFarmerRescueWatch.fromSupabase(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .where((item) => item.rescueQuantity > 0)
        .toList(growable: false);
  } catch (error) {
    farmDebugLog('Farmer Rescue Watch unavailable: $error');
    return const <HpjFarmerRescueWatch>[];
  }
}

class _HpjFarmerRescueWatchCard extends StatelessWidget {
  final List<HpjFarmerRescueWatch> rows;
  final bool loading;

  const _HpjFarmerRescueWatchCard({
    required this.rows,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6DC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEFD89A)),
      ),
      child: loading
          ? const SizedBox(
              height: 54,
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.volunteer_activism_outlined,
                      color: Color(0xFFA56E08),
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Rescue Watch • HPJ is helping move confirmed surplus',
                        style: TextStyle(
                          color: Color(0xFF654C12),
                          fontSize: 11.2,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                const Text(
                  'Only HPJ-confirmed supply appears here. Customer Rescue Harvest reservations reduce the quantity at risk in real time.',
                  style: TextStyle(
                    color: Color(0xFF89733D),
                    fontSize: 8.8,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 9),
                ...rows.take(3).map(
                  (item) => Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.72),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.productName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: FarmColors.ink,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Text(
                          '${_farmerPartnerNumber(item.rescueQuantity)} ${item.unit} need homes',
                          style: const TextStyle(
                            color: Color(0xFF9D6808),
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
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

Future<String?> _hpjUploadHarvestJourneyPhoto() async {
  final user = supabase.auth.currentUser;
  if (user == null) throw Exception('Sign in before posting a crop update.');

  final picked = await pickProductImageFromDevice();
  if (picked == null) return null;
  if (picked.bytes.isEmpty) throw Exception('Choose a valid crop photo.');

  const maxBytes = 8 * 1024 * 1024;
  if (picked.bytes.length > maxBytes) {
    throw Exception('Crop photo must be under 8 MB.');
  }

  final mime = picked.mimeType.trim().toLowerCase();
  if (!const <String>{
    'image/jpeg', 'image/jpg', 'image/png', 'image/webp',
  }.contains(mime)) {
    throw Exception('Use a JPG, PNG or WebP crop photo.');
  }

  final rawName = picked.fileName.trim().isEmpty
      ? 'harvest-update.jpg'
      : picked.fileName.trim();
  final safeName = rawName.replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '-');
  final path = '${user.id}/${DateTime.now().millisecondsSinceEpoch}-$safeName';

  await supabase.storage.from('harvest-journey-media').uploadBinary(
        path,
        picked.bytes,
        fileOptions: FileOptions(contentType: mime, upsert: false),
      );

  return supabase.storage.from('harvest-journey-media').getPublicUrl(path);
}

Future<void> saveHpjHarvestJourneyUpdate({
  required HpjGrowSignal signal,
  required FarmerProfile profile,
  required String stage,
  required String message,
  String imageUrl = '',
}) async {
  if (!profile.isApproved) {
    throw Exception('Your farmer profile must be approved first.');
  }

  await supabase.rpc(
    'hpj_add_harvest_journey_update',
    params: <String, dynamic>{
      'p_circle_id': signal.circleId,
      'p_farmer_profile_id': profile.id,
      'p_stage': stage,
      'p_message': message.trim(),
      'p_image_url': imageUrl.trim().isEmpty ? null : imageUrl.trim(),
    },
  );
}

class _HpjHarvestJourneyUpdateSheet extends StatefulWidget {
  final HpjGrowSignal signal;
  final FarmerProfile profile;

  const _HpjHarvestJourneyUpdateSheet({
    required this.signal,
    required this.profile,
  });

  @override
  State<_HpjHarvestJourneyUpdateSheet> createState() =>
      _HpjHarvestJourneyUpdateSheetState();
}

class _HpjHarvestJourneyUpdateSheetState
    extends State<_HpjHarvestJourneyUpdateSheet> {
  final TextEditingController messageController = TextEditingController();
  String stage = 'growing';
  String imageUrl = '';
  bool choosingPhoto = false;
  bool saving = false;

  static const stages = <(String, String)>[
    ('planted', 'Planted'),
    ('established', 'Established'),
    ('growing', 'Growing'),
    ('flowering', 'Flowering'),
    ('fruiting', 'Producing'),
    ('harvest_ready', 'Harvest ready'),
    ('harvesting', 'Harvesting'),
    ('collected', 'Collected'),
  ];

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  Future<void> _choosePhoto() async {
    if (choosingPhoto || saving) return;
    setState(() => choosingPhoto = true);
    try {
      final uploaded = await _hpjUploadHarvestJourneyPhoto();
      if (!mounted) return;
      if (uploaded != null) setState(() => imageUrl = uploaded);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyAppError(error))),
      );
    } finally {
      if (mounted) setState(() => choosingPhoto = false);
    }
  }

  Future<void> _save() async {
    if (saving) return;
    final message = messageController.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tell customers what is happening with the crop.')),
      );
      return;
    }

    setState(() => saving = true);
    try {
      await saveHpjHarvestJourneyUpdate(
        signal: widget.signal,
        profile: widget.profile,
        stage: stage,
        message: message,
        imageUrl: imageUrl,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyAppError(error))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Container(
      constraints: const BoxConstraints(maxWidth: 680),
      margin: EdgeInsets.only(top: 20, bottom: kIsWeb ? 18 : 0),
      padding: EdgeInsets.fromLTRB(20, 18, 20, bottom + 22),
      decoration: const BoxDecoration(
        color: FarmColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Share a Harvest Journey update',
              style: TextStyle(
                color: FarmColors.ink,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.signal.productName} • Customers following this harvest can see the story from the field.',
              style: const TextStyle(
                color: FarmColors.mutedText,
                fontSize: 9.8,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Crop stage',
              style: TextStyle(
                color: FarmColors.ink,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: stages
                  .map(
                    (item) => ChoiceChip(
                      label: Text(item.$2),
                      selected: stage == item.$1,
                      onSelected: (_) => setState(() => stage = item.$1),
                      selectedColor: FarmColors.primary,
                      labelStyle: TextStyle(
                        color: stage == item.$1 ? Colors.white : FarmColors.ink,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
            const SizedBox(height: 13),
            InkWell(
              onTap: _choosePhoto,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: double.infinity,
                height: imageUrl.isEmpty ? 118 : 210,
                decoration: BoxDecoration(
                  color: FarmColors.cardSoft,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: FarmColors.line),
                ),
                child: imageUrl.isEmpty
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          choosingPhoto
                              ? const CircularProgressIndicator()
                              : const Icon(
                                  Icons.add_a_photo_outlined,
                                  color: FarmColors.primary,
                                  size: 29,
                                ),
                          const SizedBox(height: 7),
                          Text(
                            choosingPhoto ? 'Uploading crop photo...' : 'Add a crop photo',
                            style: const TextStyle(
                              color: FarmColors.mutedText,
                              fontSize: 9.4,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(17),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.image_not_supported_outlined),
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 13),
            TextField(
              controller: messageController,
              maxLines: 4,
              maxLength: 800,
              decoration: const InputDecoration(
                labelText: 'Field update',
                hintText: 'Example: Rain was good this week and the callaloo is establishing well…',
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: FarmColors.primarySoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Keep updates factual. Customers may be following or reserving this harvest, so photos and crop stages should reflect what is actually happening in the field.',
                style: TextStyle(
                  color: FarmColors.primary,
                  fontSize: 8.8,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: saving ? null : _save,
                icon: saving
                    ? const SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.publish_rounded),
                label: Text(saving ? 'Posting...' : 'Post Harvest Journey update'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HpjGrowSignalsEntryCard extends StatelessWidget {
  final FarmerProfile profile;

  const _HpjGrowSignalsEntryCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => HpjFarmerGrowSignalsScreen(profile: profile),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF7EA),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFCFE2C8)),
        ),
        child: const Row(
          children: [
            Icon(Icons.spa_rounded, color: FarmColors.primary, size: 22),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Grow Signals',
                    style: TextStyle(
                      color: FarmColors.ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'See real customer Harvest Circle reservations before you commit supply.',
                    style: TextStyle(
                      color: FarmColors.mutedText,
                      fontSize: 9.2,
                      height: 1.3,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: FarmColors.primary),
          ],
        ),
      ),
    );
  }
}

class _HpjFarmerMealPulseCard extends StatelessWidget {
  const _HpjFarmerMealPulseCard();

  String _growthLabel(HpjMealIngredientPulse item) {
    final value = item.growthPercent;
    if (value >= 1000) return '↑ 999%+';
    if (value >= 1) return '↑ ${value.toStringAsFixed(0)}%';
    if (value <= -1) return '↓ ${value.abs().toStringAsFixed(0)}%';
    return 'Steady';
  }

  Color _growthColor(HpjMealIngredientPulse item) {
    if (item.growthPercent > 0) return FarmColors.success;
    if (item.growthPercent < 0) return FarmColors.warning;
    return FarmColors.mutedText;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<HpjMealIngredientPulse>>(
      future: fetchHpjMealIngredientPulse(
        days: 7,
        limit: 6,
      ),
      builder: (context, snapshot) {
        final items =
            snapshot.data ?? const <HpjMealIngredientPulse>[];

        return Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0A4733),
                Color(0xFF176044),
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0A4733).withOpacity(.12),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.restaurant_menu_rounded,
                    color: Color(0xFFFFD85C),
                    size: 19,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Meal Pulse • What Jamaica is cooking',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13.2,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                items.isEmpty
                    ? 'As customers share meals, HPJ will show the ingredients appearing most often.'
                    : 'Social ingredient activity from meals shared with HPJ during the last 7 days.',
                style: TextStyle(
                  color: Colors.white.withOpacity(.78),
                  fontSize: 9.5,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (items.isNotEmpty) ...[
                const SizedBox(height: 12),
                ...items.take(5).map(
                  (item) => Container(
                    margin: const EdgeInsets.only(bottom: 7),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.08),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: Colors.white.withOpacity(.10),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.ingredient,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Text(
                          '${item.currentMentions} meal${item.currentMentions == 1 ? '' : 's'}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(.72),
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 9),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _growthLabel(item),
                            style: TextStyle(
                              color: _growthColor(item),
                              fontSize: 7.8,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4D4),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: Color(0xFF8A6511),
                      size: 16,
                    ),
                    SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        'Meal Pulse is a social signal, not a guaranteed order. Use it with HPJ Buyer Demand and confirmed supply needs before deciding what to plant.',
                        style: TextStyle(
                          color: Color(0xFF6B5314),
                          fontSize: 8.8,
                          height: 1.35,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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

class FarmerDemandBoardScreen extends StatefulWidget {
  final FarmerProfile profile;
  final String? initialWatchKey;
  final bool embedded;

  const FarmerDemandBoardScreen({
    super.key,
    required this.profile,
    this.initialWatchKey,
    this.embedded = false,
  });

  @override
  State<FarmerDemandBoardScreen> createState() =>
      _FarmerDemandBoardScreenState();
}

class _FarmerDemandBoardScreenState extends State<FarmerDemandBoardScreen> {
  int _days = 30;
  String _sortMode = 'next';
  String _filterMode = 'all';
  late Future<List<FarmerMarketDemandOpportunity>> _future;

  @override
  void initState() {
    super.initState();
    _future = fetchFarmerMarketDemandBoard(_days);
  }

  Future<void> _refresh() async {
    final next = fetchFarmerMarketDemandBoard(_days);
    setState(() {
      _future = next;
    });
    await next;
  }

  void _setDays(int days) {
    if (_days == days) return;
    setState(() {
      _days = days;
      _future = fetchFarmerMarketDemandBoard(_days);
    });
  }

  Color _signalColor(FarmerMarketDemandOpportunity item) {
    switch (item.demandSignal) {
      case 'committed_need':
        return FarmColors.danger;
      case 'urgent':
        return const Color(0xFFE3A51A);
      case 'opportunity':
        return FarmColors.primary;
      case 'covered_by_you':
        return FarmColors.success;
      default:
        return FarmColors.mutedText;
    }
  }

  String _sortLabel() {
    switch (_sortMode) {
      case 'gap':
        return 'Largest gap';
      case 'priority':
        return 'Priority';
      case 'next':
      default:
        return 'Next need';
    }
  }

  List<FarmerMarketDemandOpportunity> _filteredRows(
    List<FarmerMarketDemandOpportunity> source,
  ) {
    switch (_filterMode) {
      case 'open':
        return source.where((item) => item.opportunityGap > 0).toList();
      case 'urgent':
        return source
            .where(
              (item) =>
                  item.demandSignal == 'urgent' ||
                  item.demandSignal == 'committed_need',
            )
            .toList();
      case 'mine':
        return source.where((item) => item.myReportedSupply > 0).toList();
      case 'covered':
        return source.where((item) => item.opportunityGap <= 0).toList();
      case 'all':
      default:
        return List<FarmerMarketDemandOpportunity>.from(source);
    }
  }

  String _filterEmptyTitle() {
    switch (_filterMode) {
      case 'open':
        return 'No open supply gaps';
      case 'urgent':
        return 'No produce needed soon';
      case 'mine':
        return 'No matching reported supply';
      case 'covered':
        return 'No covered demand signals';
      case 'all':
      default:
        return 'No active demand signals';
    }
  }

  String _filterEmptyMessage() {
    switch (_filterMode) {
      case 'open':
        return 'All visible demand in this window is currently covered.';
      case 'urgent':
        return 'There are no urgent or near-term demand signals in this window.';
      case 'mine':
        return 'Report your expected harvest to see demand that matches your supply.';
      case 'covered':
        return 'No current demand signal is fully covered by your reported supply.';
      case 'all':
      default:
        return 'New business and wholesale requirements will appear here when HPJ has visible demand.';
    }
  }

  Widget _demandFilterChip({
    required String value,
    required String label,
    required int count,
    required IconData icon,
  }) {
    final selected = _filterMode == value;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (_filterMode == value) return;
          setState(() => _filterMode = value);
        },
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: selected ? FarmColors.primary : FarmColors.card,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? FarmColors.primary : FarmColors.line,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: FarmColors.primary.withOpacity(.14),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : const [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 15,
                color: selected ? Colors.white : FarmColors.deepGreen,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : FarmColors.ink,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                constraints: const BoxConstraints(minWidth: 22),
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 3,
                ),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withOpacity(.16)
                      : FarmColors.primarySoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: selected ? Colors.white : FarmColors.primary,
                    fontSize: 8.4,
                    height: 1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<FarmerMarketDemandOpportunity> _sortedRows(
    List<FarmerMarketDemandOpportunity> source,
  ) {
    final rows = List<FarmerMarketDemandOpportunity>.from(source);

    int priority(FarmerMarketDemandOpportunity item) {
      switch (item.demandSignal) {
        case 'committed_need':
          return 4;
        case 'urgent':
          return 3;
        case 'opportunity':
          return 2;
        case 'covered_by_you':
          return 1;
        default:
          return 0;
      }
    }

    rows.sort((a, b) {
      if (_sortMode == 'gap') {
        final gap = b.opportunityGap.compareTo(a.opportunityGap);
        if (gap != 0) return gap;
      } else if (_sortMode == 'priority') {
        final result = priority(b).compareTo(priority(a));
        if (result != 0) return result;
      } else {
        final ad = a.nextNeedBy;
        final bd = b.nextNeedBy;
        if (ad != null && bd != null) {
          final result = ad.compareTo(bd);
          if (result != 0) return result;
        } else if (ad != null) {
          return -1;
        } else if (bd != null) {
          return 1;
        }
      }

      return b.visibleDemand.compareTo(a.visibleDemand);
    });

    return rows;
  }

  Future<void> _reportSupply(FarmerMarketDemandOpportunity demand) async {
    if (!widget.profile.isApproved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your farmer profile must be approved first.'),
        ),
      );
      return;
    }

    final qty = TextEditingController(
      text: demand.opportunityGap > 0
          ? _farmerPartnerNumber(demand.opportunityGap)
          : '',
    );
    final notes = TextEditingController(
      text: 'Reported from HPJ Market Demand board.',
    );
    DateTime? harvestDate = demand.nextNeedBy;
    bool saving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> pickDate() async {
              final now = DateTime.now();
              final first = DateTime(now.year, now.month, now.day);
              final initial =
                  harvestDate == null || harvestDate!.isBefore(first)
                      ? first.add(const Duration(days: 7))
                      : harvestDate!;
              final picked = await showDatePicker(
                context: sheetContext,
                initialDate: initial,
                firstDate: first,
                lastDate: first.add(const Duration(days: 730)),
              );
              if (picked == null) return;
              setSheetState(() => harvestDate = picked);
            }

            Future<void> save() async {
              if (saving) return;
              final quantity = double.tryParse(
                qty.text.trim().replaceAll(',', ''),
              );
              if (quantity == null || !quantity.isFinite || quantity <= 0) {
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  const SnackBar(
                    content: Text('Enter the quantity you expect to supply.'),
                  ),
                );
                return;
              }
              setSheetState(() => saving = true);
              try {
                await createFarmerSupplyForecast(
                  cropName: demand.productName,
                  expectedQuantity: quantity,
                  unit: demand.unit,
                  expectedHarvestDate: harvestDate,
                  status: 'expected',
                  notes: notes.text.trim(),
                );
                if (!sheetContext.mounted) return;
                Navigator.pop(sheetContext);
                try {
                  await _refresh();
                } catch (error) {
                  farmDebugLog(
                    'Demand refresh after supply save skipped: $error',
                  );
                }
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${demand.productName} supply reported. HPJ can now review it in Matching.',
                    ),
                  ),
                );
              } catch (error) {
                if (!sheetContext.mounted) return;
                setSheetState(() => saving = false);
                ScaffoldMessenger.of(sheetContext).showSnackBar(
                  SnackBar(content: Text(friendlyAppError(error))),
                );
              }
            }

            return Container(
              decoration: const BoxDecoration(
                color: FarmColors.card,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 16,
                  bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 22,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: FarmColors.line,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'I Can Supply ${demand.productName}',
                      style: const TextStyle(
                        color: FarmColors.ink,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Open opportunity: ${_farmerPartnerNumber(demand.opportunityGap)} ${demand.unit}. '
                      'Tell HPJ what you expect to have ready.',
                      style: const TextStyle(
                        color: FarmColors.mutedText,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: qty,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Expected quantity (${demand.unit})',
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Expected harvest date',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(_farmerPartnerDate(harvestDate)),
                      trailing: const Icon(Icons.calendar_today_outlined),
                      onTap: pickDate,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: notes,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Notes'),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: saving ? null : save,
                        icon: const Icon(Icons.agriculture_outlined),
                        label: Text(saving ? 'Saving...' : 'Report Supply'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    qty.dispose();
    notes.dispose();
  }

  Widget _approvalContent() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 560),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: FarmColors.card,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: FarmColors.line),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.verified_user_outlined,
                color: FarmColors.warning,
                size: 42,
              ),
              SizedBox(height: 12),
              Text(
                'Farmer approval required',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: FarmColors.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'HPJ must approve your farmer profile before market demand is shown.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: FarmColors.mutedText,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
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
    if (!widget.profile.isApproved) {
      final content = _approvalContent();
      if (widget.embedded) return content;
      return Scaffold(
        backgroundColor: FarmColors.background,
        appBar: AppBar(title: const Text('HPJ Demand')),
        body: content,
      );
    }

    final demandContent = FutureBuilder<List<FarmerMarketDemandOpportunity>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            snapshot.data == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError && snapshot.data == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cloud_off_outlined,
                    color: FarmColors.mutedText,
                    size: 36,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    friendlyAppError(snapshot.error!),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: FarmColors.mutedText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => setState(() {
                      _future = fetchFarmerMarketDemandBoard(_days);
                    }),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final allRows =
            snapshot.data ?? const <FarmerMarketDemandOpportunity>[];
        final requestedWatchKey = widget.initialWatchKey?.trim() ?? '';
        final focusedRows = requestedWatchKey.isEmpty
            ? const <FarmerMarketDemandOpportunity>[]
            : allRows
                .where(
                  (item) =>
                      hpjFarmerDemandWatchKey(item.productName, item.unit) ==
                      requestedWatchKey,
                )
                .toList();
        final exactDemandFound = focusedRows.isNotEmpty;
        final sourceRows = exactDemandFound ? focusedRows : allRows;

        final urgentCount = sourceRows
            .where(
              (item) =>
                  item.demandSignal == 'urgent' ||
                  item.demandSignal == 'committed_need',
            )
            .length;
        final opportunityCount =
            sourceRows.where((item) => item.opportunityGap > 0).length;
        final coveredCount =
            sourceRows.where((item) => item.opportunityGap <= 0).length;
        final mySupplyCount =
            sourceRows.where((item) => item.myReportedSupply > 0).length;

        final rows = _sortedRows(_filteredRows(sourceRows));

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 110),
            children: [
              _PremiumFarmerDemandHero(
                farmerId: widget.profile.id,
                farmName: widget.profile.farmName,
                days: _days,
                signalCount: rows.length,
                opportunityCount: opportunityCount,
                urgentCount: urgentCount,
                coveredCount: coveredCount,
                onDaysChanged: _setDays,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: FarmColors.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: FarmColors.line),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      color: FarmColors.primary,
                      size: 18,
                    ),
                    SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'Demand is aggregated by HPJ. Customer identity, private pricing and HPJ margin data are not shown to farmers.',
                        style: TextStyle(
                          color: FarmColors.mutedText,
                          fontSize: 9.8,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _HpjGrowSignalsEntryCard(profile: widget.profile),
              const SizedBox(height: 12),
              const _HpjFarmerMealPulseCard(),

              if (requestedWatchKey.isNotEmpty) ...[
                const SizedBox(height: 12),
                _FarmerNotificationFocusNotice(
                  found: exactDemandFound,
                  foundMessage:
                      'Opened from your notification. Showing the matching buyer-demand signal.',
                  missingMessage:
                      'That demand signal has changed or is no longer active. Showing current buyer demand instead.',
                ),
              ],
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Buyer demand opportunities',
                          style: TextStyle(
                            color: FarmColors.ink,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Compare what HPJ needs with what you have already reported.',
                          style: TextStyle(
                            color: FarmColors.mutedText,
                            fontSize: 10.2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (rows.isNotEmpty) ...[
                    Text(
                      _filterMode == 'all'
                          ? '${sourceRows.length} signal${sourceRows.length == 1 ? '' : 's'}'
                          : '${rows.length} of ${sourceRows.length}',
                      style: const TextStyle(
                        color: FarmColors.mutedText,
                        fontSize: 9.8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 10),
                    PopupMenuButton<String>(
                      initialValue: _sortMode,
                      onSelected: (value) {
                        if (value == _sortMode) return;
                        setState(() => _sortMode = value);
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'next',
                          child: Text('Next need'),
                        ),
                        PopupMenuItem(
                          value: 'gap',
                          child: Text('Largest gap'),
                        ),
                        PopupMenuItem(
                          value: 'priority',
                          child: Text('Priority'),
                        ),
                      ],
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: FarmColors.card,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: FarmColors.line),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.swap_vert_rounded,
                              size: 16,
                              color: FarmColors.deepGreen,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Sort: ${_sortLabel()}',
                              style: const TextStyle(
                                color: FarmColors.ink,
                                fontSize: 9.3,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 16,
                              color: FarmColors.mutedText,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: FarmColors.card.withOpacity(.72),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: FarmColors.line),
                ),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(right: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            size: 16,
                            color: FarmColors.deepGreen,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Filter',
                            style: TextStyle(
                              color: FarmColors.ink,
                              fontSize: 9.8,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _demandFilterChip(
                      value: 'all',
                      label: 'All',
                      count: sourceRows.length,
                      icon: Icons.grid_view_rounded,
                    ),
                    _demandFilterChip(
                      value: 'open',
                      label: 'Needs supply',
                      count: opportunityCount,
                      icon: Icons.add_circle_outline_rounded,
                    ),
                    _demandFilterChip(
                      value: 'urgent',
                      label: 'Needed soon',
                      count: urgentCount,
                      icon: Icons.schedule_rounded,
                    ),
                    _demandFilterChip(
                      value: 'mine',
                      label: 'My supply',
                      count: mySupplyCount,
                      icon: Icons.agriculture_outlined,
                    ),
                    _demandFilterChip(
                      value: 'covered',
                      label: 'Covered',
                      count: coveredCount,
                      icon: Icons.verified_outlined,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (rows.isEmpty)
                FarmEmptyState(
                  icon: Icons.filter_alt_off_outlined,
                  title: _filterEmptyTitle(),
                  message: _filterEmptyMessage(),
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final desktop = HpjWebUi.isDesktop(context);
                    final columns = desktop && constraints.maxWidth >= 900
                        ? 3
                        : constraints.maxWidth >= 720
                            ? 2
                            : 1;
                    const gap = 12.0;
                    final width = columns == 1
                        ? constraints.maxWidth
                        : (constraints.maxWidth - gap * (columns - 1)) /
                            columns;

                    return Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: [
                        for (final item in rows)
                          SizedBox(
                            width: width,
                            child: _PremiumFarmerDemandCard(
                              item: item,
                              signalColor: _signalColor(item),
                              onReportSupply: item.opportunityGap > 0
                                  ? () => _reportSupply(item)
                                  : null,
                            ),
                          ),
                      ],
                    );
                  },
                ),
            ],
          ),
        );
      },
    );

    if (widget.embedded) {
      return demandContent;
    }

    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: AppBar(title: const Text('HPJ Demand')),
      body: demandContent,
    );
  }
}

// =====================================================
// HPJ PHASE 80 — ELITE FARMER DEMAND VISUAL SYSTEM
// Self-contained desktop/web hero helpers for this file.
// Uses the farmer's real public farm cover image when available.
// Mobile/native keeps the compact green presentation.
// =====================================================

class _EliteFarmerDemandHeroSurface extends StatelessWidget {
  final String farmerId;
  final IconData fallbackIcon;
  final Widget child;
  final Alignment imageAlignment;

  const _EliteFarmerDemandHeroSurface({
    required this.farmerId,
    required this.fallbackIcon,
    required this.child,
    this.imageAlignment = Alignment.center,
  });

  Widget _background(String? coverUrl) {
    final cleanCover = cleanHostedImageUrl(coverUrl);

    if (cleanCover == null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF043A29),
                  Color(0xFF09613F),
                  Color(0xFF438354),
                ],
              ),
            ),
          ),
          Positioned(
            right: -20,
            top: -30,
            child: Icon(
              fallbackIcon,
              size: 240,
              color: Colors.white.withOpacity(.055),
            ),
          ),
        ],
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          cleanCover,
          fit: BoxFit.cover,
          alignment: imageAlignment,
          filterQuality: FilterQuality.high,
          errorBuilder: (_, __, ___) => const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF043A29),
                  Color(0xFF09613F),
                  Color(0xFF438354),
                ],
              ),
            ),
          ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Color(0xF0043325),
                Color(0xD9085036),
                Color(0x9E165C3D),
                Color(0x553D7650),
              ],
              stops: [0, .48, .76, 1],
            ),
          ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Color(0x52001810),
                Color(0x00001810),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final desktopWeb = HpjWebUi.isDesktop(context);

    Widget shell(String? coverUrl) {
      return Container(
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(desktopWeb ? 28 : 22),
          boxShadow: desktopWeb
              ? [
                  BoxShadow(
                    color: const Color(0xFF073F2C).withOpacity(.16),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                  ),
                ]
              : const [],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: desktopWeb ? _background(coverUrl) : _background(null),
            ),
            Padding(
              padding: EdgeInsets.all(desktopWeb ? 24 : 20),
              child: child,
            ),
          ],
        ),
      );
    }

    if (!desktopWeb) return shell(null);

    return FutureBuilder<FarmPublicProfileRecord?>(
      future: fetchFarmPublicProfile(
        farmerId,
        includeUnpublished: true,
      ),
      builder: (context, snapshot) => shell(snapshot.data?.coverImageUrl),
    );
  }
}

class _EliteFarmerDemandHeroMetric extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final String? helper;
  final Color accent;
  final double minWidth;

  const _EliteFarmerDemandHeroMetric({
    required this.icon,
    required this.value,
    required this.label,
    this.helper,
    this.accent = const Color(0xFFFFC84D),
    this.minWidth = 175,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        minWidth: minWidth,
        minHeight: helper == null ? 76 : 86,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.095),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: Colors.white.withOpacity(.23),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 43,
            height: 43,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withOpacity(.14),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              size: 23,
              color: accent,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.2,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(.93),
                    fontSize: 10.2,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (helper != null && helper!.trim().isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    helper!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(.66),
                      fontSize: 8.5,
                      height: 1.1,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class _EliteFarmerHeroQuote extends StatelessWidget {
  final String line1;
  final String line2;

  const _EliteFarmerHeroQuote({
    required this.line1,
    required this.line2,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          line1,
          textAlign: TextAlign.right,
          style: TextStyle(
            color: Colors.white.withOpacity(.93),
            fontSize: 17,
            height: 1.08,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          line2,
          textAlign: TextAlign.right,
          style: const TextStyle(
            color: Color(0xFFFFC84D),
            fontSize: 16.5,
            height: 1.08,
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 7),
        Container(
          width: 76,
          height: 3,
          decoration: BoxDecoration(
            color: const Color(0xFFFFB813),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ],
    );
  }
}

class _PremiumFarmerDemandHero extends StatelessWidget {
  final String farmerId;
  final String farmName;
  final int days;
  final int signalCount;
  final int opportunityCount;
  final int urgentCount;
  final int coveredCount;
  final ValueChanged<int> onDaysChanged;

  const _PremiumFarmerDemandHero({
    required this.farmerId,
    required this.farmName,
    required this.days,
    required this.signalCount,
    required this.opportunityCount,
    required this.urgentCount,
    required this.coveredCount,
    required this.onDaysChanged,
  });

  Widget _rangeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DEMAND WINDOW',
          style: TextStyle(
            color: Colors.white.withOpacity(.76),
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: .9,
          ),
        ),
        const SizedBox(height: 9),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final value in const [14, 30, 60])
              _PremiumDemandRangeChip(
                label: '$value days',
                selected: days == value,
                onTap: () => onDaysChanged(value),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final farm = farmName.trim().isEmpty ? 'Your farm' : farmName.trim();

    return _EliteFarmerDemandHeroSurface(
      farmerId: farmerId,
      fallbackIcon: Icons.trending_up_rounded,
      imageAlignment: Alignment.center,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 980;

          final metrics = Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _EliteFarmerDemandHeroMetric(
                icon: Icons.receipt_long_outlined,
                value: '$signalCount',
                label: 'Signals',
                helper: 'Visible market needs',
                minWidth: wide ? 168 : 148,
              ),
              _EliteFarmerDemandHeroMetric(
                icon: Icons.track_changes_rounded,
                value: '$opportunityCount',
                label: 'Open gaps',
                helper: 'Supply still needed',
                minWidth: wide ? 168 : 148,
              ),
              _EliteFarmerDemandHeroMetric(
                icon: Icons.local_fire_department_outlined,
                value: '$urgentCount',
                label: 'Priority',
                helper: 'Needs attention',
                minWidth: wide ? 168 : 148,
              ),
              _EliteFarmerDemandHeroMetric(
                icon: Icons.eco_outlined,
                value: '$coveredCount',
                label: 'Covered',
                helper: 'Matched by supply',
                accent: const Color(0xFF9DE27C),
                minWidth: wide ? 168 : 148,
              ),
            ],
          );

          final intro = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'HPJ BUYER SIGNALS',
                style: TextStyle(
                  color: Color(0xFFFFD15A),
                  fontSize: 10.4,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'See what the market needs',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: wide ? 35 : 25,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.9,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$farm • Use visible HPJ demand to decide what supply to report next.',
                style: TextStyle(
                  color: Colors.white.withOpacity(.90),
                  fontSize: 11.8,
                  height: 1.38,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          intro,
                          const SizedBox(height: 20),
                          metrics,
                        ],
                      ),
                    ),
                    const SizedBox(width: 28),
                    Container(
                      width: 275,
                      padding: const EdgeInsets.only(left: 23),
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: Colors.white.withOpacity(.22),
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const _EliteFarmerHeroQuote(
                            line1: 'Local Demand',
                            line2: 'Real Opportunities',
                          ),
                          const SizedBox(height: 24),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: _rangeSelector(),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              else ...[
                intro,
                const SizedBox(height: 17),
                metrics,
                const SizedBox(height: 17),
                _rangeSelector(),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _PremiumDemandRangeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PremiumDemandRangeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.white.withOpacity(0.09),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? Colors.white : Colors.white.withOpacity(0.24),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? const Color(0xFF073F2C) : Colors.white,
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _PremiumFarmerDemandCard extends StatelessWidget {
  final FarmerMarketDemandOpportunity item;
  final Color signalColor;
  final VoidCallback? onReportSupply;

  const _PremiumFarmerDemandCard({
    required this.item,
    required this.signalColor,
    required this.onReportSupply,
  });

  Widget _metric({
    required String label,
    required double value,
    required bool highlight,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: highlight
              ? signalColor.withOpacity(0.075)
              : const Color(0xFFF8FAF6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: FarmColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: FarmColors.mutedText,
                fontSize: 8.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _farmerPartnerNumber(value),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: highlight && value > 0 ? signalColor : FarmColors.ink,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              item.unit,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: FarmColors.mutedText,
                fontSize: 8.2,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final openGap = item.opportunityGap > 0;
    final description = openGap
        ? 'HPJ still needs ${_farmerPartnerNumber(item.opportunityGap)} ${item.unit} from the farmer network.'
        : 'Your reported supply currently covers this visible market need.';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: FarmColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: openGap ? signalColor.withOpacity(0.22) : FarmColors.line,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF173B30).withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HpjProductThumb(
                productName: item.productName,
                size: 128,
                radius: 17,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: signalColor.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          item.signalLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: signalColor,
                            fontSize: 8.4,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item.productName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: FarmColors.ink,
                        fontSize: 17,
                        height: 1.04,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Next need • ${_farmerPartnerDate(item.nextNeedBy)}',
                      style: const TextStyle(
                        color: FarmColors.mutedText,
                        fontSize: 9.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: FarmColors.mutedText,
                        fontSize: 9.2,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              _metric(
                label: 'Market need',
                value: item.visibleDemand,
                highlight: false,
              ),
              const SizedBox(width: 7),
              _metric(
                label: 'Your supply',
                value: item.myReportedSupply,
                highlight: false,
              ),
              const SizedBox(width: 7),
              _metric(
                label: 'Open gap',
                value: item.opportunityGap,
                highlight: true,
              ),
            ],
          ),
          const SizedBox(height: 9),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F6F2),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Text(
              openGap
                  ? 'Approved ${_farmerPartnerNumber(item.approvedDemand)} • Standing ${_farmerPartnerNumber(item.standingDemand)} • Planning ${_farmerPartnerNumber(item.planningDemand)} ${item.unit}'
                  : 'Covered by your reported supply',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: openGap ? FarmColors.mutedText : FarmColors.success,
                fontSize: 8.7,
                height: 1.25,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (onReportSupply != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: FilledButton.icon(
                onPressed: onReportSupply,
                icon: const Icon(Icons.agriculture_outlined, size: 17),
                label: const Text('I Can Supply This'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FarmerDemandSupplySheet extends StatefulWidget {
  final FarmerMarketDemandOpportunity demand;

  const _FarmerDemandSupplySheet({
    required this.demand,
  });

  @override
  State<_FarmerDemandSupplySheet> createState() =>
      _FarmerDemandSupplySheetState();
}

class _FarmerDemandSupplySheetState extends State<_FarmerDemandSupplySheet> {
  late final TextEditingController quantityController;
  late final TextEditingController notesController;

  late DateTime harvestDate;
  bool saving = false;

  FarmerMarketDemandOpportunity get demand => widget.demand;

  @override
  void initState() {
    super.initState();

    quantityController = TextEditingController(
      text: demand.opportunityGap > 0
          ? _farmerPartnerNumber(
              demand.opportunityGap,
            )
          : '',
    );

    notesController = TextEditingController(
      text: 'Reported from HPJ Market Demand board.',
    );

    final now = DateTime.now();
    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final suggested = demand.nextNeedBy;

    harvestDate = suggested == null || suggested.isBefore(today)
        ? today.add(
            const Duration(days: 7),
          )
        : suggested;
  }

  @override
  void dispose() {
    quantityController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final first = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final picked = await showDatePicker(
      context: context,
      initialDate: harvestDate.isBefore(first)
          ? first.add(
              const Duration(days: 7),
            )
          : harvestDate,
      firstDate: first,
      lastDate: first.add(
        const Duration(days: 730),
      ),
    );

    if (!mounted || picked == null) {
      return;
    }

    setState(() {
      harvestDate = picked;
    });
  }

  Future<void> _save() async {
    if (saving) return;

    final quantity = double.tryParse(
      quantityController.text.trim().replaceAll(',', ''),
    );

    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Enter the quantity you expect to supply.',
          ),
        ),
      );
      return;
    }

    setState(() {
      saving = true;
    });

    try {
      await createFarmerSupplyForecast(
        cropName: demand.productName,
        expectedQuantity: quantity,
        unit: demand.unit,
        expectedHarvestDate: harvestDate,
        status: 'expected',
        notes: notesController.text.trim(),
      );

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        saving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            friendlyAppError(error),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      duration: const Duration(
        milliseconds: 160,
      ),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: FarmColors.card,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(26),
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            18,
            14,
            18,
            22,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: FarmColors.line,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Report ${demand.productName} Supply',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Market need: ${_farmerPartnerNumber(demand.visibleDemand)} ${demand.unit} • '
                'Your reported supply: ${_farmerPartnerNumber(demand.myReportedSupply)} ${demand.unit}',
                style: const TextStyle(
                  color: FarmColors.mutedText,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: quantityController,
                enabled: !saving,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Expected quantity (${demand.unit})',
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: saving ? null : _pickDate,
                borderRadius: BorderRadius.circular(16),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Expected harvest date',
                    suffixIcon: Icon(
                      Icons.calendar_today_outlined,
                    ),
                  ),
                  child: Text(
                    _farmerPartnerDate(
                      harvestDate,
                    ),
                    style: const TextStyle(
                      color: FarmColors.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                enabled: !saving,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: saving ? null : _save,
                  icon: saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.add_circle_outline,
                        ),
                  label: Text(
                    saving ? 'Saving...' : 'Report Supply',
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

class FarmerCollectionScheduleScreen extends StatefulWidget {
  final FarmerProfile profile;
  final String? initialCollectionId;

  const FarmerCollectionScheduleScreen({
    super.key,
    required this.profile,
    this.initialCollectionId,
  });

  @override
  State<FarmerCollectionScheduleScreen> createState() =>
      _FarmerCollectionScheduleScreenState();
}

class _FarmerCollectionScheduleScreenState
    extends State<FarmerCollectionScheduleScreen> {
  late Future<List<FarmerCollectionScheduleItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = fetchFarmerCollectionSchedule();
  }

  Future<void> _refresh() async {
    final next = fetchFarmerCollectionSchedule();
    setState(() {
      _future = next;
    });
    await next;
  }

  Color _statusColor(FarmerCollectionScheduleItem item) {
    if (item.stopStatus == 'collected' || item.receivingStatus == 'completed') {
      return FarmColors.success;
    }
    if (item.stopStatus == 'skipped' || item.stopStatus == 'cancelled') {
      return FarmColors.danger;
    }
    if (item.runStatus == 'in_progress') return FarmColors.warning;
    return FarmColors.primary;
  }

  String _statusLabel(FarmerCollectionScheduleItem item) {
    if (item.receivingStatus == 'completed') return 'Received';
    if (item.stopStatus == 'collected') return 'Collected';
    if (item.stopStatus == 'skipped') return 'Skipped';
    if (item.stopStatus == 'cancelled') return 'Cancelled';
    if (item.runStatus == 'in_progress') return 'On Route';
    return 'Scheduled';
  }

  bool _isComplete(FarmerCollectionScheduleItem item) {
    return item.receivingStatus == 'completed' ||
        item.stopStatus == 'collected' ||
        item.stopStatus == 'completed';
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.profile.isApproved) {
      return Scaffold(
        backgroundColor: FarmColors.background,
        appBar: AppBar(title: const Text('Collections')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: FarmEmptyState(
              icon: Icons.verified_user_outlined,
              title: 'Farmer approval required',
              message:
                  'Collection schedules are available after HPJ approves your farmer profile.',
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: AppBar(title: const Text('Collections')),
      body: FutureBuilder<List<FarmerCollectionScheduleItem>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError && snapshot.data == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  friendlyAppError(snapshot.error!),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final allRows =
              snapshot.data ?? const <FarmerCollectionScheduleItem>[];

          final requestedCollectionId =
              widget.initialCollectionId?.trim() ?? '';

          final focusedRows = requestedCollectionId.isEmpty
              ? const <FarmerCollectionScheduleItem>[]
              : allRows
                  .where(
                    (item) => item.id.trim() == requestedCollectionId,
                  )
                  .toList();

          final exactCollectionFound = focusedRows.isNotEmpty;
          final rows = exactCollectionFound ? focusedRows : allRows;

          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);

          final upcoming = allRows
              .where(
                (item) =>
                    !item.collectionDate.isBefore(today) &&
                    item.stopStatus != 'cancelled' &&
                    !_isComplete(item),
              )
              .length;

          final onRoute =
              allRows.where((item) => item.runStatus == 'in_progress').length;

          final completed = allRows.where(_isComplete).length;

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
              children: [
                _PremiumFarmerCollectionsHero(
                  farmName: widget.profile.farmName,
                  total: allRows.length,
                  upcoming: upcoming,
                  onRoute: onRoute,
                  completed: completed,
                ),
                const SizedBox(height: 14),
                if (requestedCollectionId.isNotEmpty) ...[
                  _FarmerNotificationFocusNotice(
                    found: exactCollectionFound,
                    foundMessage:
                        'Opened from your notification. Showing the related collection stop.',
                    missingMessage:
                        'That collection stop is no longer available. Showing your current collection schedule instead.',
                  ),
                  const SizedBox(height: 12),
                ],
                const Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Collection schedule',
                        style: TextStyle(
                          color: FarmColors.ink,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.lock_outline_rounded,
                      color: FarmColors.mutedText,
                      size: 17,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Only collection stops linked to your farmer profile are shown.',
                  style: TextStyle(
                    color: FarmColors.mutedText,
                    fontSize: 9.6,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                if (rows.isEmpty)
                  const FarmEmptyState(
                    icon: Icons.local_shipping_outlined,
                    title: 'No collections scheduled',
                    message:
                        'Once HPJ reserves your supply and schedules collection, the stop will appear here.',
                  )
                else
                  ...rows.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _PremiumFarmerCollectionCard(
                        item: item,
                        statusLabel: _statusLabel(item),
                        statusColor: _statusColor(item),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PremiumFarmerCollectionsHero extends StatelessWidget {
  final String farmName;
  final int total;
  final int upcoming;
  final int onRoute;
  final int completed;

  const _PremiumFarmerCollectionsHero({
    required this.farmName,
    required this.total,
    required this.upcoming,
    required this.onRoute,
    required this.completed,
  });

  Widget _metric(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.12),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withOpacity(.16)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withOpacity(.72),
                fontSize: 8.8,
                fontWeight: FontWeight.w800,
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            FarmColors.deepGreen,
            FarmColors.green,
            Color(0xFF4E8157),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'HPJ COLLECTIONS',
            style: TextStyle(
              color: Color(0xFFCFE0CF),
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              letterSpacing: .9,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            upcoming > 0
                ? '$upcoming upcoming collection${upcoming == 1 ? '' : 's'}'
                : 'No upcoming collection',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Follow scheduled produce from your farm through HPJ collection and receiving.',
            style: TextStyle(
              color: Colors.white.withOpacity(.82),
              fontSize: 10.5,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              _metric('$total', 'Stops'),
              const SizedBox(width: 8),
              _metric('$onRoute', 'On route'),
              const SizedBox(width: 8),
              _metric('$completed', 'Received'),
            ],
          ),
        ],
      ),
    );
  }
}

class _PremiumFarmerCollectionCard extends StatelessWidget {
  final FarmerCollectionScheduleItem item;
  final String statusLabel;
  final Color statusColor;

  const _PremiumFarmerCollectionCard({
    required this.item,
    required this.statusLabel,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final method = item.collectionMethod == 'farmer_delivery'
        ? 'Farmer Delivery'
        : 'HPJ Collection';

    final transport = <String>[
      item.driverName,
      item.vehicleLabel,
    ].where((value) => value.isNotEmpty).join(' • ');

    return FarmCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  statusLabel == 'Received'
                      ? Icons.inventory_2_outlined
                      : Icons.local_shipping_outlined,
                  color: statusColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: FarmColors.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${_farmerPartnerDate(item.collectionDate)} • $method • Stop ${item.sequenceNo}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: FarmColors.mutedText,
                        fontSize: 9.5,
                        height: 1.25,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(.09),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: statusColor.withOpacity(.16)),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F8F5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: FarmColors.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'PLANNED',
                        style: TextStyle(
                          color: FarmColors.mutedText,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${_farmerPartnerNumber(item.plannedQuantity)} ${item.unit}',
                        style: const TextStyle(
                          color: FarmColors.ink,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: item.collectedQuantity > 0
                        ? FarmColors.primarySoft
                        : const Color(0xFFF8F8F5),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: FarmColors.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'COLLECTED',
                        style: TextStyle(
                          color: FarmColors.mutedText,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.collectedQuantity > 0
                            ? '${_farmerPartnerNumber(item.collectedQuantity)} ${item.unit}'
                            : 'Pending',
                        style: const TextStyle(
                          color: FarmColors.deepGreen,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (transport.isNotEmpty) ...[
            const SizedBox(height: 9),
            Row(
              children: [
                const Icon(
                  Icons.badge_outlined,
                  size: 16,
                  color: FarmColors.mutedText,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    transport,
                    style: const TextStyle(
                      color: FarmColors.mutedText,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (item.qualityGrade.isNotEmpty) ...[
            const SizedBox(height: 7),
            Row(
              children: [
                const Icon(
                  Icons.verified_outlined,
                  size: 16,
                  color: FarmColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Quality grade: ${item.qualityGrade}',
                  style: const TextStyle(
                    color: FarmColors.primary,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],
          if (item.note.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8F5),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Text(
                item.note,
                style: const TextStyle(
                  color: FarmColors.mutedText,
                  fontSize: 9.2,
                  height: 1.3,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}


// ============================================================================
// HPJ PHASE 97 — FARMER GROW INTELLIGENCE
// ============================================================================

class _HpjP97FarmerIntelBundle {
  final List<HpjGrowIntelligenceSignal> intelligence;
  final List<HpjParishDemandPulse> parish;
  final List<HpjGrowSignal> growSignals;

  const _HpjP97FarmerIntelBundle({
    required this.intelligence,
    required this.parish,
    required this.growSignals,
  });
}

Future<_HpjP97FarmerIntelBundle> _fetchHpjP97FarmerIntelBundle() async {
  final results = await Future.wait<dynamic>([
    fetchHpjGrowIntelligence(limit: 60),
    fetchHpjParishDemandPulse(limit: 160),
    fetchHpjGrowSignals(),
  ]);

  return _HpjP97FarmerIntelBundle(
    intelligence: results[0] as List<HpjGrowIntelligenceSignal>,
    parish: results[1] as List<HpjParishDemandPulse>,
    growSignals: results[2] as List<HpjGrowSignal>,
  );
}

class HpjFarmerGrowIntelligenceScreen extends StatefulWidget {
  final FarmerProfile profile;

  const HpjFarmerGrowIntelligenceScreen({
    super.key,
    required this.profile,
  });

  @override
  State<HpjFarmerGrowIntelligenceScreen> createState() =>
      _HpjFarmerGrowIntelligenceScreenState();
}

class _HpjFarmerGrowIntelligenceScreenState
    extends State<HpjFarmerGrowIntelligenceScreen> {
  String _filter = 'gap';
  late Future<_HpjP97FarmerIntelBundle> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetchHpjP97FarmerIntelBundle();
  }

  Future<void> _refresh() async {
    final next = _fetchHpjP97FarmerIntelBundle();
    if (mounted) setState(() => _future = next);
    await next;
  }

  List<HpjGrowIntelligenceSignal> _filtered(
    List<HpjGrowIntelligenceSignal> source,
  ) {
    switch (_filter) {
      case 'high':
        return source.where((e) => e.confidence == 'high').toList();
      case 'watch':
        return source.where((e) => e.signalStatus == 'watch').toList();
      case 'covered':
        return source.where((e) => e.signalStatus == 'covered').toList();
      case 'all':
        return source;
      default:
        return source.where((e) => e.hasVerifiedGap).toList();
    }
  }

  HpjGrowSignal? _growSignalFor(
    HpjGrowIntelligenceSignal intel,
    List<HpjGrowSignal> signals,
  ) {
    final id = intel.harvestCircleId?.trim() ?? '';
    if (id.isEmpty) return null;
    for (final signal in signals) {
      if (signal.circleId == id) return signal;
    }
    return null;
  }

  Future<void> _actOn(
    HpjGrowIntelligenceSignal intel,
    List<HpjGrowSignal> growSignals,
  ) async {
    final signal = _growSignalFor(intel, growSignals);
    if (signal == null) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => FarmerDemandBoardScreen(profile: widget.profile),
        ),
      );
      return;
    }

    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _HpjGrowSignalCommitSheet(
        signal: signal,
        profile: widget.profile,
      ),
    );
    if (changed == true && mounted) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final desktop = kIsWeb && MediaQuery.sizeOf(context).width >= 980;

    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          'Grow Intelligence',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<_HpjP97FarmerIntelBundle>(
          future: _future,
          builder: (context, snapshot) {
            final data = snapshot.data;
            final all = data?.intelligence ?? const <HpjGrowIntelligenceSignal>[];
            final rows = _filtered(all);
            final verifiedGaps = all.where((e) => e.hasVerifiedGap).length;
            final highConfidence = all.where((e) => e.confidence == 'high').length;
            final guardCount = all.where((e) => e.overplantGuard).length;

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                desktop ? 28 : 14,
                desktop ? 24 : 14,
                desktop ? 28 : 14,
                48,
              ),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1180),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HpjP97FarmerIntelHero(
                          verifiedGaps: verifiedGaps,
                          highConfidence: highConfidence,
                          guardCount: guardCount,
                        ),
                        const SizedBox(height: 12),
                        FarmCard(
                          padding: const EdgeInsets.all(13),
                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.shield_outlined, color: FarmColors.warning),
                              SizedBox(width: 9),
                              Expanded(
                                child: Text(
                                  'Planting safeguard: Meal Pulse is social interest and recent orders are historical. HPJ only treats Harvest Circle reservations and active buyer planning as future demand, and compares them with HPJ-confirmed farmer supply.',
                                  style: TextStyle(
                                    color: FarmColors.mutedText,
                                    fontSize: 9.5,
                                    height: 1.4,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 13),
                        if (data != null && data.parish.isNotEmpty)
                          _HpjP97FarmerParishStrip(
                            profile: widget.profile,
                            rows: data.parish,
                          ),
                        const SizedBox(height: 14),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _chip('gap', 'Verified gaps'),
                              const SizedBox(width: 7),
                              _chip('high', 'High confidence'),
                              const SizedBox(width: 7),
                              _chip('watch', 'Watch only'),
                              const SizedBox(width: 7),
                              _chip('covered', 'Covered'),
                              const SizedBox(width: 7),
                              _chip('all', 'All'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 13),
                        if (snapshot.connectionState == ConnectionState.waiting && data == null)
                          const SizedBox(
                            height: 260,
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (snapshot.hasError)
                          const FarmEmptyState(
                            icon: Icons.insights_outlined,
                            title: 'Grow Intelligence unavailable',
                            message: 'Run the Phase 97 SQL migration, then refresh.',
                          )
                        else if (rows.isEmpty)
                          const FarmEmptyState(
                            icon: Icons.check_circle_outline_rounded,
                            title: 'Nothing in this view',
                            message: 'Try another filter. A quiet screen can be good news — HPJ will not invent a planting signal where committed demand is not present.',
                          )
                        else
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final columns = constraints.maxWidth >= 850 ? 2 : 1;
                              final gap = 11.0;
                              final width = columns == 1
                                  ? constraints.maxWidth
                                  : (constraints.maxWidth - gap) / 2;
                              return Wrap(
                                spacing: gap,
                                runSpacing: gap,
                                children: rows.map((intel) {
                                  final growSignal = data == null
                                      ? null
                                      : _growSignalFor(intel, data.growSignals);
                                  return SizedBox(
                                    width: width,
                                    child: _HpjP97FarmerIntelCard(
                                      signal: intel,
                                      actionLabel: growSignal == null
                                          ? 'Open Market Demand'
                                          : growSignal.hasMyCommitment
                                              ? 'Edit Grow Signal'
                                              : 'I Can Grow This',
                                      onAction: () => _actOn(
                                        intel,
                                        data?.growSignals ?? const <HpjGrowSignal>[],
                                      ),
                                    ),
                                  );
                                }).toList(growable: false),
                              );
                            },
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

  Widget _chip(String value, String label) {
    final selected = _filter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _filter = value),
      selectedColor: FarmColors.green,
      backgroundColor: FarmColors.card,
      side: const BorderSide(color: FarmColors.line),
      labelStyle: TextStyle(
        color: selected ? Colors.white : FarmColors.ink,
        fontSize: 9.5,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

String _hpjP97FarmerQty(double value, String unit) {
  final text = value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);
  final cleanUnit = unit.trim();
  return cleanUnit.isEmpty || cleanUnit == 'unit' ? text : '$text $cleanUnit';
}

class _HpjP97FarmerIntelHero extends StatelessWidget {
  final int verifiedGaps;
  final int highConfidence;
  final int guardCount;

  const _HpjP97FarmerIntelHero({
    required this.verifiedGaps,
    required this.highConfidence,
    required this.guardCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF063D2A), Color(0xFF176044), Color(0xFF4E8157)],
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'GROWTOGETHER INTELLIGENCE',
            style: TextStyle(
              color: Color(0xFFFFD86A),
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
              letterSpacing: .9,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Grow with evidence, not hype.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            '$verifiedGaps verified gap${verifiedGaps == 1 ? '' : 's'} • $highConfidence high-confidence signal${highConfidence == 1 ? '' : 's'} • $guardCount overplant guard${guardCount == 1 ? '' : 's'}',
            style: TextStyle(
              color: Colors.white.withOpacity(.82),
              fontSize: 10.2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HpjP97FarmerIntelCard extends StatelessWidget {
  final HpjGrowIntelligenceSignal signal;
  final String actionLabel;
  final VoidCallback onAction;

  const _HpjP97FarmerIntelCard({
    required this.signal,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = signal.hasVerifiedGap
        ? FarmColors.warning
        : signal.isCovered
            ? FarmColors.success
            : FarmColors.primary;

    return FarmCard(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  signal.cropName,
                  style: const TextStyle(
                    color: FarmColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${signal.opportunityScore}/100',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 8.2,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            signal.confidenceLabel,
            style: TextStyle(
              color: statusColor,
              fontSize: 9.2,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              _metric('Future demand', _hpjP97FarmerQty(signal.futureDemandQuantity, signal.unit)),
              const SizedBox(width: 7),
              _metric('Confirmed supply', _hpjP97FarmerQty(signal.confirmedSupplyQuantity, signal.unit)),
              const SizedBox(width: 7),
              _metric('Gap', _hpjP97FarmerQty(signal.supplyGap, signal.unit)),
            ],
          ),
          const SizedBox(height: 9),
          Text(
            '${signal.reservedHouseholds} reserving household${signal.reservedHouseholds == 1 ? '' : 's'} • ${signal.businessNeedCount} active business need${signal.businessNeedCount == 1 ? '' : 's'} • ${signal.recentOrderCount} recent order${signal.recentOrderCount == 1 ? '' : 's'} • ${signal.socialMentions} Meal Pulse mention${signal.socialMentions == 1 ? '' : 's'}',
            style: const TextStyle(
              color: FarmColors.mutedText,
              fontSize: 8.8,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 9),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: signal.overplantGuard
                  ? FarmColors.warning.withOpacity(.08)
                  : FarmColors.primarySoft,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Text(
              signal.recommendedAction,
              style: TextStyle(
                color: signal.overplantGuard ? FarmColors.warning : FarmColors.deepGreen,
                fontSize: 8.8,
                height: 1.35,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 11),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onAction,
              icon: Icon(signal.hasVerifiedGap ? Icons.spa_outlined : Icons.trending_up_outlined),
              label: Text(actionLabel),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: FarmColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: FarmColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: FarmColors.ink,
                fontSize: 10.2,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: FarmColors.mutedText,
                fontSize: 7.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HpjP97FarmerParishStrip extends StatelessWidget {
  final FarmerProfile profile;
  final List<HpjParishDemandPulse> rows;

  const _HpjP97FarmerParishStrip({required this.profile, required this.rows});

  @override
  Widget build(BuildContext context) {
    final parishName = profile.parish.trim();
    final local = rows.where((e) => e.parish.toLowerCase() == parishName.toLowerCase()).take(4).toList();
    if (local.isEmpty) return const SizedBox.shrink();

    return FarmCard(
      padding: const EdgeInsets.all(13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$parishName pulse',
            style: const TextStyle(
              color: FarmColors.ink,
              fontSize: 13.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'Location-backed business and Meal Pulse signals near your parish. HPJ can still move produce across parishes.',
            style: TextStyle(
              color: FarmColors.mutedText,
              fontSize: 8.8,
              height: 1.3,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: local.map((row) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                decoration: BoxDecoration(
                  color: FarmColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${row.cropName} • ${row.businessNeedCount > 0 ? '${row.businessNeedCount} buyer need${row.businessNeedCount == 1 ? '' : 's'}' : '${row.socialMentions} social'}',
                  style: const TextStyle(
                    color: FarmColors.deepGreen,
                    fontSize: 8.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              );
            }).toList(growable: false),
          ),
        ],
      ),
    );
  }
}


// ============================================================================
// HPJ PHASE 98 — FARMER MATCHED OPPORTUNITIES
// ============================================================================
// Recommendations use only the farmer's own HPJ-confirmed supply.
// Buyer identity is not exposed and a recommendation is not a purchase order.
// ============================================================================

class HpjFarmerSmartProcurementMatch {
  final String demandForecastId;
  final String supplyForecastId;
  final String productName;
  final String unit;
  final DateTime? needByDate;
  final DateTime? expectedHarvestDate;
  final double remainingDemand;
  final double availableSupply;
  final double recommendedQuantity;
  final int matchScore;
  final String matchBand;
  final int? timingDays;
  final bool sameParish;
  final int completedBatches;
  final double acceptedRatio;
  final List<String> reasons;
  final List<String> warnings;

  const HpjFarmerSmartProcurementMatch({
    required this.demandForecastId,
    required this.supplyForecastId,
    required this.productName,
    required this.unit,
    required this.needByDate,
    required this.expectedHarvestDate,
    required this.remainingDemand,
    required this.availableSupply,
    required this.recommendedQuantity,
    required this.matchScore,
    required this.matchBand,
    required this.timingDays,
    required this.sameParish,
    required this.completedBatches,
    required this.acceptedRatio,
    required this.reasons,
    required this.warnings,
  });

  factory HpjFarmerSmartProcurementMatch.fromSupabase(
    Map<String, dynamic> data,
  ) {
    double number(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    int integer(dynamic value) {
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    int? nullableInteger(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString());
    }

    List<String> strings(dynamic value) {
      if (value is! List) return const <String>[];
      return value
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
    }

    DateTime? date(dynamic value) {
      final text = value?.toString().trim() ?? '';
      return text.isEmpty ? null : DateTime.tryParse(text);
    }

    return HpjFarmerSmartProcurementMatch(
      demandForecastId: (data['demand_forecast_id'] ?? '').toString(),
      supplyForecastId: (data['supply_forecast_id'] ?? '').toString(),
      productName: (data['product_name'] ?? 'Produce').toString().trim(),
      unit: (data['unit'] ?? 'unit').toString().trim(),
      needByDate: date(data['need_by_date']),
      expectedHarvestDate: date(data['expected_harvest_date']),
      remainingDemand: number(data['remaining_demand']),
      availableSupply: number(data['available_supply']),
      recommendedQuantity: number(data['recommended_quantity']),
      matchScore: integer(data['match_score']),
      matchBand: (data['match_band'] ?? 'review').toString().trim().toLowerCase(),
      timingDays: nullableInteger(data['timing_days']),
      sameParish: data['same_parish'] == true,
      completedBatches: integer(data['completed_batches']),
      acceptedRatio: number(data['accepted_ratio']),
      reasons: strings(data['reasons']),
      warnings: strings(data['warnings']),
    );
  }

  String get bandLabel {
    switch (matchBand) {
      case 'excellent':
        return 'Excellent';
      case 'strong':
        return 'Strong';
      case 'possible':
        return 'Possible';
      default:
        return 'Review';
    }
  }
}

Future<List<HpjFarmerSmartProcurementMatch>> fetchHpjFarmerSmartMatches(
  String farmerProfileId,
) async {
  final clean = farmerProfileId.trim();
  if (clean.isEmpty || supabase.auth.currentUser == null) {
    return const <HpjFarmerSmartProcurementMatch>[];
  }

  try {
    final response = await supabase.rpc(
      'hpj_get_farmer_smart_matches',
      params: <String, dynamic>{
        'p_farmer_profile_id': clean,
        'p_limit': 30,
      },
    );

    if (response is! List) {
      return const <HpjFarmerSmartProcurementMatch>[];
    }

    return response
        .whereType<Map>()
        .map(
          (item) => HpjFarmerSmartProcurementMatch.fromSupabase(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList(growable: false);
  } catch (error) {
    farmDebugLog('Farmer smart matches unavailable: $error');
    return const <HpjFarmerSmartProcurementMatch>[];
  }
}

class HpjFarmerMatchedOpportunitiesScreen extends StatefulWidget {
  final FarmerProfile profile;

  const HpjFarmerMatchedOpportunitiesScreen({
    super.key,
    required this.profile,
  });

  @override
  State<HpjFarmerMatchedOpportunitiesScreen> createState() =>
      _HpjFarmerMatchedOpportunitiesScreenState();
}

class _HpjFarmerMatchedOpportunitiesScreenState
    extends State<HpjFarmerMatchedOpportunitiesScreen> {
  late Future<List<HpjFarmerSmartProcurementMatch>> future;

  @override
  void initState() {
    super.initState();
    future = fetchHpjFarmerSmartMatches(widget.profile.id);
  }

  Future<void> _refresh() async {
    final next = fetchHpjFarmerSmartMatches(widget.profile.id);
    if (mounted) setState(() => future = next);
    await next;
  }

  String _number(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
  }

  String _date(DateTime? value) {
    if (value == null) return 'Date not set';
    final local = value.toLocal();
    const months = <String>[
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${local.day} ${months[local.month - 1]} ${local.year}';
  }

  Color _scoreColor(int score) {
    if (score >= 90) return FarmColors.success;
    if (score >= 78) return FarmColors.green;
    if (score >= 65) return FarmColors.primary;
    return FarmColors.warning;
  }

  Widget _matchCard(HpjFarmerSmartProcurementMatch row) {
    final color = _scoreColor(row.matchScore);

    return FarmCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  row.productName,
                  style: const TextStyle(
                    color: FarmColors.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${row.matchScore}% ${row.bandLabel}',
                  style: TextStyle(
                    color: color,
                    fontSize: 8.8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _HpjFarmerSmartMatchMetric(
                  label: 'Recommended',
                  value: '${_number(row.recommendedQuantity)} ${row.unit}',
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _HpjFarmerSmartMatchMetric(
                  label: 'Your confirmed supply',
                  value: '${_number(row.availableSupply)} ${row.unit}',
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _HpjFarmerSmartMatchMetric(
                  label: 'Buyer need date',
                  value: _date(row.needByDate),
                ),
              ),
            ],
          ),
          if (row.reasons.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...row.reasons.take(3).map(
              (reason) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle_outline_rounded,
                      size: 15,
                      color: FarmColors.success,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        reason,
                        style: const TextStyle(
                          color: FarmColors.mutedText,
                          fontSize: 9.4,
                          height: 1.3,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (row.warnings.isNotEmpty) ...[
            const SizedBox(height: 5),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: FarmColors.warning.withOpacity(.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                row.warnings.join(' • '),
                style: const TextStyle(
                  color: FarmColors.warning,
                  fontSize: 8.9,
                  height: 1.3,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          const Text(
            'HPJ must still review and reserve this supply. This recommendation is not a purchase order or guaranteed sale.',
            style: TextStyle(
              color: FarmColors.mutedText,
              fontSize: 8.5,
              height: 1.3,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final desktop = kIsWeb && MediaQuery.sizeOf(context).width >= 980;

    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: AppBar(
        title: const Text(
          'Matched Opportunities',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<HpjFarmerSmartProcurementMatch>>(
          future: future,
          builder: (context, snapshot) {
            final rows =
                snapshot.data ?? const <HpjFarmerSmartProcurementMatch>[];

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                desktop ? 28 : 14,
                desktop ? 24 : 14,
                desktop ? 28 : 14,
                42,
              ),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(26),
                            gradient: const LinearGradient(
                              colors: [
                                FarmColors.deepGreen,
                                FarmColors.green,
                                Color(0xFF4E8157),
                              ],
                            ),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SMART PROCUREMENT MATCHES',
                                style: TextStyle(
                                  color: Color(0xFFE8C768),
                                  fontSize: 9.5,
                                  letterSpacing: .8,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(height: 7),
                              Text(
                                'Where your confirmed supply fits real buyer demand',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  height: 1.1,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(height: 7),
                              Text(
                                'HPJ compares crop, unit, quantity, harvest timing, parish and receiving history. Buyer identity stays private.',
                                style: TextStyle(
                                  color: Color(0xFFD7E6DB),
                                  fontSize: 10,
                                  height: 1.4,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (snapshot.connectionState ==
                                ConnectionState.waiting &&
                            rows.isEmpty)
                          const SizedBox(
                            height: 220,
                            child:
                                Center(child: CircularProgressIndicator()),
                          )
                        else if (rows.isEmpty)
                          const FarmEmptyState(
                            icon: Icons.route_outlined,
                            title: 'No confirmed match yet',
                            message:
                                'Matched Opportunities appear when your HPJ-confirmed supply fits an active procurement requirement.',
                          )
                        else
                          ...rows.map(
                            (row) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _matchCard(row),
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

class _HpjFarmerSmartMatchMetric extends StatelessWidget {
  final String label;
  final String value;

  const _HpjFarmerSmartMatchMetric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9F4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FarmColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: FarmColors.mutedText,
              fontSize: 7.8,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: FarmColors.ink,
              fontSize: 9.7,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}


// ============================================================================
// HPJ PHASE 107 — SMART FARMER MATCHING / DEMAND RADAR
// ============================================================================

class HpjFarmerDemandRadarScreen extends StatefulWidget {
  final FarmerProfile profile;

  const HpjFarmerDemandRadarScreen({
    super.key,
    required this.profile,
  });

  @override
  State<HpjFarmerDemandRadarScreen> createState() =>
      _HpjFarmerDemandRadarScreenState();
}

class _HpjFarmerDemandRadarScreenState
    extends State<HpjFarmerDemandRadarScreen> {
  late Future<List<HpjDemandRadarSignal>> _radarFuture;
  late Future<List<FarmerSupplyForecast>> _supplyFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _radarFuture = fetchHpjDemandRadar();
    _supplyFuture = fetchFarmerSupplyForecasts(widget.profile.id);
  }

  Future<void> _refresh() async {
    setState(_reload);
    await Future.wait<dynamic>([_radarFuture, _supplyFuture]);
  }

  String _key(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), ' ');

  bool _matchesMySupply(
    HpjDemandRadarSignal signal,
    List<FarmerSupplyForecast> supply,
  ) {
    final crop = _key(signal.cropName);
    final unit = _key(signal.unit);

    return supply.any((row) {
      final status = row.status.trim().toLowerCase();
      final active = status != 'cancelled' && status != 'completed';
      return active &&
          _key(row.cropName) == crop &&
          _key(row.unit) == unit;
    });
  }

  Future<void> _offer(HpjDemandRadarSignal signal) async {
    final submitted = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _HpjFarmerDemandOfferSheet(
        profile: widget.profile,
        signal: signal,
      ),
    );

    if (submitted == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Supply response sent to HPJ. Your reported supply was also updated for matching.',
          ),
        ),
      );
      await _refresh();
    }
  }

  String _number(double value) {
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
  }

  Widget _signalCard(
    HpjDemandRadarSignal signal, {
    required bool matchesMySupply,
  }) {
    final covered = signal.gapQuantity <= 0.0001;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: matchesMySupply
            ? const Color(0xFFF0F7ED)
            : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: matchesMySupply
              ? FarmColors.primary.withOpacity(.32)
              : FarmColors.line,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: matchesMySupply
                      ? FarmColors.primarySoft
                      : FarmColors.cardSoft,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  matchesMySupply
                      ? Icons.auto_awesome_rounded
                      : Icons.radar_rounded,
                  color: FarmColors.primary,
                  size: 20,
                ),
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
                            signal.cropName,
                            style: const TextStyle(
                              color: FarmColors.ink,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (matchesMySupply)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: FarmColors.primary,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'MATCHES YOUR SUPPLY',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 7.0,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${_number(signal.totalDemand)} ${signal.unit} demand • '
                      '${_number(signal.reportedSupply)} ${signal.unit} reported',
                      style: const TextStyle(
                        color: FarmColors.mutedText,
                        fontSize: 9.1,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: _HpjFarmerRadarMetric(
                  label: 'Still needed',
                  value: '${_number(signal.gapQuantity)} ${signal.unit}',
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _HpjFarmerRadarMetric(
                  label: 'Coverage',
                  value: '${signal.coveragePercent.toStringAsFixed(0)}%',
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _HpjFarmerRadarMetric(
                  label: 'Buyer needs',
                  value: '${signal.businessCount}',
                ),
              ),
            ],
          ),
          if (signal.earliestNeedBy != null) ...[
            const SizedBox(height: 7),
            Text(
              'Earliest need: ${_farmerPartnerDate(signal.earliestNeedBy!)}',
              style: const TextStyle(
                color: FarmColors.deepGreen,
                fontSize: 8.6,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: FilledButton.icon(
              onPressed: covered ? null : () => _offer(signal),
              icon: Icon(
                covered
                    ? Icons.check_rounded
                    : Icons.agriculture_outlined,
                size: 16,
              ),
              label: Text(
                covered ? 'Supply currently covered' : 'I Can Supply This',
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: AppBar(
        title: const Text('Demand Radar'),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<dynamic>>(
          future: Future.wait<dynamic>([
            _radarFuture,
            _supplyFuture,
          ]),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                snapshot.data == null) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  SkeletonList(count: 4),
                ],
              );
            }

            final values = snapshot.data ?? const <dynamic>[];
            final radar = values.isNotEmpty
                ? List<HpjDemandRadarSignal>.from(
                    values[0] as List<HpjDemandRadarSignal>,
                  )
                : <HpjDemandRadarSignal>[];
            final supply = values.length > 1
                ? List<FarmerSupplyForecast>.from(
                    values[1] as List<FarmerSupplyForecast>,
                  )
                : <FarmerSupplyForecast>[];

            radar.sort((a, b) {
              final aMatch = _matchesMySupply(a, supply);
              final bMatch = _matchesMySupply(b, supply);
              if (aMatch != bMatch) return aMatch ? -1 : 1;

              final gapCompare =
                  b.gapQuantity.compareTo(a.gapQuantity);
              if (gapCompare != 0) return gapCompare;

              return a.cropName.toLowerCase().compareTo(
                    b.cropName.toLowerCase(),
                  );
            });

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
              children: [
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: const Color(0xFF073F2C),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.radar_rounded,
                        color: Color(0xFFFFD15A),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'HPJ combines open business demand with farmer-reported supply. Buyer identities stay private; crops matching your own supply are ranked first.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.1,
                            height: 1.35,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                if (radar.isEmpty)
                  const FarmEmptyState(
                    icon: Icons.radar_rounded,
                    title: 'No open demand signals',
                    message:
                        'New national demand opportunities will appear here as businesses post needs.',
                  )
                else
                  for (var i = 0; i < radar.length; i++) ...[
                    _signalCard(
                      radar[i],
                      matchesMySupply:
                          _matchesMySupply(radar[i], supply),
                    ),
                    if (i != radar.length - 1)
                      const SizedBox(height: 9),
                  ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HpjFarmerRadarMetric extends StatelessWidget {
  final String label;
  final String value;

  const _HpjFarmerRadarMetric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: FarmColors.cardSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: FarmColors.deepGreen,
              fontSize: 10.3,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: FarmColors.mutedText,
              fontSize: 7.7,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HpjFarmerDemandOfferSheet extends StatefulWidget {
  final FarmerProfile profile;
  final HpjDemandRadarSignal signal;

  const _HpjFarmerDemandOfferSheet({
    required this.profile,
    required this.signal,
  });

  @override
  State<_HpjFarmerDemandOfferSheet> createState() =>
      _HpjFarmerDemandOfferSheetState();
}

class _HpjFarmerDemandOfferSheetState
    extends State<_HpjFarmerDemandOfferSheet> {
  final quantityController = TextEditingController();
  final noteController = TextEditingController();
  late DateTime availableDate;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    availableDate = widget.signal.earliestNeedBy ??
        DateTime.now().add(const Duration(days: 7));
  }

  @override
  void dispose() {
    quantityController.dispose();
    noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final chosen = await showDatePicker(
      context: context,
      initialDate: availableDate.isBefore(today) ? today : availableDate,
      firstDate: DateTime(today.year, today.month, today.day),
      lastDate: today.add(const Duration(days: 365)),
    );
    if (chosen == null || !mounted) return;
    setState(() => availableDate = chosen);
  }

  Future<void> _submit() async {
    final quantity = double.tryParse(
      quantityController.text.trim().replaceAll(',', ''),
    );

    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid supply quantity.')),
      );
      return;
    }

    setState(() => saving = true);

    try {
      await supabase.rpc(
        'hpj_submit_farmer_demand_offer',
        params: <String, dynamic>{
          'p_crop_name': widget.signal.cropName,
          'p_unit': widget.signal.unit,
          'p_quantity': quantity,
          'p_available_date':
              availableDate.toIso8601String().split('T').first,
          'p_note': noteController.text.trim(),
        },
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyAppError(error))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: FarmColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          18,
          18,
          18,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Supply ${widget.signal.cropName}',
              style: const TextStyle(
                color: FarmColors.ink,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'HPJ currently shows ${widget.signal.gapQuantity.toStringAsFixed(widget.signal.gapQuantity == widget.signal.gapQuantity.roundToDouble() ? 0 : 1)} ${widget.signal.unit} still needed across the network.',
              style: const TextStyle(
                color: FarmColors.mutedText,
                fontSize: 10.2,
                height: 1.3,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: quantityController,
              enabled: !saving,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'I can supply (${widget.signal.unit})',
                prefixIcon: const Icon(Icons.scale_outlined),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.calendar_month_outlined,
                color: FarmColors.primary,
              ),
              title: const Text(
                'Available date',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(_farmerPartnerDate(availableDate)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: saving ? null : _pickDate,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: noteController,
              enabled: !saving,
              maxLength: 240,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Note to HPJ (optional)',
                hintText:
                    'Example: first 100 lb ready Monday, remaining quantity later in week.',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: FarmColors.primarySoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Submitting creates or updates a matching Farmer Supply signal for HPJ. The business does not receive your private phone, email or exact farm location.',
                style: TextStyle(
                  color: FarmColors.deepGreen,
                  fontSize: 9.0,
                  height: 1.35,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: FilledButton.icon(
                onPressed: saving ? null : _submit,
                icon: saving
                    ? const SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.agriculture_outlined),
                label: Text(
                  saving ? 'Sending…' : 'Send Supply Response',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ============================================================================
// HPJ PHASES 108–110 — TRUST & CONNECTION NETWORK
// 108 Ask the Farmer Inbox
// 109 Farmer Trust & Reputation
// 110 Story → Sale Intelligence
// ============================================================================

class HpjFarmerQuestionRecord {
  final String id;
  final String question;
  final String answer;
  final String status;
  final String sourceWorkspace;
  final bool isPublic;
  final DateTime? createdAt;
  final DateTime? answeredAt;

  const HpjFarmerQuestionRecord({
    required this.id,
    required this.question,
    required this.answer,
    required this.status,
    required this.sourceWorkspace,
    required this.isPublic,
    this.createdAt,
    this.answeredAt,
  });

  factory HpjFarmerQuestionRecord.fromSupabase(Map<String, dynamic> row) {
    return HpjFarmerQuestionRecord(
      id: (row['id'] ?? '').toString().trim(),
      question: (row['question'] ?? '').toString().trim(),
      answer: (row['answer'] ?? '').toString().trim(),
      status: (row['status'] ?? 'pending').toString().trim().toLowerCase(),
      sourceWorkspace:
          (row['source_workspace'] ?? 'customer').toString().trim(),
      isPublic: row['is_public'] != false,
      createdAt: parseProductDate(row['created_at']),
      answeredAt: parseProductDate(row['answered_at']),
    );
  }

  bool get isPending => status == 'pending';

  String get sourceLabel =>
      sourceWorkspace.trim().toLowerCase() == 'wholesale' ||
              sourceWorkspace.trim().toLowerCase() == 'business'
          ? 'Business question'
          : 'Customer question';
}

Future<List<HpjFarmerQuestionRecord>> fetchHpjFarmerQuestions(
  String farmerProfileId,
) async {
  final clean = farmerProfileId.trim();
  if (clean.isEmpty || supabase.auth.currentUser == null) {
    return const <HpjFarmerQuestionRecord>[];
  }

  final response = await supabase.rpc(
    'hpj_my_farmer_questions',
    params: <String, dynamic>{
      'p_farmer_profile_id': clean,
    },
  );

  return (response as List)
      .map(
        (row) => HpjFarmerQuestionRecord.fromSupabase(
          Map<String, dynamic>.from(row as Map),
        ),
      )
      .toList(growable: false);
}

Future<void> answerHpjFarmerQuestion({
  required String questionId,
  required String answer,
  required bool publishPublicly,
}) async {
  final clean = answer.trim();
  if (clean.length < 4) {
    throw Exception('Add a useful answer before sending.');
  }

  await supabase.rpc(
    'hpj_answer_farm_question',
    params: <String, dynamic>{
      'p_question_id': questionId.trim(),
      'p_answer': clean,
      'p_publish_public': publishPublicly,
    },
  );
}

class HpjFarmerQuestionsScreen extends StatefulWidget {
  final FarmerProfile profile;

  const HpjFarmerQuestionsScreen({
    super.key,
    required this.profile,
  });

  @override
  State<HpjFarmerQuestionsScreen> createState() =>
      _HpjFarmerQuestionsScreenState();
}

class _HpjFarmerQuestionsScreenState extends State<HpjFarmerQuestionsScreen> {
  late Future<List<HpjFarmerQuestionRecord>> _future;
  bool showAnswered = false;

  @override
  void initState() {
    super.initState();
    _future = fetchHpjFarmerQuestions(widget.profile.id);
  }

  Future<void> _refresh() async {
    final next = fetchHpjFarmerQuestions(widget.profile.id);
    if (mounted) setState(() => _future = next);
    await next;
  }

  Future<void> _answer(HpjFarmerQuestionRecord question) async {
    final controller = TextEditingController(text: question.answer);
    var publishPublicly = question.isPublic;
    var saving = false;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                18,
                18,
                18,
                MediaQuery.viewInsetsOf(context).bottom + 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Answer Question',
                    style: TextStyle(
                      color: FarmColors.deepGreen,
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: FarmColors.cardSoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      question.question,
                      style: const TextStyle(
                        color: FarmColors.ink,
                        fontSize: 10.5,
                        height: 1.35,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    enabled: !saving,
                    maxLength: 600,
                    minLines: 4,
                    maxLines: 8,
                    decoration: const InputDecoration(
                      labelText: 'Your answer',
                      hintText:
                          'Give a useful answer about the crop, timing or farming practice.',
                      alignLabelWithHint: true,
                    ),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: publishPublicly,
                    onChanged: saving
                        ? null
                        : (value) => setSheetState(
                              () => publishPublicly = value,
                            ),
                    title: const Text(
                      'Show this answer on my public Farm Profile',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    subtitle: const Text(
                      'The person who asked is never identified publicly.',
                      style: TextStyle(fontSize: 8.5),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: FilledButton.icon(
                      onPressed: saving
                          ? null
                          : () async {
                              setSheetState(() => saving = true);
                              try {
                                await answerHpjFarmerQuestion(
                                  questionId: question.id,
                                  answer: controller.text,
                                  publishPublicly: publishPublicly,
                                );
                                if (!sheetContext.mounted) return;
                                Navigator.of(sheetContext).pop(true);
                              } catch (error) {
                                if (!sheetContext.mounted) return;
                                setSheetState(() => saving = false);
                                ScaffoldMessenger.of(sheetContext).showSnackBar(
                                  SnackBar(
                                    content: Text(friendlyAppError(error)),
                                  ),
                                );
                              }
                            },
                      icon: saving
                          ? const SizedBox(
                              width: 17,
                              height: 17,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded),
                      label: Text(saving ? 'Sending…' : 'Send Answer'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    controller.dispose();

    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Answer sent.')),
      );
      await _refresh();
    }
  }

  String _date(DateTime? value) {
    if (value == null) return '';
    return _farmerPartnerDate(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: AppBar(title: const Text('Ask the Farmer Inbox')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<HpjFarmerQuestionRecord>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                snapshot.data == null) {
              return const Center(child: CircularProgressIndicator());
            }

            final all = snapshot.data ?? const <HpjFarmerQuestionRecord>[];
            final pending = all.where((q) => q.isPending).toList();
            final answered = all.where((q) => !q.isPending).toList();
            final visible = showAnswered ? answered : pending;

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
              children: [
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: const Color(0xFF073F2C),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.forum_outlined,
                        color: Color(0xFFFFD15A),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${pending.length} awaiting answer • ${answered.length} answered. Customer and business contact details stay private.',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            height: 1.35,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SegmentedButton<bool>(
                  segments: [
                    ButtonSegment<bool>(
                      value: false,
                      label: Text('Pending (${pending.length})'),
                      icon: const Icon(Icons.schedule_rounded),
                    ),
                    ButtonSegment<bool>(
                      value: true,
                      label: Text('Answered (${answered.length})'),
                      icon: const Icon(Icons.check_circle_outline_rounded),
                    ),
                  ],
                  selected: <bool>{showAnswered},
                  onSelectionChanged: (values) => setState(
                    () => showAnswered = values.first,
                  ),
                ),
                const SizedBox(height: 12),
                if (visible.isEmpty)
                  FarmEmptyState(
                    icon: showAnswered
                        ? Icons.forum_outlined
                        : Icons.mark_chat_read_outlined,
                    title: showAnswered
                        ? 'No answered questions yet'
                        : 'You are all caught up',
                    message: showAnswered
                        ? 'Questions you answer will appear here.'
                        : 'New customer or business questions will appear here.',
                  )
                else
                  for (var i = 0; i < visible.length; i++) ...[
                    FarmCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: visible[i].isPending
                                      ? const Color(0xFFFFF4D6)
                                      : FarmColors.primarySoft,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  visible[i].sourceLabel,
                                  style: const TextStyle(
                                    color: FarmColors.deepGreen,
                                    fontSize: 7.6,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                _date(visible[i].createdAt),
                                style: const TextStyle(
                                  color: FarmColors.mutedText,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            visible[i].question,
                            style: const TextStyle(
                              color: FarmColors.ink,
                              fontSize: 11,
                              height: 1.35,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (visible[i].answer.isNotEmpty) ...[
                            const SizedBox(height: 9),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: FarmColors.primarySoft,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                visible[i].answer,
                                style: const TextStyle(
                                  color: FarmColors.deepGreen,
                                  fontSize: 9.5,
                                  height: 1.35,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () => _answer(visible[i]),
                              icon: Icon(
                                visible[i].isPending
                                    ? Icons.reply_rounded
                                    : Icons.edit_outlined,
                                size: 16,
                              ),
                              label: Text(
                                visible[i].isPending
                                    ? 'Answer'
                                    : 'Update answer',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (i != visible.length - 1)
                      const SizedBox(height: 8),
                  ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class HpjFarmerTrustScreen extends StatefulWidget {
  final FarmerProfile profile;

  const HpjFarmerTrustScreen({
    super.key,
    required this.profile,
  });

  @override
  State<HpjFarmerTrustScreen> createState() => _HpjFarmerTrustScreenState();
}

class _HpjFarmerTrustScreenState extends State<HpjFarmerTrustScreen> {
  late Future<HpjFarmTrustSnapshot> _future;

  @override
  void initState() {
    super.initState();
    _future = fetchHpjPublicFarmTrust(widget.profile.id);
  }

  Future<void> _refresh() async {
    final next = fetchHpjPublicFarmTrust(widget.profile.id);
    if (mounted) setState(() => _future = next);
    await next;
  }

  Widget _metric(IconData icon, String value, String label, String note) {
    return FarmCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: FarmColors.primary, size: 20),
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
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            note,
            style: const TextStyle(
              color: FarmColors.mutedText,
              fontSize: 8.2,
              height: 1.3,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: AppBar(title: const Text('Trust & Reputation')),
      body: FutureBuilder<HpjFarmTrustSnapshot>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final trust = snapshot.data ?? HpjFarmTrustSnapshot.empty;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF073F2C),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'YOUR PUBLIC HPJ TRUST PROFILE',
                        style: TextStyle(
                          color: Color(0xFFFFD15A),
                          fontSize: 9,
                          letterSpacing: .8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        trust.trustLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'HPJ uses verified marketplace activity — not paid badges or follower popularity — to build customer trust.',
                        style: TextStyle(
                          color: Color(0xFFD1E2D8),
                          fontSize: 9.5,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 760 ? 4 : 2;
                    const gap = 9.0;
                    final width =
                        (constraints.maxWidth - gap * (columns - 1)) / columns;
                    final cards = <Widget>[
                      _metric(
                        Icons.verified_rounded,
                        trust.verified ? 'Verified' : 'Building',
                        'HPJ verification',
                        'Approval status from HPJ Farmer onboarding.',
                      ),
                      _metric(
                        Icons.local_shipping_outlined,
                        '${trust.fulfilledOrders}',
                        'Fulfilled orders',
                        'Delivered HPJ orders containing your products.',
                      ),
                      _metric(
                        Icons.star_rounded,
                        trust.ratingCount <= 0
                            ? 'New'
                            : trust.averageRating.toStringAsFixed(1),
                        'Customer rating',
                        trust.ratingCount <= 0
                            ? 'No completed-order rating history yet.'
                            : '${trust.ratingCount} transaction-linked ratings.',
                      ),
                      _metric(
                        Icons.forum_outlined,
                        trust.questionCount <= 0
                            ? 'New'
                            : '${trust.questionResponseRate.toStringAsFixed(0)}%',
                        'Question response',
                        '${trust.answeredQuestions} of ${trust.questionCount} questions answered.',
                      ),
                    ];

                    return Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: cards
                          .map((card) => SizedBox(width: width, child: card))
                          .toList(growable: false),
                    );
                  },
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF1DFAD)),
                  ),
                  child: const Text(
                    'The public Farm Profile shows these aggregate trust signals only. Customer names, order details, addresses and private messages are never exposed.',
                    style: TextStyle(
                      color: Color(0xFF755A1A),
                      fontSize: 9.2,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class HpjStorySalesInsights {
  final int storyViews30d;
  final int farmViews30d;
  final int productViews30d;
  final int addToBox30d;
  final int attributedOrders30d;
  final double attributedUnits30d;
  final double attributedRevenue30d;
  final double viewToOrderPercent;
  final String topStoryProduct;
  final String topStoryCaption;
  final int topStoryOrders;

  const HpjStorySalesInsights({
    required this.storyViews30d,
    required this.farmViews30d,
    required this.productViews30d,
    required this.addToBox30d,
    required this.attributedOrders30d,
    required this.attributedUnits30d,
    required this.attributedRevenue30d,
    required this.viewToOrderPercent,
    required this.topStoryProduct,
    required this.topStoryCaption,
    required this.topStoryOrders,
  });

  static const empty = HpjStorySalesInsights(
    storyViews30d: 0,
    farmViews30d: 0,
    productViews30d: 0,
    addToBox30d: 0,
    attributedOrders30d: 0,
    attributedUnits30d: 0,
    attributedRevenue30d: 0,
    viewToOrderPercent: 0,
    topStoryProduct: '',
    topStoryCaption: '',
    topStoryOrders: 0,
  );

  factory HpjStorySalesInsights.fromSupabase(Map<String, dynamic> row) {
    int whole(dynamic value) {
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    double number(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    return HpjStorySalesInsights(
      storyViews30d: whole(row['story_views_30d']),
      farmViews30d: whole(row['farm_views_30d']),
      productViews30d: whole(row['product_views_30d']),
      addToBox30d: whole(row['add_to_box_30d']),
      attributedOrders30d: whole(row['attributed_orders_30d']),
      attributedUnits30d: number(row['attributed_units_30d']),
      attributedRevenue30d: number(row['attributed_revenue_30d']),
      viewToOrderPercent: number(row['view_to_order_percent']),
      topStoryProduct: (row['top_story_product'] ?? '').toString().trim(),
      topStoryCaption: (row['top_story_caption'] ?? '').toString().trim(),
      topStoryOrders: whole(row['top_story_orders']),
    );
  }
}

Future<HpjStorySalesInsights> fetchHpjStorySalesInsights(
  String farmerProfileId,
) async {
  final clean = farmerProfileId.trim();
  if (clean.isEmpty || supabase.auth.currentUser == null) {
    return HpjStorySalesInsights.empty;
  }

  final response = await supabase.rpc(
    'hpj_get_farmer_story_sales_insights',
    params: <String, dynamic>{
      'p_farmer_profile_id': clean,
    },
  );

  if (response is List && response.isNotEmpty) {
    return HpjStorySalesInsights.fromSupabase(
      Map<String, dynamic>.from(response.first as Map),
    );
  }
  if (response is Map) {
    return HpjStorySalesInsights.fromSupabase(
      Map<String, dynamic>.from(response),
    );
  }
  return HpjStorySalesInsights.empty;
}

class HpjFarmerStorySalesInsightsScreen extends StatefulWidget {
  final FarmerProfile profile;

  const HpjFarmerStorySalesInsightsScreen({
    super.key,
    required this.profile,
  });

  @override
  State<HpjFarmerStorySalesInsightsScreen> createState() =>
      _HpjFarmerStorySalesInsightsScreenState();
}

class _HpjFarmerStorySalesInsightsScreenState
    extends State<HpjFarmerStorySalesInsightsScreen> {
  late Future<HpjStorySalesInsights> _future;

  @override
  void initState() {
    super.initState();
    _future = fetchHpjStorySalesInsights(widget.profile.id);
  }

  Future<void> _refresh() async {
    final next = fetchHpjStorySalesInsights(widget.profile.id);
    if (mounted) setState(() => _future = next);
    await next;
  }

  Widget _metric({
    required IconData icon,
    required String value,
    required String label,
    required String note,
  }) {
    return FarmCard(
      padding: const EdgeInsets.all(13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: FarmColors.primary, size: 20),
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
              fontSize: 9.8,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            note,
            style: const TextStyle(
              color: FarmColors.mutedText,
              fontSize: 8.2,
              height: 1.25,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _units(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: AppBar(title: const Text('Story → Sales')),
      body: FutureBuilder<HpjStorySalesInsights>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(18),
                children: [
                  FarmEmptyState(
                    icon: Icons.moving_rounded,
                    title: 'Story-to-Sale insights unavailable',
                    message: friendlyAppError(snapshot.error!),
                  ),
                ],
              ),
            );
          }

          final insight = snapshot.data ?? HpjStorySalesInsights.empty;

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF063D2A), Color(0xFF126445)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'STORY → SHOP → SALE',
                        style: TextStyle(
                          color: Color(0xFFFFD15A),
                          fontSize: 9,
                          letterSpacing: .9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 7),
                      const Text(
                        'See which Farm Stories move customers toward a real HPJ order.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          height: 1.08,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        '${widget.profile.farmName} • rolling 30-day funnel',
                        style: TextStyle(
                          color: Colors.white.withOpacity(.75),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 850 ? 4 : 2;
                    const gap = 9.0;
                    final width =
                        (constraints.maxWidth - gap * (columns - 1)) / columns;
                    final cards = <Widget>[
                      _metric(
                        icon: Icons.visibility_outlined,
                        value: '${insight.storyViews30d}',
                        label: 'Story views',
                        note: 'Unique Story sessions',
                      ),
                      _metric(
                        icon: Icons.shopping_bag_outlined,
                        value: '${insight.productViews30d}',
                        label: 'Product views',
                        note: 'Opened from a Story',
                      ),
                      _metric(
                        icon: Icons.add_shopping_cart_rounded,
                        value: '${insight.addToBox30d}',
                        label: 'Add to Box',
                        note: 'Story-linked product actions',
                      ),
                      _metric(
                        icon: Icons.receipt_long_outlined,
                        value: '${insight.attributedOrders30d}',
                        label: 'Attributed orders',
                        note: '${insight.viewToOrderPercent.toStringAsFixed(1)}% view → order',
                      ),
                    ];

                    return Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: cards
                          .map((card) => SizedBox(width: width, child: card))
                          .toList(growable: false),
                    );
                  },
                ),
                const SizedBox(height: 12),
                FarmCard(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Attributed commerce',
                        style: TextStyle(
                          color: FarmColors.ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _HpjStoryImpactRow(
                        icon: Icons.inventory_2_outlined,
                        label: 'Units in attributed orders',
                        value: _units(insight.attributedUnits30d),
                      ),
                      _HpjStoryImpactRow(
                        icon: Icons.payments_outlined,
                        label: 'Attributed order value',
                        value: formatJmd(insight.attributedRevenue30d),
                      ),
                      _HpjStoryImpactRow(
                        icon: Icons.storefront_outlined,
                        label: 'Farm views from Stories',
                        value: '${insight.farmViews30d}',
                        isLast: true,
                      ),
                    ],
                  ),
                ),
                if (insight.topStoryProduct.isNotEmpty ||
                    insight.topStoryCaption.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  FarmCard(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Top converting Story',
                          style: TextStyle(
                            color: FarmColors.ink,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 7),
                        if (insight.topStoryProduct.isNotEmpty)
                          Text(
                            insight.topStoryProduct,
                            style: const TextStyle(
                              color: FarmColors.deepGreen,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        if (insight.topStoryCaption.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            insight.topStoryCaption,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: FarmColors.mutedText,
                              fontSize: 9.2,
                              height: 1.35,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const SizedBox(height: 7),
                        Text(
                          '${insight.topStoryOrders} attributed order${insight.topStoryOrders == 1 ? '' : 's'}',
                          style: const TextStyle(
                            color: FarmColors.primary,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF1DFAD)),
                  ),
                  child: const Text(
                    'HPJ attributes a sale only when a signed-in customer engages with a product linked to your Farm Story and buys that same product within 7 days. Customer identity is never shown here.',
                    style: TextStyle(
                      color: Color(0xFF755A1A),
                      fontSize: 9.2,
                      height: 1.4,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}


// ============================================================================
// HPJ PHASE 115 — FARMER MEAL INTELLIGENCE
// Social meal activity is an early signal, not confirmed purchase demand.
// ============================================================================

class HpjMealIntelligenceSignal {
  final String ingredient;
  final int mentions;
  final int uniqueCreators;
  final int engagement;
  final double growthPercent;

  const HpjMealIntelligenceSignal({
    required this.ingredient,
    required this.mentions,
    required this.uniqueCreators,
    required this.engagement,
    required this.growthPercent,
  });

  factory HpjMealIntelligenceSignal.fromSupabase(Map<String, dynamic> row) {
    int whole(dynamic value) {
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    double number(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    return HpjMealIntelligenceSignal(
      ingredient: (row['ingredient'] ?? '').toString().trim(),
      mentions: whole(row['mentions']),
      uniqueCreators: whole(row['unique_creators']),
      engagement: whole(row['engagement']),
      growthPercent: number(row['growth_percent']),
    );
  }
}

Future<List<HpjMealIntelligenceSignal>> fetchHpjMealIntelligence({
  int days = 7,
  int limit = 12,
}) async {
  try {
    final response = await supabase.rpc(
      'hpj_get_meal_intelligence',
      params: <String, dynamic>{
        'p_days': days.clamp(1, 30),
        'p_limit': limit.clamp(1, 30),
      },
    );

    return (response as List)
        .map(
          (item) => HpjMealIntelligenceSignal.fromSupabase(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .where((item) => item.ingredient.isNotEmpty)
        .toList(growable: false);
  } catch (error) {
    farmDebugLog('Meal Intelligence unavailable: $error');
    return const <HpjMealIntelligenceSignal>[];
  }
}


class _HpjFarmerMobileInsightIntro extends StatelessWidget {
  final IconData icon;
  final String eyebrow;
  final String title;
  final String message;

  const _HpjFarmerMobileInsightIntro({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFEFB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0E6DE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF3E7),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: FarmColors.green,
              size: 20,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow,
                  style: const TextStyle(
                    color: FarmColors.green,
                    fontSize: 8.2,
                    letterSpacing: .75,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  title,
                  style: const TextStyle(
                    color: FarmColors.ink,
                    fontSize: 14.5,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -.2,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  message,
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
        ],
      ),
    );
  }
}

class HpjFarmerMealIntelligenceScreen extends StatefulWidget {
  const HpjFarmerMealIntelligenceScreen({super.key});

  @override
  State<HpjFarmerMealIntelligenceScreen> createState() =>
      _HpjFarmerMealIntelligenceScreenState();
}

class _HpjFarmerMealIntelligenceScreenState
    extends State<HpjFarmerMealIntelligenceScreen> {
  int days = 7;
  late Future<List<HpjMealIntelligenceSignal>> _future;

  @override
  void initState() {
    super.initState();
    _future = fetchHpjMealIntelligence(days: days);
  }

  void _setDays(int value) {
    if (days == value) return;
    setState(() {
      days = value;
      _future = fetchHpjMealIntelligence(days: days);
    });
  }

  String _growth(double value) {
    if (value >= 1) return '+${value.toStringAsFixed(0)}%';
    if (value <= -1) return '${value.toStringAsFixed(0)}%';
    return 'Steady';
  }

  @override
  Widget build(BuildContext context) {
    final nativeMobile = !kIsWeb;

    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: AppBar(title: const Text('Meal Intelligence')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
        children: [
          if (nativeMobile)
            const _HpjFarmerMobileInsightIntro(
              icon: Icons.restaurant_menu_rounded,
              eyebrow: 'MEAL PULSE SIGNAL',
              title: 'What Jamaica is cooking',
              message:
                  'Use ingredient activity alongside Buyer Demand, reservations and confirmed HPJ supply—not as a guaranteed order forecast.',
            )
          else
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFF073F2C),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.restaurant_menu_rounded,
                    color: Color(0xFFFFD15A),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'See the ingredients appearing in Meal Pulse and the social engagement around them. Use this with Buyer Demand, reservations and confirmed HPJ supply — not as a guaranteed order forecast.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        height: 1.4,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('7 days'),
                selected: days == 7,
                onSelected: (_) => _setDays(7),
              ),
              ChoiceChip(
                label: const Text('14 days'),
                selected: days == 14,
                onSelected: (_) => _setDays(14),
              ),
              ChoiceChip(
                label: const Text('30 days'),
                selected: days == 30,
                onSelected: (_) => _setDays(30),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FutureBuilder<List<HpjMealIntelligenceSignal>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  snapshot.data == null) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(30),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final items =
                  snapshot.data ?? const <HpjMealIntelligenceSignal>[];
              if (items.isEmpty) {
                return const FarmEmptyState(
                  icon: Icons.restaurant_menu_rounded,
                  title: 'No Meal Pulse signal yet',
                  message:
                      'As members post meals, ingredient activity will appear here.',
                );
              }

              return Column(
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(17),
                        border: Border.all(color: FarmColors.line),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: FarmColors.primarySoft,
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(
                                color: FarmColors.deepGreen,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  items[i].ingredient,
                                  style: const TextStyle(
                                    color: FarmColors.ink,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${items[i].mentions} meal mentions • ${items[i].uniqueCreators} creator${items[i].uniqueCreators == 1 ? '' : 's'} • ${items[i].engagement} engagement points',
                                  style: const TextStyle(
                                    color: FarmColors.mutedText,
                                    fontSize: 8.7,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: items[i].growthPercent > 0
                                  ? FarmColors.successSoft
                                  : FarmColors.cardSoft,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              _growth(items[i].growthPercent),
                              style: TextStyle(
                                color: items[i].growthPercent > 0
                                    ? FarmColors.success
                                    : FarmColors.mutedText,
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (i != items.length - 1) const SizedBox(height: 8),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}


// ============================================================================
// HPJ PHASE 118 — FARMER RELATIONSHIP NETWORK
// Aggregate only. Buyer identities and private contact details are never shown.
// ============================================================================

class HpjFarmerRelationshipSummary {
  final int preferredByCustomers;
  final int preferredByBusinesses;
  final int repeatCustomerRelationships;
  final int repeatBusinessRelationships;
  final int totalCompletedCustomerOrders;
  final int totalBusinessMatches;

  const HpjFarmerRelationshipSummary({
    required this.preferredByCustomers,
    required this.preferredByBusinesses,
    required this.repeatCustomerRelationships,
    required this.repeatBusinessRelationships,
    required this.totalCompletedCustomerOrders,
    required this.totalBusinessMatches,
  });

  static const empty = HpjFarmerRelationshipSummary(
    preferredByCustomers: 0,
    preferredByBusinesses: 0,
    repeatCustomerRelationships: 0,
    repeatBusinessRelationships: 0,
    totalCompletedCustomerOrders: 0,
    totalBusinessMatches: 0,
  );

  factory HpjFarmerRelationshipSummary.fromSupabase(
    Map<String, dynamic> row,
  ) {
    int integer(dynamic value) {
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return HpjFarmerRelationshipSummary(
      preferredByCustomers: integer(row['preferred_by_customers']),
      preferredByBusinesses: integer(row['preferred_by_businesses']),
      repeatCustomerRelationships:
          integer(row['repeat_customer_relationships']),
      repeatBusinessRelationships:
          integer(row['repeat_business_relationships']),
      totalCompletedCustomerOrders:
          integer(row['total_completed_customer_orders']),
      totalBusinessMatches: integer(row['total_business_matches']),
    );
  }
}

Future<HpjFarmerRelationshipSummary> fetchHpjFarmerRelationshipSummary(
  String farmerProfileId,
) async {
  try {
    final response = await supabase.rpc(
      'hpj_get_farmer_relationship_summary',
      params: <String, dynamic>{
        'p_farmer_profile_id': farmerProfileId.trim(),
      },
    );

    if (response is! List || response.isEmpty) {
      return HpjFarmerRelationshipSummary.empty;
    }

    return HpjFarmerRelationshipSummary.fromSupabase(
      Map<String, dynamic>.from(response.first as Map),
    );
  } catch (error) {
    farmDebugLog('Farmer relationship summary unavailable: $error');
    return HpjFarmerRelationshipSummary.empty;
  }
}

class HpjFarmerRelationshipNetworkScreen extends StatefulWidget {
  final FarmerProfile profile;

  const HpjFarmerRelationshipNetworkScreen({
    super.key,
    required this.profile,
  });

  @override
  State<HpjFarmerRelationshipNetworkScreen> createState() =>
      _HpjFarmerRelationshipNetworkScreenState();
}

class _HpjFarmerRelationshipNetworkScreenState
    extends State<HpjFarmerRelationshipNetworkScreen> {
  late Future<HpjFarmerRelationshipSummary> _future;

  @override
  void initState() {
    super.initState();
    _future = fetchHpjFarmerRelationshipSummary(widget.profile.id);
  }

  Future<void> _refresh() async {
    final next = fetchHpjFarmerRelationshipSummary(widget.profile.id);
    setState(() => _future = next);
    await next;
  }

  Widget _metric({
    required IconData icon,
    required String value,
    required String title,
    required String subtitle,
  }) {
    return FarmCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: FarmColors.primarySoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: FarmColors.primary,
              size: 21,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        color: FarmColors.deepGreen,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: FarmColors.ink,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: FarmColors.mutedText,
                    fontSize: 8.7,
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

  @override
  Widget build(BuildContext context) {
    final nativeMobile = !kIsWeb;

    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: AppBar(title: const Text('Relationship Network')),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<HpjFarmerRelationshipSummary>(
          future: _future,
          builder: (context, snapshot) {
            final summary =
                snapshot.data ?? HpjFarmerRelationshipSummary.empty;

            if (snapshot.connectionState == ConnectionState.waiting &&
                snapshot.data == null) {
              return ListView(
                padding: EdgeInsets.all(18),
                children: [
                  SizedBox(height: 220),
                  Center(child: CircularProgressIndicator()),
                ],
              );
            }

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
              children: [
                if (nativeMobile)
                  const _HpjFarmerMobileInsightIntro(
                    icon: Icons.handshake_outlined,
                    eyebrow: 'RELATIONSHIP SIGNAL',
                    title: 'Your repeat HPJ network',
                    message:
                        'See preferred and repeat relationship counts while customer and business identities remain private.',
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: FarmColors.deepGreen,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.handshake_outlined,
                          color: Color(0xFFFFD15A),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Strong HPJ relationships are built through reliable fulfilment and repeat sourcing. These are aggregate signals only—customer and business identities stay private.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.2,
                              height: 1.4,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 14),
                _metric(
                  icon: Icons.star_rounded,
                  value: '${summary.preferredByCustomers}',
                  title: 'Customer preferred-farm saves',
                  subtitle:
                      'Customers who intentionally marked your farm as preferred.',
                ),
                const SizedBox(height: 8),
                _metric(
                  icon: Icons.business_center_outlined,
                  value: '${summary.preferredByBusinesses}',
                  title: 'Business preferred-supplier saves',
                  subtitle:
                      'Approved businesses that want HPJ to check your farm first.',
                ),
                const SizedBox(height: 8),
                _metric(
                  icon: Icons.repeat_rounded,
                  value: '${summary.repeatCustomerRelationships}',
                  title: 'Repeat customer relationships',
                  subtitle:
                      'Aggregate customers with two or more completed orders involving your farm.',
                ),
                const SizedBox(height: 8),
                _metric(
                  icon: Icons.sync_alt_rounded,
                  value: '${summary.repeatBusinessRelationships}',
                  title: 'Repeat business relationships',
                  subtitle:
                      'Aggregate business accounts with two or more HPJ supply matches.',
                ),
                const SizedBox(height: 8),
                _metric(
                  icon: Icons.shopping_bag_outlined,
                  value: '${summary.totalCompletedCustomerOrders}',
                  title: 'Completed customer orders',
                  subtitle:
                      'Delivered/completed HPJ orders containing produce from your farm.',
                ),
                const SizedBox(height: 8),
                _metric(
                  icon: Icons.account_tree_outlined,
                  value: '${summary.totalBusinessMatches}',
                  title: 'Business sourcing matches',
                  subtitle:
                      'Reserved or converted HPJ procurement matches involving your supply.',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
