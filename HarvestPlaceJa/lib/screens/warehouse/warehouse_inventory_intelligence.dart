part of harvest_place_app;

// ================================================================
// THE HARVEST PLACE JA
// PHASE 3AO — INVENTORY INTELLIGENCE + STOCK AGEING
// ================================================================

class WarehouseInventoryHealthRow {
  final String lotId;
  final String lotCode;
  final String productName;
  final String unit;
  final String farmName;
  final String farmerName;
  final String parish;
  final String storageLocationCode;
  final double quantityOnHand;
  final double quantityReserved;
  final double availableQuantity;
  final double quantityWasted;
  final DateTime? receivedAt;
  final DateTime? bestBeforeDate;
  final int ageDays;
  final int? daysToBestBefore;
  final double issuedLast7Days;
  final double issuedVelocityWindow;
  final int velocityWindowDays;
  final double averageDailyIssue;
  final double? estimatedDaysCover;
  final double wasteRatioPercent;
  final DateTime? lastIssueAt;
  final String healthStatus;
  final String healthReason;

  const WarehouseInventoryHealthRow({
    required this.lotId,
    required this.lotCode,
    required this.productName,
    required this.unit,
    required this.farmName,
    required this.farmerName,
    required this.parish,
    required this.storageLocationCode,
    required this.quantityOnHand,
    required this.quantityReserved,
    required this.availableQuantity,
    required this.quantityWasted,
    this.receivedAt,
    this.bestBeforeDate,
    required this.ageDays,
    this.daysToBestBefore,
    required this.issuedLast7Days,
    required this.issuedVelocityWindow,
    required this.velocityWindowDays,
    required this.averageDailyIssue,
    this.estimatedDaysCover,
    required this.wasteRatioPercent,
    this.lastIssueAt,
    required this.healthStatus,
    required this.healthReason,
  });

  factory WarehouseInventoryHealthRow.fromSupabase(Map<String, dynamic> data) {
    double amount(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    double? optionalAmount(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    int? optionalInt(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString());
    }

    return WarehouseInventoryHealthRow(
      lotId: (data['lot_id'] ?? '').toString(),
      lotCode: (data['lot_code'] ?? '').toString().trim(),
      productName: (data['product_name'] ?? 'Produce').toString().trim(),
      unit: (data['unit'] ?? 'unit').toString().trim(),
      farmName: (data['farm_name'] ?? '').toString().trim(),
      farmerName: (data['farmer_name'] ?? '').toString().trim(),
      parish: (data['parish'] ?? '').toString().trim(),
      storageLocationCode:
          (data['storage_location_code'] ?? '').toString().trim(),
      quantityOnHand: amount(data['quantity_on_hand']),
      quantityReserved: amount(data['quantity_reserved']),
      availableQuantity: amount(data['available_quantity']),
      quantityWasted: amount(data['quantity_wasted']),
      receivedAt: DateTime.tryParse((data['received_at'] ?? '').toString()),
      bestBeforeDate:
          DateTime.tryParse((data['best_before_date'] ?? '').toString()),
      ageDays: optionalInt(data['age_days']) ?? 0,
      daysToBestBefore: optionalInt(data['days_to_best_before']),
      issuedLast7Days: amount(data['issued_last_7_days']),
      issuedVelocityWindow: amount(data['issued_velocity_window']),
      velocityWindowDays: optionalInt(data['velocity_window_days']) ?? 30,
      averageDailyIssue: amount(data['average_daily_issue']),
      estimatedDaysCover: optionalAmount(data['estimated_days_cover']),
      wasteRatioPercent: amount(data['waste_ratio_percent']),
      lastIssueAt: DateTime.tryParse((data['last_issue_at'] ?? '').toString()),
      healthStatus:
          (data['health_status'] ?? 'healthy').toString().trim().toLowerCase(),
      healthReason: (data['health_reason'] ?? '').toString().trim(),
    );
  }

  bool get isCritical => const {
        'expired',
        'critical_expiry',
        'quarantined',
      }.contains(healthStatus);

  bool get isExpiryRisk => const {
        'expired',
        'critical_expiry',
        'expiring_soon',
        'missing_best_before',
      }.contains(healthStatus);

  bool get isSlow => const {'stale', 'slow_moving'}.contains(healthStatus);

  String quantity(double value) {
    final text = value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
    return '$text $unit';
  }

  String get healthLabel {
    switch (healthStatus) {
      case 'expired':
        return 'Expired';
      case 'critical_expiry':
        return 'Critical Expiry';
      case 'expiring_soon':
        return 'Expiring Soon';
      case 'missing_best_before':
        return 'Missing Best-Before';
      case 'high_waste':
        return 'High Waste';
      case 'stale':
        return 'Stale Stock';
      case 'slow_moving':
        return 'Slow Moving';
      case 'quarantined':
        return 'Quarantined';
      case 'depleted':
        return 'Depleted';
      default:
        return 'Healthy';
    }
  }
}

Future<List<WarehouseInventoryHealthRow>> fetchWarehouseInventoryHealth({
  int velocityDays = 30,
}) async {
  await requireAdminAccess();
  final response = await supabase.rpc(
    'admin_warehouse_inventory_health',
    params: {'p_velocity_days': velocityDays},
  );
  return (response as List)
      .map(
        (row) => WarehouseInventoryHealthRow.fromSupabase(
          Map<String, dynamic>.from(row),
        ),
      )
      .toList();
}

class WarehouseInventoryIntelligenceScreen extends StatefulWidget {
  const WarehouseInventoryIntelligenceScreen({super.key});

  @override
  State<WarehouseInventoryIntelligenceScreen> createState() =>
      _WarehouseInventoryIntelligenceScreenState();
}

class _WarehouseInventoryIntelligenceScreenState
    extends State<WarehouseInventoryIntelligenceScreen> {
  late Future<List<WarehouseInventoryHealthRow>> _future;
  String _filter = 'risk';
  int _velocityDays = 30;

  @override
  void initState() {
    super.initState();
    _future = fetchWarehouseInventoryHealth(velocityDays: _velocityDays);
  }

  Future<void> _refresh() async {
    final next = fetchWarehouseInventoryHealth(velocityDays: _velocityDays);
    setState(() => _future = next);
    await next;
  }

  Color _statusColor(WarehouseInventoryHealthRow row) {
    if (row.isCritical) return FarmColors.danger;
    if (row.isExpiryRisk || row.healthStatus == 'high_waste') {
      return FarmColors.warning;
    }
    if (row.isSlow) return FarmColors.warning;
    return FarmColors.success;
  }

  String _dateLabel(DateTime? date) {
    if (date == null) return 'Not set';
    final d = date.toLocal();
    return '${d.day}/${d.month}/${d.year}';
  }

  Widget _metric(String label, String value) {
    return Expanded(
      child: FarmCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: FarmColors.ink,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: FarmColors.mutedText,
                fontSize: 9.5,
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
    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: const _WarehouseAppBar(title: 'Inventory Intelligence'),
      body: FutureBuilder<List<WarehouseInventoryHealthRow>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError && snapshot.data == null) {
            return Center(child: Text(friendlyAppError(snapshot.error!)));
          }

          final rows = snapshot.data ?? const <WarehouseInventoryHealthRow>[];
          final critical = rows.where((row) => row.isCritical).length;
          final expiry = rows.where((row) => row.isExpiryRisk).length;
          final slow = rows.where((row) => row.isSlow).length;
          final healthy = rows.where((row) => row.healthStatus == 'healthy').length;

          final filtered = rows.where((row) {
            switch (_filter) {
              case 'critical':
                return row.isCritical;
              case 'expiry':
                return row.isExpiryRisk;
              case 'slow':
                return row.isSlow;
              case 'healthy':
                return row.healthStatus == 'healthy';
              case 'risk':
                return row.healthStatus != 'healthy' &&
                    row.healthStatus != 'depleted';
              default:
                return true;
            }
          }).toList();

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 110),
              children: [
                FarmCard(
                  padding: const EdgeInsets.all(16),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.analytics_outlined,
                        color: FarmColors.primary,
                        size: 30,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Inventory Health & Ageing',
                              style: TextStyle(
                                color: FarmColors.ink,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'See expiry pressure, stock age, issue velocity, estimated cover and waste risk at lot level.',
                              style: TextStyle(
                                color: FarmColors.mutedText,
                                fontSize: 10.5,
                                height: 1.35,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _metric('Critical', '$critical'),
                    const SizedBox(width: 7),
                    _metric('Expiry Risk', '$expiry'),
                    const SizedBox(width: 7),
                    _metric('Slow', '$slow'),
                    const SizedBox(width: 7),
                    _metric('Healthy', '$healthy'),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text(
                      'Velocity window',
                      style: TextStyle(
                        color: FarmColors.mutedText,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 10),
                    DropdownButton<int>(
                      value: _velocityDays,
                      items: const [
                        DropdownMenuItem(value: 14, child: Text('14 days')),
                        DropdownMenuItem(value: 30, child: Text('30 days')),
                        DropdownMenuItem(value: 60, child: Text('60 days')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _velocityDays = value;
                          _future = fetchWarehouseInventoryHealth(
                            velocityDays: value,
                          );
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final entry in const [
                        ('risk', 'Risks'),
                        ('critical', 'Critical'),
                        ('expiry', 'Expiry'),
                        ('slow', 'Slow'),
                        ('healthy', 'Healthy'),
                        ('all', 'All'),
                      ]) ...[
                        ChoiceChip(
                          label: Text(entry.$2),
                          selected: _filter == entry.$1,
                          onSelected: (_) => setState(() => _filter = entry.$1),
                        ),
                        const SizedBox(width: 7),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (filtered.isEmpty)
                  const FarmEmptyState(
                    icon: Icons.check_circle_outline,
                    title: 'No inventory lines here',
                    message: 'Nothing currently matches this health filter.',
                  )
                else
                  ...filtered.map((row) {
                    final color = _statusColor(row);
                    final cover = row.estimatedDaysCover == null
                        ? 'No recent issue velocity'
                        : '${row.estimatedDaysCover!.toStringAsFixed(1)} days cover';
                    final expiryText = row.daysToBestBefore == null
                        ? 'Best-before not set'
                        : row.daysToBestBefore! < 0
                            ? '${row.daysToBestBefore!.abs()} days past best-before'
                            : '${row.daysToBestBefore} days to best-before';
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
                                    '${row.productName} • ${row.lotCode}',
                                    style: const TextStyle(
                                      color: FarmColors.ink,
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.10),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    row.healthLabel,
                                    style: TextStyle(
                                      color: color,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              row.healthReason,
                              style: TextStyle(
                                color: color,
                                fontSize: 10.5,
                                height: 1.35,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 7,
                              runSpacing: 7,
                              children: [
                                _WarehouseIntelChip(
                                  label: 'On hand',
                                  value: row.quantity(row.quantityOnHand),
                                ),
                                _WarehouseIntelChip(
                                  label: 'Available',
                                  value: row.quantity(row.availableQuantity),
                                ),
                                _WarehouseIntelChip(
                                  label: 'Age',
                                  value: '${row.ageDays} days',
                                ),
                                _WarehouseIntelChip(
                                  label: 'Cover',
                                  value: cover,
                                ),
                                _WarehouseIntelChip(
                                  label: 'Expiry',
                                  value: expiryText,
                                ),
                                _WarehouseIntelChip(
                                  label: 'Waste',
                                  value:
                                      '${row.wasteRatioPercent.toStringAsFixed(1)}%',
                                ),
                              ],
                            ),
                            const SizedBox(height: 9),
                            Text(
                              'Location: ${row.storageLocationCode.isEmpty ? 'Unassigned' : row.storageLocationCode} • Best-before: ${_dateLabel(row.bestBeforeDate)} • 7-day issues: ${row.quantity(row.issuedLast7Days)}',
                              style: const TextStyle(
                                color: FarmColors.mutedText,
                                fontSize: 9.5,
                                height: 1.35,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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

class _WarehouseIntelChip extends StatelessWidget {
  final String label;
  final String value;

  const _WarehouseIntelChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: FarmColors.cardSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FarmColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: FarmColors.mutedText,
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: FarmColors.ink,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
