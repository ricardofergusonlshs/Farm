part of harvest_place_app;

// ================================================================
// THE HARVEST PLACE JA
// PHASE 5D — ADVANCED FORECASTING + FORECAST ACCURACY
// ================================================================

class AdvancedForecastSummary {
  final int horizonDays, historyDays, shortageProductCount, criticalProductCount, maturedSnapshotCount;
  final double projectedSalesRevenue, salesLowerBound, salesUpperBound, projectedContributionMargin, marginLowerBound, marginUpperBound;
  final double projectedNetCashPosition, cashLowerBound, cashUpperBound, forecastDemandQuantity, demandLowerBound, demandUpperBound;
  final double trustedSupplyQuantity, projectedProcurementQuantity, baseForecastConfidence, calibratedConfidence, revenueAccuracyPercent, forecastBandPercent;
  final String forecastSignal;
  const AdvancedForecastSummary({required this.horizonDays,required this.historyDays,required this.shortageProductCount,required this.criticalProductCount,required this.maturedSnapshotCount,required this.projectedSalesRevenue,required this.salesLowerBound,required this.salesUpperBound,required this.projectedContributionMargin,required this.marginLowerBound,required this.marginUpperBound,required this.projectedNetCashPosition,required this.cashLowerBound,required this.cashUpperBound,required this.forecastDemandQuantity,required this.demandLowerBound,required this.demandUpperBound,required this.trustedSupplyQuantity,required this.projectedProcurementQuantity,required this.baseForecastConfidence,required this.calibratedConfidence,required this.revenueAccuracyPercent,required this.forecastBandPercent,required this.forecastSignal});
  factory AdvancedForecastSummary.fromSupabase(Map<String,dynamic>d){double n(dynamic v)=>v is num?v.toDouble():double.tryParse('${v??''}')??0;int i(dynamic v)=>v is num?v.toInt():int.tryParse('${v??''}')??0;return AdvancedForecastSummary(horizonDays:i(d['horizon_days']),historyDays:i(d['history_days']),shortageProductCount:i(d['shortage_product_count']),criticalProductCount:i(d['critical_product_count']),maturedSnapshotCount:i(d['matured_snapshot_count']),projectedSalesRevenue:n(d['projected_sales_revenue']),salesLowerBound:n(d['sales_lower_bound']),salesUpperBound:n(d['sales_upper_bound']),projectedContributionMargin:n(d['projected_contribution_margin']),marginLowerBound:n(d['margin_lower_bound']),marginUpperBound:n(d['margin_upper_bound']),projectedNetCashPosition:n(d['projected_net_cash_position']),cashLowerBound:n(d['cash_lower_bound']),cashUpperBound:n(d['cash_upper_bound']),forecastDemandQuantity:n(d['forecast_demand_quantity']),demandLowerBound:n(d['demand_lower_bound']),demandUpperBound:n(d['demand_upper_bound']),trustedSupplyQuantity:n(d['trusted_supply_quantity']),projectedProcurementQuantity:n(d['projected_procurement_quantity']),baseForecastConfidence:n(d['base_forecast_confidence']),calibratedConfidence:n(d['calibrated_confidence']),revenueAccuracyPercent:n(d['revenue_accuracy_percent']),forecastBandPercent:n(d['forecast_band_percent']),forecastSignal:(d['forecast_signal']??'limited_history').toString());}
}

class AdvancedForecastProductRow {
  final String productName,unit,demandSignal,riskStatus,recommendedAction;
  final double demandConfidence,forecastDemand,demandLowerBound,demandUpperBound,trustedSupply,projectedGap,suggestedProcurementQuantity,averageUnitCost,projectedProcurementCost,averageSellingPrice,projectedSalesValue,projectedSalesLowerBound,projectedSalesUpperBound,observedMarginPercent;
  final DateTime? needByDate;
  const AdvancedForecastProductRow({required this.productName,required this.unit,required this.demandSignal,required this.riskStatus,required this.recommendedAction,required this.demandConfidence,required this.forecastDemand,required this.demandLowerBound,required this.demandUpperBound,required this.trustedSupply,required this.projectedGap,required this.suggestedProcurementQuantity,required this.averageUnitCost,required this.projectedProcurementCost,required this.averageSellingPrice,required this.projectedSalesValue,required this.projectedSalesLowerBound,required this.projectedSalesUpperBound,required this.observedMarginPercent,this.needByDate});
  factory AdvancedForecastProductRow.fromSupabase(Map<String,dynamic>d){double n(dynamic v)=>v is num?v.toDouble():double.tryParse('${v??''}')??0;return AdvancedForecastProductRow(productName:(d['product_name']??'Produce').toString(),unit:(d['unit']??'').toString(),demandSignal:(d['demand_signal']??'stable').toString(),riskStatus:(d['risk_status']??'covered').toString(),recommendedAction:(d['recommended_action']??'').toString(),demandConfidence:n(d['demand_confidence']),forecastDemand:n(d['forecast_demand']),demandLowerBound:n(d['demand_lower_bound']),demandUpperBound:n(d['demand_upper_bound']),trustedSupply:n(d['trusted_supply']),projectedGap:n(d['projected_gap']),suggestedProcurementQuantity:n(d['suggested_procurement_quantity']),averageUnitCost:n(d['average_unit_cost']),projectedProcurementCost:n(d['projected_procurement_cost']),averageSellingPrice:n(d['average_selling_price']),projectedSalesValue:n(d['projected_sales_value']),projectedSalesLowerBound:n(d['projected_sales_lower_bound']),projectedSalesUpperBound:n(d['projected_sales_upper_bound']),observedMarginPercent:n(d['observed_margin_percent']),needByDate:DateTime.tryParse('${d['need_by_date']??''}'));}
}

class ForecastAccuracyRow {
  final String snapshotNumber,forecastSignal,snapshotStatus,note;
  final DateTime? capturedAt,targetDate;
  final int horizonDays;
  final double projectedSalesRevenue,actualSalesRevenue,revenueVariance,revenueAccuracyPercent,salesLowerBound,salesUpperBound,calibratedConfidence;
  final bool withinSalesBand;
  const ForecastAccuracyRow({required this.snapshotNumber,required this.forecastSignal,required this.snapshotStatus,required this.note,this.capturedAt,this.targetDate,required this.horizonDays,required this.projectedSalesRevenue,required this.actualSalesRevenue,required this.revenueVariance,required this.revenueAccuracyPercent,required this.salesLowerBound,required this.salesUpperBound,required this.calibratedConfidence,required this.withinSalesBand});
  factory ForecastAccuracyRow.fromSupabase(Map<String,dynamic>d){double n(dynamic v)=>v is num?v.toDouble():double.tryParse('${v??''}')??0;int i(dynamic v)=>v is num?v.toInt():int.tryParse('${v??''}')??0;return ForecastAccuracyRow(snapshotNumber:(d['snapshot_number']??'Forecast').toString(),forecastSignal:(d['forecast_signal']??'').toString(),snapshotStatus:(d['snapshot_status']??'open').toString(),note:(d['note']??'').toString(),capturedAt:DateTime.tryParse('${d['captured_at']??''}'),targetDate:DateTime.tryParse('${d['target_date']??''}'),horizonDays:i(d['horizon_days']),projectedSalesRevenue:n(d['projected_sales_revenue']),actualSalesRevenue:n(d['actual_sales_revenue']),revenueVariance:n(d['revenue_variance']),revenueAccuracyPercent:n(d['revenue_accuracy_percent']),salesLowerBound:n(d['sales_lower_bound']),salesUpperBound:n(d['sales_upper_bound']),calibratedConfidence:n(d['calibrated_confidence']),withinSalesBand:d['within_sales_band']==true);}
}

Future<List<dynamic>> fetchAdvancedForecastBundle({required int horizonDays,required int historyDays}) async {
  await requireAdminAccess();
  final values=await Future.wait<dynamic>([
    supabase.rpc('admin_advanced_forecast_summary',params:{'p_horizon_days':horizonDays,'p_history_days':historyDays}),
    supabase.rpc('admin_advanced_forecast_products',params:{'p_horizon_days':horizonDays,'p_history_days':historyDays,'p_limit':120}),
    supabase.rpc('admin_list_advanced_forecast_accuracy',params:{'p_limit':25}),
  ]);
  dynamic first(dynamic raw)=>raw is List&&raw.isNotEmpty?raw.first:raw;
  final summary=AdvancedForecastSummary.fromSupabase(Map<String,dynamic>.from(first(values[0]) as Map));
  final products=(values[1] as List).map((e)=>AdvancedForecastProductRow.fromSupabase(Map<String,dynamic>.from(e as Map))).toList();
  final accuracy=(values[2] as List).map((e)=>ForecastAccuracyRow.fromSupabase(Map<String,dynamic>.from(e as Map))).toList();
  return [summary,products,accuracy];
}

class AdvancedForecastingScreen extends StatefulWidget {
  final int initialHorizonDays;
  const AdvancedForecastingScreen({super.key,this.initialHorizonDays=30});
  @override State<AdvancedForecastingScreen> createState()=>_AdvancedForecastingScreenState();
}

class _AdvancedForecastingScreenState extends State<AdvancedForecastingScreen> {
  late int _days;int _history=90;late Future<List<dynamic>> _future;bool _capturing=false;
  @override void initState(){super.initState();_days=widget.initialHorizonDays;_future=fetchAdvancedForecastBundle(horizonDays:_days,historyDays:_history);}
  Future<void> _refresh()async{final next=fetchAdvancedForecastBundle(horizonDays:_days,historyDays:_history);setState(()=>_future=next);await next;}
  void _reload(){setState(()=>_future=fetchAdvancedForecastBundle(horizonDays:_days,historyDays:_history));}
  Future<void> _capture()async{if(_capturing)return;setState(()=>_capturing=true);try{await requireAdminAccess();await supabase.rpc('admin_capture_advanced_forecast_snapshot',params:{'p_horizon_days':_days,'p_history_days':_history,'p_note':''});if(!mounted)return;ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Forecast snapshot captured.')));await _refresh();}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(friendlyAppError(e))));}finally{if(mounted)setState(()=>_capturing=false);}}
  Widget _metric(String label,String value,IconData icon,{String? note})=>Container(width:150,padding:const EdgeInsets.all(11),decoration:BoxDecoration(color:FarmColors.cardSoft,borderRadius:BorderRadius.circular(13),border:Border.all(color:FarmColors.line)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(icon,size:17,color:FarmColors.primary),const SizedBox(height:5),Text(value,style:const TextStyle(color:FarmColors.ink,fontWeight:FontWeight.w900,fontSize:13)),Text(label,style:const TextStyle(color:FarmColors.mutedText,fontSize:9,fontWeight:FontWeight.w700)),if(note!=null)...[const SizedBox(height:3),Text(note,style:const TextStyle(color:FarmColors.mutedText,fontSize:8.5,height:1.2))]]));
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: AppBar(title: const Text('Advanced Forecast')),
      body: FutureBuilder<List<dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError && snapshot.data == null) {
            return Center(child: Text(friendlyAppError(snapshot.error!)));
          }
          final data = snapshot.data ?? const <dynamic>[];
          if (data.length < 3) return const SizedBox.shrink();
          final s = data[0] as AdvancedForecastSummary;
          final products = data[1] as List<AdvancedForecastProductRow>;
          final history = data[2] as List<ForecastAccuracyRow>;

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
                      const Row(
                        children: [
                          Icon(Icons.show_chart_rounded, color: FarmColors.primary, size: 28),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Advanced Forecasting',
                              style: TextStyle(color: FarmColors.ink, fontSize: 17, fontWeight: FontWeight.w900),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Planning ranges combine HPJ forecast confidence with actual accuracy from matured forecast snapshots. Bounds are uncertainty ranges, not guarantees.',
                        style: TextStyle(color: FarmColors.mutedText, fontSize: 10.5, height: 1.35, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [7, 30, 60, 90]
                            .map((d) => ChoiceChip(
                                  label: Text('$d days'),
                                  selected: _days == d,
                                  onSelected: (_) {
                                    _days = d;
                                    _reload();
                                  },
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [90, 180, 365]
                            .map((d) => ChoiceChip(
                                  label: Text('$d-day history'),
                                  selected: _history == d,
                                  onSelected: (_) {
                                    _history = d;
                                    _reload();
                                  },
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: _capturing ? null : _capture,
                        icon: _capturing
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.camera_alt_outlined, size: 17),
                        label: const Text('Capture Forecast Snapshot'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                FarmCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Forecast range', style: TextStyle(color: FarmColors.ink, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _metric('Projected sales', formatJmd(s.projectedSalesRevenue), Icons.payments_outlined,
                              note: '${formatJmd(s.salesLowerBound)} – ${formatJmd(s.salesUpperBound)}'),
                          _metric('Contribution', formatJmd(s.projectedContributionMargin), Icons.insights_outlined,
                              note: '${formatJmd(s.marginLowerBound)} – ${formatJmd(s.marginUpperBound)}'),
                          _metric('Cash position', formatJmd(s.projectedNetCashPosition), Icons.account_balance_wallet_outlined,
                              note: '${formatJmd(s.cashLowerBound)} – ${formatJmd(s.cashUpperBound)}'),
                          _metric('Demand', s.forecastDemandQuantity.toStringAsFixed(1), Icons.inventory_2_outlined,
                              note: '${s.demandLowerBound.toStringAsFixed(1)} – ${s.demandUpperBound.toStringAsFixed(1)}'),
                          _metric('Confidence', '${s.calibratedConfidence.toStringAsFixed(0)}%', Icons.verified_outlined,
                              note: '±${s.forecastBandPercent.toStringAsFixed(1)}% band'),
                          _metric('Accuracy history', s.maturedSnapshotCount == 0 ? 'Building' : '${s.revenueAccuracyPercent.toStringAsFixed(0)}%', Icons.fact_check_outlined,
                              note: '${s.maturedSnapshotCount} matured snapshot(s)'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                FarmCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Product outlook • ${products.length}', style: const TextStyle(color: FarmColors.ink, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 9),
                      if (products.isEmpty)
                        const Text('No product forecast rows yet.', style: TextStyle(color: FarmColors.mutedText))
                      else
                        ...products.take(40).map(
                          (p) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(11),
                            decoration: BoxDecoration(
                              color: FarmColors.cardSoft,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: FarmColors.line),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: Text('${p.productName} • ${p.unit}', style: const TextStyle(color: FarmColors.ink, fontWeight: FontWeight.w900))),
                                    Text('${p.demandConfidence.toStringAsFixed(0)}%', style: const TextStyle(color: FarmColors.primary, fontSize: 9, fontWeight: FontWeight.w900)),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  'Demand ${p.forecastDemand.toStringAsFixed(1)} (${p.demandLowerBound.toStringAsFixed(1)}–${p.demandUpperBound.toStringAsFixed(1)}) • trusted ${p.trustedSupply.toStringAsFixed(1)} • gap ${p.projectedGap.toStringAsFixed(1)}',
                                  style: const TextStyle(color: FarmColors.mutedText, fontSize: 9.5, height: 1.3),
                                ),
                                Text(
                                  'Projected sales ${formatJmd(p.projectedSalesValue)} • ${formatJmd(p.projectedSalesLowerBound)}–${formatJmd(p.projectedSalesUpperBound)}',
                                  style: const TextStyle(color: FarmColors.mutedText, fontSize: 9.5, height: 1.3),
                                ),
                                if (p.recommendedAction.isNotEmpty)
                                  Text(p.recommendedAction, style: const TextStyle(color: FarmColors.ink, fontSize: 9.5, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                FarmCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Forecast accuracy history', style: TextStyle(color: FarmColors.ink, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 8),
                      if (history.isEmpty)
                        const Text('Capture forecasts now so HPJ can score them after their target dates.', style: TextStyle(color: FarmColors.mutedText, fontSize: 10))
                      else
                        ...history.take(12).map(
                          (a) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  a.snapshotStatus == 'matured'
                                      ? (a.withinSalesBand ? Icons.check_circle_outline : Icons.info_outline)
                                      : Icons.schedule_outlined,
                                  size: 18,
                                  color: a.withinSalesBand ? FarmColors.success : FarmColors.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(a.snapshotNumber, style: const TextStyle(color: FarmColors.ink, fontWeight: FontWeight.w800)),
                                      Text(
                                        a.snapshotStatus == 'matured'
                                            ? 'Forecast ${formatJmd(a.projectedSalesRevenue)} • Actual ${formatJmd(a.actualSalesRevenue)} • ${a.revenueAccuracyPercent.toStringAsFixed(0)}% accurate'
                                            : 'Open ${a.horizonDays}-day forecast • ${formatJmd(a.projectedSalesRevenue)} projected',
                                        style: const TextStyle(color: FarmColors.mutedText, fontSize: 9.5, height: 1.3),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
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
