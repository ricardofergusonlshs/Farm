part of harvest_place_app;

// ================================================================
// THE HARVEST PLACE JA
// PHASE 3AR — DEMAND FORECASTING
// ================================================================

class WarehouseDemandForecastRow {
  final String productName;
  final String unit;
  final int horizonDays;
  final int historyDays;
  final double fulfilledHistoryQuantity;
  final double fulfilledLast30Days;
  final double fulfilledPrior30Days;
  final double averageDailyFulfilled;
  final double trendFactor;
  final double historicalRunRateForecast;
  final double approvedOpenDemand;
  final double standingOrderDemand;
  final double planningAheadWeightedDemand;
  final double explicitFutureDemand;
  final double forecastDemand;
  final double confidenceScore;
  final String demandSignal;

  const WarehouseDemandForecastRow({
    required this.productName,
    required this.unit,
    required this.horizonDays,
    required this.historyDays,
    required this.fulfilledHistoryQuantity,
    required this.fulfilledLast30Days,
    required this.fulfilledPrior30Days,
    required this.averageDailyFulfilled,
    required this.trendFactor,
    required this.historicalRunRateForecast,
    required this.approvedOpenDemand,
    required this.standingOrderDemand,
    required this.planningAheadWeightedDemand,
    required this.explicitFutureDemand,
    required this.forecastDemand,
    required this.confidenceScore,
    required this.demandSignal,
  });

  factory WarehouseDemandForecastRow.fromSupabase(Map<String, dynamic> data) {
    double n(dynamic value) => value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '') ?? 0;
    int i(dynamic value) => value is num
        ? value.toInt()
        : int.tryParse(value?.toString() ?? '') ?? 0;

    return WarehouseDemandForecastRow(
      productName: (data['product_name'] ?? 'Produce').toString().trim(),
      unit: (data['unit'] ?? 'unit').toString().trim(),
      horizonDays: i(data['horizon_days']),
      historyDays: i(data['history_days']),
      fulfilledHistoryQuantity: n(data['fulfilled_history_quantity']),
      fulfilledLast30Days: n(data['fulfilled_last_30_days']),
      fulfilledPrior30Days: n(data['fulfilled_prior_30_days']),
      averageDailyFulfilled: n(data['average_daily_fulfilled']),
      trendFactor: n(data['trend_factor']),
      historicalRunRateForecast: n(data['historical_run_rate_forecast']),
      approvedOpenDemand: n(data['approved_open_demand']),
      standingOrderDemand: n(data['standing_order_demand']),
      planningAheadWeightedDemand: n(data['planning_ahead_weighted_demand']),
      explicitFutureDemand: n(data['explicit_future_demand']),
      forecastDemand: n(data['forecast_demand']),
      confidenceScore: n(data['confidence_score']),
      demandSignal: (data['demand_signal'] ?? 'stable').toString().trim().toLowerCase(),
    );
  }

  String quantity(double value) {
    final text = value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
    return '$text $unit';
  }

  String get signalLabel {
    switch (demandSignal) {
      case 'rising': return 'Rising';
      case 'falling': return 'Falling';
      case 'new_demand': return 'New Demand';
      default: return 'Stable';
    }
  }
}

Future<List<WarehouseDemandForecastRow>> fetchWarehouseDemandForecast({
  int horizonDays = 30,
  int historyDays = 90,
}) async {
  await requireAdminAccess();
  final response = await supabase.rpc(
    'admin_warehouse_demand_forecast',
    params: {
      'p_horizon_days': horizonDays,
      'p_history_days': historyDays,
    },
  );
  return (response as List)
      .map((row) => WarehouseDemandForecastRow.fromSupabase(
            Map<String, dynamic>.from(row as Map),
          ))
      .toList();
}

class WarehouseDemandForecastScreen extends StatefulWidget {
  const WarehouseDemandForecastScreen({super.key});

  @override
  State<WarehouseDemandForecastScreen> createState() =>
      _WarehouseDemandForecastScreenState();
}

class _WarehouseDemandForecastScreenState
    extends State<WarehouseDemandForecastScreen> {
  int _horizon = 30;
  late Future<List<WarehouseDemandForecastRow>> _future;

  @override
  void initState() {
    super.initState();
    _future = fetchWarehouseDemandForecast(horizonDays: _horizon);
  }

  Future<void> _refresh() async {
    final next = fetchWarehouseDemandForecast(horizonDays: _horizon);
    setState(() => _future = next);
    await next;
  }

  void _changeHorizon(int days) {
    setState(() {
      _horizon = days;
      _future = fetchWarehouseDemandForecast(horizonDays: days);
    });
  }

  Color _signalColor(WarehouseDemandForecastRow row) {
    if (row.demandSignal == 'rising' || row.demandSignal == 'new_demand') {
      return FarmColors.warning;
    }
    if (row.demandSignal == 'falling') return FarmColors.mutedText;
    return FarmColors.success;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: const _WarehouseAppBar(title: 'Demand Forecasting'),
      body: FutureBuilder<List<WarehouseDemandForecastRow>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError && snapshot.data == null) {
            return Center(child: Text(friendlyAppError(snapshot.error!)));
          }
          final rows = snapshot.data ?? const <WarehouseDemandForecastRow>[];
          final rising = rows.where((e) => e.demandSignal == 'rising').length;
          final explicit = rows.where((e) => e.explicitFutureDemand > 0).length;
          final highConfidence = rows.where((e) => e.confidenceScore >= 75).length;

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 110),
              children: [
                const FarmCard(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Forecast wholesale demand from fulfilled history, open approved orders, standing orders and weighted Planning Ahead signals. Explicit future demand is compared with historical run-rate to reduce double counting.',
                    style: TextStyle(
                      color: FarmColors.mutedText,
                      fontSize: 11,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 7,
                  children: [7, 14, 30, 60].map((days) => ChoiceChip(
                    label: Text('$days days'),
                    selected: _horizon == days,
                    onSelected: (_) => _changeHorizon(days),
                  )).toList(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _DemandMetric(label: 'Lines', value: '${rows.length}')),
                    const SizedBox(width: 8),
                    Expanded(child: _DemandMetric(label: 'Rising', value: '$rising')),
                    const SizedBox(width: 8),
                    Expanded(child: _DemandMetric(label: 'Explicit', value: '$explicit')),
                    const SizedBox(width: 8),
                    Expanded(child: _DemandMetric(label: '75%+', value: '$highConfidence')),
                  ],
                ),
                const SizedBox(height: 14),
                if (rows.isEmpty)
                  const FarmEmptyState(
                    icon: Icons.query_stats_outlined,
                    title: 'No demand signals yet',
                    message: 'Fulfilled wholesale orders, standing orders and Planning Ahead entries will build the forecast.',
                  )
                else
                  ...rows.map((row) {
                    final color = _signalColor(row);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: FarmCard(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Expanded(child: Text(row.productName,
                                style: const TextStyle(color: FarmColors.ink, fontSize: 15, fontWeight: FontWeight.w900))),
                              Text(row.signalLabel,
                                style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900)),
                            ]),
                            const SizedBox(height: 4),
                            Text('${row.quantity(row.forecastDemand)} forecast • ${row.confidenceScore.toStringAsFixed(0)}% confidence',
                              style: const TextStyle(color: FarmColors.primary, fontSize: 11, fontWeight: FontWeight.w900)),
                            const SizedBox(height: 9),
                            Wrap(spacing: 7, runSpacing: 7, children: [
                              _DemandValue(label: 'History run-rate', value: row.quantity(row.historicalRunRateForecast)),
                              _DemandValue(label: 'Approved open', value: row.quantity(row.approvedOpenDemand)),
                              _DemandValue(label: 'Standing', value: row.quantity(row.standingOrderDemand)),
                              _DemandValue(label: 'Planning Ahead', value: row.quantity(row.planningAheadWeightedDemand)),
                            ]),
                            const SizedBox(height: 8),
                            Text('Trend factor ${row.trendFactor.toStringAsFixed(2)}× • ${row.historyDays}-day history',
                              style: const TextStyle(color: FarmColors.mutedText, fontSize: 10, fontWeight: FontWeight.w700)),
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

class _DemandMetric extends StatelessWidget {
  final String label;
  final String value;
  const _DemandMetric({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: FarmColors.cardSoft,
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: FarmColors.line),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(value, style: const TextStyle(color: FarmColors.ink, fontSize: 16, fontWeight: FontWeight.w900)),
      Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: FarmColors.mutedText, fontSize: 8.5, fontWeight: FontWeight.w700)),
    ]),
  );
}

class _DemandValue extends StatelessWidget {
  final String label;
  final String value;
  const _DemandValue({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
    decoration: BoxDecoration(
      color: FarmColors.cardSoft,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: FarmColors.line),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: FarmColors.mutedText, fontSize: 9, fontWeight: FontWeight.w700)),
      const SizedBox(height: 2),
      Text(value, style: const TextStyle(color: FarmColors.ink, fontSize: 11, fontWeight: FontWeight.w900)),
    ]),
  );
}
