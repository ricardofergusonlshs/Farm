part of harvest_place_app;

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
      collectionDate: parseProductDate(data['collection_date']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
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
  if (date == null || date.millisecondsSinceEpoch <= 0) {
    return 'Not scheduled';
  }
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

String _farmerProductImageKey(String value) {
  return value.trim().toLowerCase().replaceAll(
        RegExp(r'[^a-z0-9]'),
        '',
      );
}

Future<Map<String, String?>> _loadFarmerProductImageMap() async {
  final result = <String, String?>{};

  try {
    final products = await fetchProducts();

    for (final product in products) {
      final key = _farmerProductImageKey(
        product.name,
      );

      if (key.isEmpty || result.containsKey(key)) {
        continue;
      }

      result[key] = cleanHostedImageUrl(
        product.imageUrl,
      );
    }
  } catch (error) {
    farmDebugLog(
      'Farmer product images unavailable: $error',
    );
    rethrow;
  }

  return result;
}

Future<Map<String, String?>>? _farmerProductImageMapFuture;

Future<Map<String, String?>> _farmerProductImages() async {
  final existing = _farmerProductImageMapFuture;
  if (existing != null) return existing;

  final future = _loadFarmerProductImageMap();
  _farmerProductImageMapFuture = future;

  try {
    return await future;
  } catch (_) {
    if (identical(_farmerProductImageMapFuture, future)) {
      _farmerProductImageMapFuture = null;
    }
    rethrow;
  }
}

Future<String?> _farmerProductImageUrl(
  String productName,
) async {
  final images = await _farmerProductImages();

  return images[_farmerProductImageKey(
    productName,
  )];
}

class _FarmerProductThumb extends StatelessWidget {
  final String productName;
  final double size;
  final double radius;

  const _FarmerProductThumb({
    required this.productName,
    this.size = 76,
    this.radius = 14,
  });

  Widget _fallback() {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: FarmColors.primarySoft,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: const Icon(
        Icons.eco_outlined,
        color: FarmColors.primary,
        size: 27,
      ),
    );
  }

  Widget _loading() {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: FarmColors.cardSoft,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _farmerProductImageUrl(
        productName,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData &&
            !snapshot.hasError) {
          return _loading();
        }

        final imageUrl = snapshot.data?.trim() ?? '';

        if (imageUrl.isEmpty) {
          return _fallback();
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Image.network(
            imageUrl,
            width: size,
            height: size,
            fit: BoxFit.cover,
            semanticLabel: '$productName produce',
            errorBuilder: (_, __, ___) => _fallback(),
          ),
        );
      },
    );
  }
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
            'See HPJ demand, report supply, follow collections and track payouts.',
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

class FarmerDemandBoardScreen extends StatefulWidget {
  final FarmerProfile profile;
  final String? initialWatchKey;

  const FarmerDemandBoardScreen({
    super.key,
    required this.profile,
    this.initialWatchKey,
  });

  @override
  State<FarmerDemandBoardScreen> createState() =>
      _FarmerDemandBoardScreenState();
}

class _FarmerDemandBoardScreenState extends State<FarmerDemandBoardScreen> {
  int _days = 30;
  late Future<List<FarmerMarketDemandOpportunity>> _future;

  @override
  void initState() {
    super.initState();
    _future = fetchFarmerMarketDemandBoard(_days);
  }

  Future<void> _refresh() async {
    final next = fetchFarmerMarketDemandBoard(_days);
    setState(() => _future = next);
    await next;
  }

  void _retry() {
    setState(() {
      _future = fetchFarmerMarketDemandBoard(_days);
    });
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
        return FarmColors.warning;
      case 'opportunity':
        return FarmColors.primary;
      case 'covered_by_you':
        return FarmColors.success;
      default:
        return FarmColors.mutedText;
    }
  }

  Future<void> _reportSupply(
    FarmerMarketDemandOpportunity demand,
  ) async {
    if (!widget.profile.isApproved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Your farmer profile must be approved first.',
          ),
        ),
      );
      return;
    }

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FarmerDemandSupplySheet(
        demand: demand,
      ),
    );

    if (!mounted || saved != true) {
      return;
    }

    var refreshed = true;
    try {
      await _refresh();
    } catch (error) {
      refreshed = false;
      farmDebugLog(
        'Farmer demand refresh after saved supply skipped: $error',
      );
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          refreshed
              ? '${demand.productName} supply reported. HPJ can now review it in Matching.'
              : '${demand.productName} supply was saved. Current demand totals could not refresh yet; pull down to retry.',
        ),
      ),
    );
  }

  Widget _metric(String label, double value, String unit) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: FarmColors.cardSoft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: FarmColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: FarmColors.mutedText,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '${_farmerPartnerNumber(value)} $unit',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: FarmColors.ink,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.profile.isApproved) {
      return Scaffold(
        backgroundColor: FarmColors.background,
        appBar: AppBar(title: const Text('Market Demand')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: FarmEmptyState(
              icon: Icons.verified_user_outlined,
              title: 'Farmer approval required',
              message:
                  'HPJ must approve your farmer profile before market demand is shown.',
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: AppBar(title: const Text('Market Demand')),
      body: FutureBuilder<List<FarmerMarketDemandOpportunity>>(
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
                      size: 34,
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
                      onPressed: _retry,
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
                        hpjFarmerDemandWatchKey(
                          item.productName,
                          item.unit,
                        ) ==
                        requestedWatchKey,
                  )
                  .toList();

          final exactDemandFound = focusedRows.isNotEmpty;
          final rows = exactDemandFound ? focusedRows : allRows;

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
              children: [
                FarmCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'What buyers need',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'Look for the produce you grow. HPJ shows combined buyer demand without revealing private buyer details.',
                        style: TextStyle(
                          color: FarmColors.mutedText,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [14, 30, 60]
                            .map(
                              (d) => ChoiceChip(
                                label: Text('$d days'),
                                selected: _days == d,
                                onSelected: (_) => _setDays(d),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (requestedWatchKey.isNotEmpty) ...[
                  _FarmerNotificationFocusNotice(
                    found: exactDemandFound,
                    foundMessage:
                        'Opened from your notification. Showing the matching buyer-demand signal.',
                    missingMessage:
                        'That demand signal has changed or is no longer active. Showing current buyer demand instead.',
                  ),
                  const SizedBox(height: 12),
                ],
                if (rows.isEmpty)
                  const FarmEmptyState(
                    icon: Icons.trending_up_outlined,
                    title: 'No active demand signals',
                    message:
                        'New wholesale requirements will appear here when businesses submit demand.',
                  )
                else
                  ...rows.map((item) {
                    final color = _signalColor(item);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: FarmCard(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _FarmerProductThumb(
                                  productName: item.productName,
                                  size: 78,
                                  radius: 14,
                                ),
                                const SizedBox(width: 11),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item.productName,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: FarmColors.ink,
                                                fontSize: 17,
                                                height: 1.05,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 7,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: color.withOpacity(0.10),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                            child: Text(
                                              item.signalLabel,
                                              style: TextStyle(
                                                color: color,
                                                fontSize: 8.2,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Needed by ${_farmerPartnerDate(item.nextNeedBy)}',
                                        style: const TextStyle(
                                          color: FarmColors.mutedText,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 10.2,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        item.opportunityGap > 0
                                            ? '${_farmerPartnerNumber(item.opportunityGap)} ${item.unit} opportunity'
                                            : 'Your reported supply currently covers this need',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: FarmColors.primary,
                                          fontSize: 10.2,
                                          height: 1.25,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 11),
                            Row(
                              children: [
                                _metric('Market need', item.visibleDemand,
                                    item.unit),
                                const SizedBox(width: 7),
                                _metric('Your supply', item.myReportedSupply,
                                    item.unit),
                                const SizedBox(width: 7),
                                _metric('Opportunity', item.opportunityGap,
                                    item.unit),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Approved ${_farmerPartnerNumber(item.approvedDemand)} • Standing ${_farmerPartnerNumber(item.standingDemand)} • Planning ${_farmerPartnerNumber(item.planningDemand)} ${item.unit}',
                              style: const TextStyle(
                                color: FarmColors.mutedText,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (item.opportunityGap > 0) ...[
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () => _reportSupply(item),
                                  icon: const Icon(Icons.agriculture_outlined),
                                  label: const Text('I Can Supply This'),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          );
        },
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

    if (quantity == null || !quantity.isFinite || quantity <= 0) {
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
    setState(() => _future = next);
    await next;
  }

  void _retry() {
    setState(() {
      _future = fetchFarmerCollectionSchedule();
    });
  }

  Color _statusColor(FarmerCollectionScheduleItem item) {
    if (item.stopStatus == 'collected' || item.receivingStatus == 'completed') {
      return FarmColors.success;
    }
    if (item.stopStatus == 'skipped' || item.stopStatus == 'cancelled') {
      return FarmColors.danger;
    }
    if (item.runStatus == 'in_progress') return FarmColors.warning;
    if (_isScheduledCollection(item)) return FarmColors.primary;
    return FarmColors.mutedText;
  }

  bool _isScheduledCollection(FarmerCollectionScheduleItem item) {
    const scheduledRunStatuses = <String>{
      'planned',
      'scheduled',
      'assigned',
      'ready',
    };
    const scheduledStopStatuses = <String>{
      'planned',
      'scheduled',
      'pending',
      'assigned',
      'ready',
    };

    return scheduledRunStatuses.contains(item.runStatus) ||
        scheduledStopStatuses.contains(item.stopStatus);
  }

  String _statusLabel(FarmerCollectionScheduleItem item) {
    if (item.receivingStatus == 'completed') return 'Received';
    if (item.stopStatus == 'collected') return 'Collected';
    if (item.stopStatus == 'skipped') return 'Skipped';
    if (item.stopStatus == 'cancelled') return 'Cancelled';
    if (item.runStatus == 'in_progress') return 'On Route';
    if (_isScheduledCollection(item)) return 'Scheduled';
    return 'Status unavailable';
  }

  String _collectionMethodLabel(FarmerCollectionScheduleItem item) {
    switch (item.collectionMethod) {
      case 'farmer_delivery':
        return 'Farmer Delivery';
      case 'hpj_collection':
      case 'hpj_pickup':
      case 'collection':
      case 'pickup':
        return 'HPJ Collection';
      default:
        return 'Method unavailable';
    }
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cloud_off_outlined,
                      color: FarmColors.mutedText,
                      size: 34,
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
                      onPressed: _retry,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
                    ),
                  ],
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

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
              children: [
                const FarmCard(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HPJ Collection Schedule',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Only collection stops linked to your farmer profile are shown.',
                        style: TextStyle(
                          color: FarmColors.mutedText,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
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
                if (rows.isEmpty)
                  const FarmEmptyState(
                    icon: Icons.local_shipping_outlined,
                    title: 'No collections scheduled',
                    message:
                        'Once HPJ reserves your supply and schedules collection, the stop will appear here.',
                  )
                else
                  ...rows.map((item) {
                    final color = _statusColor(item);
                    final method = _collectionMethodLabel(item);
                    final stopLabel =
                        item.sequenceNo > 0 ? ' • Stop ${item.sequenceNo}' : '';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: FarmCard(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.productName,
                                    style: const TextStyle(
                                      color: FarmColors.ink,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.10),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    _statusLabel(item),
                                    style: TextStyle(
                                      color: color,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 7),
                            Text(
                              '${_farmerPartnerDate(item.collectionDate)} • $method$stopLabel',
                              style: const TextStyle(
                                color: FarmColors.mutedText,
                                fontWeight: FontWeight.w700,
                                fontSize: 10.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Planned: ${_farmerPartnerNumber(item.plannedQuantity)} ${item.unit}'
                              '${item.collectedQuantity > 0 ? ' • Collected: ${_farmerPartnerNumber(item.collectedQuantity)} ${item.unit}' : ''}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w900),
                            ),
                            if (item.driverName.isNotEmpty ||
                                item.vehicleLabel.isNotEmpty) ...[
                              const SizedBox(height: 5),
                              Text(
                                [item.driverName, item.vehicleLabel]
                                    .where((x) => x.isNotEmpty)
                                    .join(' • '),
                                style: const TextStyle(
                                  color: FarmColors.mutedText,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                            if (item.qualityGrade.isNotEmpty) ...[
                              const SizedBox(height: 5),
                              Text(
                                'Quality grade: ${item.qualityGrade}',
                                style: const TextStyle(
                                  color: FarmColors.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                            if (item.note.isNotEmpty) ...[
                              const SizedBox(height: 5),
                              Text(
                                item.note,
                                style: const TextStyle(
                                  color: FarmColors.mutedText,
                                  fontSize: 10,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }
}
