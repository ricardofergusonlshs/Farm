part of harvest_place_app;

// ================================================================
// THE HARVEST PLACE JA
// PHASE 3AQ — STOCKOUT + REPLENISHMENT INTELLIGENCE
// ================================================================

class WarehouseStockRiskRow {
  final String productName;
  final String unit;
  final double warehouseOnHand;
  final double warehouseReserved;
  final double warehouseAvailable;
  final double confirmedFarmSupply;
  final double committedDemand;
  final double issuedLast7Days;
  final double issuedLast30Days;
  final double averageDailyIssue;
  final double projectedHorizonDemand;
  final int horizonDays;
  final double? estimatedDaysCover;
  final double netAfterHorizon;
  final double suggestedReorderQuantity;
  final int oldestLotAgeDays;
  final DateTime? earliestBestBeforeDate;
  final String riskStatus;
  final String recommendedAction;

  const WarehouseStockRiskRow({
    required this.productName,
    required this.unit,
    required this.warehouseOnHand,
    required this.warehouseReserved,
    required this.warehouseAvailable,
    required this.confirmedFarmSupply,
    required this.committedDemand,
    required this.issuedLast7Days,
    required this.issuedLast30Days,
    required this.averageDailyIssue,
    required this.projectedHorizonDemand,
    required this.horizonDays,
    this.estimatedDaysCover,
    required this.netAfterHorizon,
    required this.suggestedReorderQuantity,
    required this.oldestLotAgeDays,
    this.earliestBestBeforeDate,
    required this.riskStatus,
    required this.recommendedAction,
  });

  factory WarehouseStockRiskRow.fromSupabase(Map<String, dynamic> data) {
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

    return WarehouseStockRiskRow(
      productName: (data['product_name'] ?? 'Produce').toString().trim(),
      unit: (data['unit'] ?? 'unit').toString().trim(),
      warehouseOnHand: amount(data['warehouse_on_hand']),
      warehouseReserved: amount(data['warehouse_reserved']),
      warehouseAvailable: amount(data['warehouse_available']),
      confirmedFarmSupply: amount(data['confirmed_farm_supply']),
      committedDemand: amount(data['committed_demand']),
      issuedLast7Days: amount(data['issued_last_7_days']),
      issuedLast30Days: amount(data['issued_last_30_days']),
      averageDailyIssue: amount(data['average_daily_issue']),
      projectedHorizonDemand: amount(data['projected_horizon_demand']),
      horizonDays: optionalInt(data['horizon_days']) ?? 7,
      estimatedDaysCover: optionalAmount(data['estimated_days_cover']),
      netAfterHorizon: amount(data['net_after_horizon']),
      suggestedReorderQuantity: amount(data['suggested_reorder_quantity']),
      oldestLotAgeDays: optionalInt(data['oldest_lot_age_days']) ?? 0,
      earliestBestBeforeDate:
          DateTime.tryParse((data['earliest_best_before_date'] ?? '').toString()),
      riskStatus:
          (data['risk_status'] ?? 'stable').toString().trim().toLowerCase(),
      recommendedAction: (data['recommended_action'] ?? '').toString().trim(),
    );
  }

  bool get isUrgent => const {'stockout', 'critical'}.contains(riskStatus);
  bool get isLow => riskStatus == 'low';
  bool get isExcess => const {'overstock', 'slow_moving'}.contains(riskStatus);

  String quantity(double value) {
    final text = value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
    return '$text $unit';
  }

  String get riskLabel {
    switch (riskStatus) {
      case 'stockout':
        return 'STOCKOUT';
      case 'critical':
        return 'CRITICAL';
      case 'low':
        return 'LOW STOCK';
      case 'overstock':
        return 'OVERSTOCK';
      case 'slow_moving':
        return 'SLOW MOVING';
      default:
        return 'STABLE';
    }
  }
}

Future<List<WarehouseStockRiskRow>> fetchWarehouseStockRiskSummary({
  int horizonDays = 7,
}) async {
  await requireAdminAccess();
  final response = await supabase.rpc(
    'admin_warehouse_stock_risk_summary',
    params: {'p_horizon_days': horizonDays},
  );
  return (response as List)
      .map(
        (row) => WarehouseStockRiskRow.fromSupabase(
          Map<String, dynamic>.from(row),
        ),
      )
      .toList();
}

Future<String> createProcurementActionFromStockRisk({
  required WarehouseStockRiskRow row,
  required int horizonDays,
}) async {
  await requireAdminAccess();
  final response = await supabase.rpc(
    'admin_create_procurement_action_from_stock_risk',
    params: {
      'p_product_name': row.productName,
      'p_unit': row.unit,
      'p_horizon_days': horizonDays,
      'p_need_by_date': null,
    },
  );
  return response?.toString() ?? '';
}

class WarehouseStockoutForecastScreen extends StatefulWidget {
  const WarehouseStockoutForecastScreen({super.key});

  @override
  State<WarehouseStockoutForecastScreen> createState() =>
      _WarehouseStockoutForecastScreenState();
}

class _WarehouseStockoutForecastScreenState
    extends State<WarehouseStockoutForecastScreen> {
  late Future<List<WarehouseStockRiskRow>> _future;
  int _horizonDays = 7;
  String _filter = 'risk';

  @override
  void initState() {
    super.initState();
    _future = fetchWarehouseStockRiskSummary(horizonDays: _horizonDays);
  }

  Future<void> _refresh() async {
    final next = fetchWarehouseStockRiskSummary(horizonDays: _horizonDays);
    setState(() => _future = next);
    await next;
  }

  Color _riskColor(WarehouseStockRiskRow row) {
    if (row.isUrgent) return FarmColors.danger;
    if (row.isLow || row.isExcess) return FarmColors.warning;
    return FarmColors.success;
  }

  Future<void> _createAction(WarehouseStockRiskRow row) async {
    try {
      await createProcurementActionFromStockRisk(
        row: row,
        horizonDays: _horizonDays,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Procurement action created or updated for ${row.productName}.',
          ),
        ),
      );
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyAppError(error))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: const _WarehouseAppBar(title: 'Stock Risk & Replenishment'),
      body: FutureBuilder<List<WarehouseStockRiskRow>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError && snapshot.data == null) {
            return Center(child: Text(friendlyAppError(snapshot.error!)));
          }

          final rows = snapshot.data ?? const <WarehouseStockRiskRow>[];
          final urgent = rows.where((row) => row.isUrgent).length;
          final low = rows.where((row) => row.isLow).length;
          final excess = rows.where((row) => row.isExcess).length;

          final filtered = rows.where((row) {
            switch (_filter) {
              case 'urgent':
                return row.isUrgent;
              case 'low':
                return row.isLow;
              case 'excess':
                return row.isExcess;
              case 'stable':
                return row.riskStatus == 'stable';
              case 'risk':
                return row.riskStatus != 'stable';
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
                        Icons.trending_up_outlined,
                        color: FarmColors.primary,
                        size: 30,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Stockout & Replenishment Intelligence',
                              style: TextStyle(
                                color: FarmColors.ink,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Combine warehouse availability, recent issue velocity, committed demand and confirmed farm supply to flag stockout and overstock risk.',
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
                const SizedBox(height: 12),
                Row(
                  children: [
                    _StockRiskMetric(label: 'Urgent', value: '$urgent'),
                    const SizedBox(width: 8),
                    _StockRiskMetric(label: 'Low Stock', value: '$low'),
                    const SizedBox(width: 8),
                    _StockRiskMetric(label: 'Excess', value: '$excess'),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Planning horizon',
                  style: TextStyle(
                    color: FarmColors.mutedText,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    for (final days in const [7, 14, 30]) ...[
                      ChoiceChip(
                        label: Text('$days days'),
                        selected: _horizonDays == days,
                        onSelected: (_) {
                          setState(() {
                            _horizonDays = days;
                            _future = fetchWarehouseStockRiskSummary(
                              horizonDays: days,
                            );
                          });
                        },
                      ),
                      const SizedBox(width: 7),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final entry in const [
                        ('risk', 'Risks'),
                        ('urgent', 'Urgent'),
                        ('low', 'Low'),
                        ('excess', 'Excess'),
                        ('stable', 'Stable'),
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
                    title: 'No stock-risk lines',
                    message: 'Nothing currently matches this replenishment filter.',
                  )
                else
                  ...filtered.map((row) {
                    final color = _riskColor(row);
                    final cover = row.estimatedDaysCover == null
                        ? 'No velocity'
                        : '${row.estimatedDaysCover!.toStringAsFixed(1)} days';
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
                                    row.productName,
                                    style: const TextStyle(
                                      color: FarmColors.ink,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                Text(
                                  row.riskLabel,
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              row.recommendedAction,
                              style: TextStyle(
                                color: color,
                                fontSize: 10.5,
                                height: 1.35,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 9),
                            Wrap(
                              spacing: 7,
                              runSpacing: 7,
                              children: [
                                _WarehouseIntelChip(
                                  label: 'Available',
                                  value: row.quantity(row.warehouseAvailable),
                                ),
                                _WarehouseIntelChip(
                                  label: 'Committed',
                                  value: row.quantity(row.committedDemand),
                                ),
                                _WarehouseIntelChip(
                                  label: 'Confirmed farm',
                                  value: row.quantity(row.confirmedFarmSupply),
                                ),
                                _WarehouseIntelChip(
                                  label: 'Projected demand',
                                  value: row.quantity(row.projectedHorizonDemand),
                                ),
                                _WarehouseIntelChip(
                                  label: 'Days cover',
                                  value: cover,
                                ),
                                _WarehouseIntelChip(
                                  label: 'Suggested reorder',
                                  value:
                                      row.quantity(row.suggestedReorderQuantity),
                                ),
                              ],
                            ),
                            if (row.suggestedReorderQuantity > 0) ...[
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => _createAction(row),
                                  icon: const Icon(Icons.add_task_outlined),
                                  label: const Text('Create Procurement Action'),
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

class _StockRiskMetric extends StatelessWidget {
  final String label;
  final String value;

  const _StockRiskMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
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
                fontSize: 19,
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
}
