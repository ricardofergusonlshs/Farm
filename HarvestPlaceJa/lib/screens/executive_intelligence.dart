part of harvest_place_app;

// ================================================================
// THE HARVEST PLACE JA
// PHASE 5A — EXECUTIVE INTELLIGENCE DASHBOARD
// ================================================================

class ExecutiveIntelligenceSummary {
  final int horizonDays;
  final double financeHealthScore;
  final double financeReconciliationPercent;
  final double netRevenue;
  final double contributionMargin;
  final double contributionMarginPercent;
  final double contributionChangePercent;
  final double openReceivableAmount;
  final double overdueReceivableAmount;
  final double openFarmerPayableAmount;
  final double cashPlanningPosition;
  final double forecastDemandQuantity;
  final double trustedSupplyQuantity;
  final double projectedSupplyGap;
  final int supplyRiskProductCount;
  final int criticalSupplyProductCount;
  final int inventoryAttentionLotCount;
  final double inventoryWasteQuantity;
  final int supplierRiskCount;
  final int supplierWatchCount;
  final int commercialAttentionCount;
  final int bankOpenTransactionCount;
  final int missingCostInvoiceCount;
  final String executiveStatus;

  const ExecutiveIntelligenceSummary({
    required this.horizonDays,
    required this.financeHealthScore,
    required this.financeReconciliationPercent,
    required this.netRevenue,
    required this.contributionMargin,
    required this.contributionMarginPercent,
    required this.contributionChangePercent,
    required this.openReceivableAmount,
    required this.overdueReceivableAmount,
    required this.openFarmerPayableAmount,
    required this.cashPlanningPosition,
    required this.forecastDemandQuantity,
    required this.trustedSupplyQuantity,
    required this.projectedSupplyGap,
    required this.supplyRiskProductCount,
    required this.criticalSupplyProductCount,
    required this.inventoryAttentionLotCount,
    required this.inventoryWasteQuantity,
    required this.supplierRiskCount,
    required this.supplierWatchCount,
    required this.commercialAttentionCount,
    required this.bankOpenTransactionCount,
    required this.missingCostInvoiceCount,
    required this.executiveStatus,
  });

  factory ExecutiveIntelligenceSummary.fromSupabase(Map<String, dynamic> data) {
    double n(dynamic v) =>
        v is num ? v.toDouble() : double.tryParse('${v ?? ''}') ?? 0;
    int i(dynamic v) => v is num ? v.toInt() : int.tryParse('${v ?? ''}') ?? 0;
    return ExecutiveIntelligenceSummary(
      horizonDays: i(data['horizon_days']),
      financeHealthScore: n(data['finance_health_score']),
      financeReconciliationPercent: n(data['finance_reconciliation_percent']),
      netRevenue: n(data['net_revenue']),
      contributionMargin: n(data['contribution_margin']),
      contributionMarginPercent: n(data['contribution_margin_percent']),
      contributionChangePercent: n(data['contribution_change_percent']),
      openReceivableAmount: n(data['open_receivable_amount']),
      overdueReceivableAmount: n(data['overdue_receivable_amount']),
      openFarmerPayableAmount: n(data['open_farmer_payable_amount']),
      cashPlanningPosition: n(data['cash_planning_position']),
      forecastDemandQuantity: n(data['forecast_demand_quantity']),
      trustedSupplyQuantity: n(data['trusted_supply_quantity']),
      projectedSupplyGap: n(data['projected_supply_gap']),
      supplyRiskProductCount: i(data['supply_risk_product_count']),
      criticalSupplyProductCount: i(data['critical_supply_product_count']),
      inventoryAttentionLotCount: i(data['inventory_attention_lot_count']),
      inventoryWasteQuantity: n(data['inventory_waste_quantity']),
      supplierRiskCount: i(data['supplier_risk_count']),
      supplierWatchCount: i(data['supplier_watch_count']),
      commercialAttentionCount: i(data['commercial_attention_count']),
      bankOpenTransactionCount: i(data['bank_open_transaction_count']),
      missingCostInvoiceCount: i(data['missing_cost_invoice_count']),
      executiveStatus:
          (data['executive_status'] ?? 'watch').toString().toLowerCase(),
    );
  }
}

Future<ExecutiveIntelligenceSummary> fetchExecutiveIntelligenceSummary(
    int days) async {
  await requireAdminAccess();
  final response = await supabase
      .rpc('admin_executive_intelligence_summary', params: {'p_days': days});
  if (response is List && response.isNotEmpty) {
    return ExecutiveIntelligenceSummary.fromSupabase(
        Map<String, dynamic>.from(response.first as Map));
  }
  if (response is Map)
    return ExecutiveIntelligenceSummary.fromSupabase(
        Map<String, dynamic>.from(response));
  throw Exception('Executive intelligence could not be loaded.');
}

class ExecutiveIntelligenceScreen extends StatefulWidget {
  const ExecutiveIntelligenceScreen({super.key});
  @override
  State<ExecutiveIntelligenceScreen> createState() =>
      _ExecutiveIntelligenceScreenState();
}

class _ExecutiveIntelligenceScreenState
    extends State<ExecutiveIntelligenceScreen> {
  int _days = 30;
  late Future<ExecutiveIntelligenceSummary> _future;

  @override
  void initState() {
    super.initState();
    _future = fetchExecutiveIntelligenceSummary(_days);
  }

  Future<void> _refresh() async {
    final next = fetchExecutiveIntelligenceSummary(_days);
    setState(() => _future = next);
    await next;
  }

  void _setDays(int value) {
    if (_days == value) return;
    setState(() {
      _days = value;
      _future = fetchExecutiveIntelligenceSummary(_days);
    });
  }

  void _open(Widget screen) {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => screen))
        .then((_) => _refresh());
  }

  Color _statusColor(String status) {
    if (status == 'attention') return FarmColors.danger;
    if (status == 'watch') return FarmColors.warning;
    return FarmColors.success;
  }

  Widget _metric(String label, String value, IconData icon, {String? note}) {
    return Container(
      width: 152,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FarmColors.cardSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: FarmColors.line),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 18, color: FarmColors.primary),
        const SizedBox(height: 7),
        Text(value,
            style: const TextStyle(
                color: FarmColors.ink,
                fontSize: 14,
                fontWeight: FontWeight.w900)),
        Text(label,
            style: const TextStyle(
                color: FarmColors.mutedText,
                fontSize: 9.5,
                fontWeight: FontWeight.w700)),
        if (note != null && note.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(note,
              style: const TextStyle(
                  color: FarmColors.mutedText, fontSize: 8.5, height: 1.25)),
        ],
      ]),
    );
  }

  Widget _actionCard(
      {required IconData icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: FarmColors.cardSoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: FarmColors.line),
        ),
        child: Row(children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: FarmColors.primarySoft,
                borderRadius: BorderRadius.circular(13)),
            child: Icon(icon, color: FarmColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    style: const TextStyle(
                        color: FarmColors.ink, fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(subtitle,
                    style: const TextStyle(
                        color: FarmColors.mutedText,
                        fontSize: 10,
                        height: 1.3,
                        fontWeight: FontWeight.w600)),
              ])),
          const Icon(Icons.chevron_right_rounded, color: FarmColors.mutedText),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ExecutiveIntelligenceSummary>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            snapshot.data == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError && snapshot.data == null) {
          farmDebugLog('HPJ EXECUTIVE LOAD ERROR: ${snapshot.error}');
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                kDebugMode
                    ? 'Executive load error:\n${snapshot.error}'
                    : friendlyAppError(snapshot.error!),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        final s = snapshot.data;
        if (s == null) return const SizedBox.shrink();
        final statusColor = _statusColor(s.executiveStatus);
        final supplyCoverage = s.forecastDemandQuantity > 0
            ? (s.trustedSupplyQuantity / s.forecastDemandQuantity * 100)
            : 100.0;

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
                      Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.dashboard_outlined,
                                color: FarmColors.primary, size: 30),
                            const SizedBox(width: 12),
                            const Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  Text('Executive Intelligence',
                                      style: TextStyle(
                                          color: FarmColors.ink,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900)),
                                  SizedBox(height: 4),
                                  Text(
                                      'One owner view across finance, margin, cash planning, supply, inventory and supplier risk.',
                                      style: TextStyle(
                                          color: FarmColors.mutedText,
                                          fontSize: 10.5,
                                          height: 1.35,
                                          fontWeight: FontWeight.w600)),
                                ])),
                          ]),
                      const SizedBox(height: 14),
                      Row(children: [
                        Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                                color: statusColor, shape: BoxShape.circle)),
                        const SizedBox(width: 7),
                        Text(
                            'Executive status: ${s.executiveStatus.toUpperCase()}',
                            style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w900,
                                fontSize: 11)),
                      ]),
                      const SizedBox(height: 12),
                      Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [7, 30, 90]
                              .map((d) => ChoiceChip(
                                  label: Text('$d days'),
                                  selected: _days == d,
                                  onSelected: (_) => _setDays(d)))
                              .toList()),
                    ]),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                    child: _actionCard(
                        icon: Icons.trending_up_outlined,
                        title: 'Business Forecast',
                        subtitle:
                            'See sales, cash, procurement and customer trends.',
                        onTap: () => _open(BusinessForecastingScreen(
                            initialHorizonDays: _days)))),
                const SizedBox(width: 10),
                Expanded(
                    child: _actionCard(
                        icon: Icons.lightbulb_outline,
                        title: 'Decision Center',
                        subtitle: 'Prioritized actions from live HPJ signals.',
                        onTap: () => _open(ExecutiveDecisionCenterScreen(
                            initialHorizonDays: _days)))),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                    child: _actionCard(
                        icon: Icons.show_chart_rounded,
                        title: 'Advanced Forecast',
                        subtitle: 'Confidence ranges and forecast accuracy.',
                        onTap: () => _open(AdvancedForecastingScreen(
                            initialHorizonDays: _days)))),
                const SizedBox(width: 10),
                Expanded(
                    child: _actionCard(
                        icon: Icons.science_outlined,
                        title: 'Scenario Planner',
                        subtitle: 'Test sales, supply, cost and price changes.',
                        onTap: () => _open(ScenarioPlanningScreen(
                            initialHorizonDays: _days)))),
              ]),
              const SizedBox(height: 10),
              _actionCard(
                  icon: Icons.notifications_active_outlined,
                  title: 'Business Alerts',
                  subtitle:
                      'Early warnings for cash, supply, margin, demand and farmer payouts.',
                  onTap: () =>
                      _open(BusinessAlertsScreen(initialHorizonDays: _days))),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                    child: _actionCard(
                        icon: Icons.fact_check_outlined,
                        title: 'Release Validation',
                        subtitle:
                            'Run pre-test schema, security and integrity checks.',
                        onTap: () => _open(ReleaseValidationScreen(
                            initialHorizonDays: _days)))),
                const SizedBox(width: 10),
                Expanded(
                    child: _actionCard(
                        icon: Icons.tune_rounded,
                        title: 'Forecast Calibration',
                        subtitle:
                            'Review forecast accuracy, bias and data quality.',
                        onTap: () => _open(ForecastCalibrationScreen(
                            initialHorizonDays: _days)))),
              ]),
              const SizedBox(height: 10),
              _actionCard(
                  icon: Icons.verified_outlined,
                  title: 'Release Readiness',
                  subtitle:
                      'Final testing gate and immutable release-candidate snapshots.',
                  onTap: () =>
                      _open(ReleaseReadinessScreen(initialHorizonDays: _days))),
              const SizedBox(height: 12),
              FarmCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Financial pulse',
                          style: TextStyle(
                              color: FarmColors.ink,
                              fontWeight: FontWeight.w900)),
                      const SizedBox(height: 10),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        _metric('Net revenue', formatJmd(s.netRevenue),
                            Icons.payments_outlined),
                        _metric('Contribution', formatJmd(s.contributionMargin),
                            Icons.insights_outlined,
                            note:
                                '${s.contributionMarginPercent.toStringAsFixed(1)}% margin'),
                        _metric(
                            'Finance health',
                            '${s.financeHealthScore.toStringAsFixed(0)}%',
                            Icons.verified_outlined,
                            note:
                                '${s.financeReconciliationPercent.toStringAsFixed(0)}% reconciled'),
                        _metric(
                            'Cash planning',
                            formatJmd(s.cashPlanningPosition),
                            Icons.account_balance_wallet_outlined),
                        _metric(
                            'Receivables',
                            formatJmd(s.openReceivableAmount),
                            Icons.receipt_long_outlined,
                            note:
                                '${formatJmd(s.overdueReceivableAmount)} overdue'),
                        _metric(
                            'Farmer payables',
                            formatJmd(s.openFarmerPayableAmount),
                            Icons.agriculture_outlined),
                      ]),
                    ]),
              ),
              const SizedBox(height: 12),
              FarmCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Supply & operations pulse',
                          style: TextStyle(
                              color: FarmColors.ink,
                              fontWeight: FontWeight.w900)),
                      const SizedBox(height: 10),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        _metric(
                            'Forecast demand',
                            s.forecastDemandQuantity.toStringAsFixed(1),
                            Icons.show_chart_rounded),
                        _metric(
                            'Trusted coverage',
                            '${supplyCoverage.toStringAsFixed(0)}%',
                            Icons.inventory_2_outlined,
                            note:
                                '${s.projectedSupplyGap.toStringAsFixed(1)} projected gap'),
                        _metric('Supply risks', '${s.supplyRiskProductCount}',
                            Icons.warning_amber_rounded,
                            note: '${s.criticalSupplyProductCount} critical'),
                        _metric(
                            'Inventory attention',
                            '${s.inventoryAttentionLotCount}',
                            Icons.warehouse_outlined,
                            note:
                                '${s.inventoryWasteQuantity.toStringAsFixed(1)} waste qty'),
                        _metric(
                            'Supplier watch/risk',
                            '${s.supplierWatchCount + s.supplierRiskCount}',
                            Icons.people_outline,
                            note: '${s.supplierRiskCount} risk'),
                        _metric(
                            'Commercial actions',
                            '${s.commercialAttentionCount}',
                            Icons.price_change_outlined),
                      ]),
                    ]),
              ),
              const SizedBox(height: 12),
              FarmCard(
                padding: const EdgeInsets.all(14),
                child: Row(children: [
                  const Icon(Icons.security_outlined,
                      color: FarmColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(
                          '${s.bankOpenTransactionCount} open bank transaction(s) • ${s.missingCostInvoiceCount} invoice(s) missing traceable procurement cost',
                          style: const TextStyle(
                              color: FarmColors.mutedText,
                              fontSize: 10.5,
                              height: 1.35,
                              fontWeight: FontWeight.w700))),
                ]),
              ),
            ],
          ),
        );
      },
    );
  }
}
