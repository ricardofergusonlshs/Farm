part of harvest_place_app;

// ================================================================
// THE HARVEST PLACE JA
// PHASE 3AS — SUPPLY GAP FORECASTING
// ================================================================

class WarehouseSupplyGapRow {
  final String productName;
  final String unit;
  final int horizonDays;
  final double forecastDemand;
  final double approvedOpenDemand;
  final double warehouseAvailable;
  final double warehouseOrderReserved;
  final double confirmedFarmSupply;
  final double expectedFarmSignal;
  final double trustedSupply;
  final double projectedGap;
  final double suggestedProcurementQuantity;
  final double? coverageRatio;
  final DateTime? needByDate;
  final String riskStatus;
  final String recommendedAction;

  const WarehouseSupplyGapRow({
    required this.productName,
    required this.unit,
    required this.horizonDays,
    required this.forecastDemand,
    required this.approvedOpenDemand,
    required this.warehouseAvailable,
    required this.warehouseOrderReserved,
    required this.confirmedFarmSupply,
    required this.expectedFarmSignal,
    required this.trustedSupply,
    required this.projectedGap,
    required this.suggestedProcurementQuantity,
    this.coverageRatio,
    this.needByDate,
    required this.riskStatus,
    required this.recommendedAction,
  });

  factory WarehouseSupplyGapRow.fromSupabase(Map<String, dynamic> data) {
    double n(dynamic value) => value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '') ?? 0;
    double? nullableN(dynamic value) => value == null ? null : (value is num ? value.toDouble() : double.tryParse(value.toString()));
    int i(dynamic value) => value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;
    return WarehouseSupplyGapRow(
      productName: (data['product_name'] ?? 'Produce').toString().trim(),
      unit: (data['unit'] ?? 'unit').toString().trim(),
      horizonDays: i(data['horizon_days']),
      forecastDemand: n(data['forecast_demand']),
      approvedOpenDemand: n(data['approved_open_demand']),
      warehouseAvailable: n(data['warehouse_available']),
      warehouseOrderReserved: n(data['warehouse_order_reserved']),
      confirmedFarmSupply: n(data['confirmed_farm_supply']),
      expectedFarmSignal: n(data['expected_farm_signal']),
      trustedSupply: n(data['trusted_supply']),
      projectedGap: n(data['projected_gap']),
      suggestedProcurementQuantity: n(data['suggested_procurement_quantity']),
      coverageRatio: nullableN(data['coverage_ratio']),
      needByDate: DateTime.tryParse((data['need_by_date'] ?? '').toString()),
      riskStatus: (data['risk_status'] ?? 'covered').toString().trim().toLowerCase(),
      recommendedAction: (data['recommended_action'] ?? '').toString().trim(),
    );
  }

  bool get isCritical => riskStatus == 'critical';
  bool get isShortage => riskStatus == 'shortage';
  bool get isWatch => riskStatus == 'watch';
  bool get isCovered => riskStatus == 'covered';

  String quantity(double value) {
    final text = value == value.roundToDouble() ? value.toInt().toString() : value.toStringAsFixed(1);
    return '$text $unit';
  }
}

Future<List<WarehouseSupplyGapRow>> fetchWarehouseSupplyGapForecast({
  int horizonDays = 30,
  int historyDays = 90,
}) async {
  await requireAdminAccess();
  final response = await supabase.rpc(
    'admin_warehouse_supply_gap_forecast',
    params: {'p_horizon_days': horizonDays, 'p_history_days': historyDays},
  );
  return (response as List)
      .map((row) => WarehouseSupplyGapRow.fromSupabase(Map<String, dynamic>.from(row as Map)))
      .toList();
}

class WarehouseSupplyGapForecastScreen extends StatefulWidget {
  const WarehouseSupplyGapForecastScreen({super.key});
  @override
  State<WarehouseSupplyGapForecastScreen> createState() => _WarehouseSupplyGapForecastScreenState();
}

class _WarehouseSupplyGapForecastScreenState extends State<WarehouseSupplyGapForecastScreen> {
  int _horizon = 30;
  String _filter = 'attention';
  late Future<List<WarehouseSupplyGapRow>> _future;

  @override
  void initState() {
    super.initState();
    _future = fetchWarehouseSupplyGapForecast(horizonDays: _horizon);
  }

  Future<void> _refresh() async {
    final next = fetchWarehouseSupplyGapForecast(horizonDays: _horizon);
    setState(() => _future = next);
    await next;
  }

  void _changeHorizon(int days) {
    setState(() {
      _horizon = days;
      _future = fetchWarehouseSupplyGapForecast(horizonDays: days);
    });
  }

  Color _riskColor(WarehouseSupplyGapRow row) {
    if (row.isCritical) return FarmColors.danger;
    if (row.isShortage) return FarmColors.warning;
    if (row.isWatch) return FarmColors.primary;
    return FarmColors.success;
  }

  String _riskLabel(WarehouseSupplyGapRow row) {
    if (row.isCritical) return 'CRITICAL';
    if (row.isShortage) return 'SHORTAGE';
    if (row.isWatch) return 'WATCH';
    return 'COVERED';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: const _WarehouseAppBar(title: 'Supply Gap Forecast'),
      body: FutureBuilder<List<WarehouseSupplyGapRow>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError && snapshot.data == null) {
            return Center(child: Text(friendlyAppError(snapshot.error!)));
          }
          final rows = snapshot.data ?? const <WarehouseSupplyGapRow>[];
          final filtered = rows.where((row) {
            if (_filter == 'attention') return !row.isCovered;
            if (_filter == 'critical') return row.isCritical;
            if (_filter == 'covered') return row.isCovered;
            return true;
          }).toList();
          final critical = rows.where((e) => e.isCritical).length;
          final gaps = rows.where((e) => e.projectedGap > 0).length;
          final watch = rows.where((e) => e.isWatch).length;

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 110),
              children: [
                const FarmCard(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Forecast demand is compared with usable warehouse stock, stock already reserved to orders, and HPJ-confirmed farmer supply. Unconfirmed farmer supply is shown separately and is never treated as trusted stock.',
                    style: TextStyle(color: FarmColors.mutedText, fontSize: 11, height: 1.4, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(spacing: 7, children: [7,14,30,60].map((days) => ChoiceChip(
                  label: Text('$days days'), selected: _horizon == days, onSelected: (_) => _changeHorizon(days),
                )).toList()),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _SupplyGapMetric(label: 'Critical', value: '$critical')),
                  const SizedBox(width: 8),
                  Expanded(child: _SupplyGapMetric(label: 'Gaps', value: '$gaps')),
                  const SizedBox(width: 8),
                  Expanded(child: _SupplyGapMetric(label: 'Watch', value: '$watch')),
                ]),
                const SizedBox(height: 12),
                SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
                  ChoiceChip(label: const Text('Attention'), selected: _filter == 'attention', onSelected: (_) => setState(() => _filter = 'attention')),
                  const SizedBox(width: 7),
                  ChoiceChip(label: const Text('Critical'), selected: _filter == 'critical', onSelected: (_) => setState(() => _filter = 'critical')),
                  const SizedBox(width: 7),
                  ChoiceChip(label: const Text('Covered'), selected: _filter == 'covered', onSelected: (_) => setState(() => _filter = 'covered')),
                  const SizedBox(width: 7),
                  ChoiceChip(label: const Text('All'), selected: _filter == 'all', onSelected: (_) => setState(() => _filter = 'all')),
                ])),
                const SizedBox(height: 14),
                if (filtered.isEmpty)
                  const FarmEmptyState(icon: Icons.balance_outlined, title: 'No supply gaps in this view', message: 'Change the horizon or filter to inspect more forecast lines.')
                else
                  ...filtered.map((row) {
                    final color = _riskColor(row);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: FarmCard(
                        padding: const EdgeInsets.all(14),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Expanded(child: Text(row.productName, style: const TextStyle(color: FarmColors.ink, fontSize: 15, fontWeight: FontWeight.w900))),
                            Text(_riskLabel(row), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900)),
                          ]),
                          const SizedBox(height: 4),
                          Text(row.projectedGap > 0 ? '${row.quantity(row.projectedGap)} projected gap' : 'Forecast covered',
                            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 9),
                          Wrap(spacing: 7, runSpacing: 7, children: [
                            _SupplyGapValue(label: 'Forecast', value: row.quantity(row.forecastDemand)),
                            _SupplyGapValue(label: 'Warehouse', value: row.quantity(row.warehouseAvailable)),
                            _SupplyGapValue(label: 'Order-reserved', value: row.quantity(row.warehouseOrderReserved)),
                            _SupplyGapValue(label: 'Confirmed farm', value: row.quantity(row.confirmedFarmSupply)),
                            _SupplyGapValue(label: 'Expected signal', value: row.quantity(row.expectedFarmSignal)),
                          ]),
                          const SizedBox(height: 9),
                          Text(row.recommendedAction, style: const TextStyle(color: FarmColors.mutedText, fontSize: 10.5, height: 1.35, fontWeight: FontWeight.w600)),
                        ]),
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

class _SupplyGapMetric extends StatelessWidget {
  final String label;
  final String value;
  const _SupplyGapMetric({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(color: FarmColors.cardSoft, borderRadius: BorderRadius.circular(14), border: Border.all(color: FarmColors.line)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(value, style: const TextStyle(color: FarmColors.ink, fontSize: 17, fontWeight: FontWeight.w900)),
      Text(label, style: const TextStyle(color: FarmColors.mutedText, fontSize: 9.5, fontWeight: FontWeight.w700)),
    ]),
  );
}

class _SupplyGapValue extends StatelessWidget {
  final String label;
  final String value;
  const _SupplyGapValue({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
    decoration: BoxDecoration(color: FarmColors.cardSoft, borderRadius: BorderRadius.circular(12), border: Border.all(color: FarmColors.line)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: FarmColors.mutedText, fontSize: 9, fontWeight: FontWeight.w700)),
      const SizedBox(height: 2),
      Text(value, style: const TextStyle(color: FarmColors.ink, fontSize: 11, fontWeight: FontWeight.w900)),
    ]),
  );
}
