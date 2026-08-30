part of harvest_place_app;

// ================================================================
// THE HARVEST PLACE JA
// PHASE 5B — BUSINESS FORECASTING
// ================================================================

class BusinessForecastSummary {
  final int horizonDays;
  final int historyDays;
  final int historicalInvoiceCount;
  final double historicalNetRevenue;
  final double historicalContributionMargin;
  final double historicalMarginPercent;
  final double revenueTrendFactor;
  final double projectedSalesRevenue;
  final double projectedContributionMargin;
  final double estimatedCollectionRate;
  final double expectedReceivablesInflow;
  final double expectedNewSalesCashIn;
  final double projectedCustomerCashIn;
  final double existingFarmerPayables;
  final double projectedProcurementSpend;
  final double refundExposure;
  final double projectedCashOutflow;
  final double projectedNetCashPosition;
  final double forecastDemandQuantity;
  final double trustedSupplyQuantity;
  final double projectedProcurementQuantity;
  final int shortageProductCount;
  final int criticalProductCount;
  final double forecastConfidence;
  final String forecastSignal;

  const BusinessForecastSummary({
    required this.horizonDays, required this.historyDays, required this.historicalInvoiceCount,
    required this.historicalNetRevenue, required this.historicalContributionMargin, required this.historicalMarginPercent,
    required this.revenueTrendFactor, required this.projectedSalesRevenue, required this.projectedContributionMargin,
    required this.estimatedCollectionRate, required this.expectedReceivablesInflow, required this.expectedNewSalesCashIn,
    required this.projectedCustomerCashIn, required this.existingFarmerPayables, required this.projectedProcurementSpend,
    required this.refundExposure, required this.projectedCashOutflow, required this.projectedNetCashPosition,
    required this.forecastDemandQuantity, required this.trustedSupplyQuantity, required this.projectedProcurementQuantity,
    required this.shortageProductCount, required this.criticalProductCount, required this.forecastConfidence,
    required this.forecastSignal,
  });

  factory BusinessForecastSummary.fromSupabase(Map<String, dynamic> d) {
    double n(dynamic v) => v is num ? v.toDouble() : double.tryParse('${v ?? ''}') ?? 0;
    int i(dynamic v) => v is num ? v.toInt() : int.tryParse('${v ?? ''}') ?? 0;
    return BusinessForecastSummary(
      horizonDays: i(d['horizon_days']), historyDays: i(d['history_days']), historicalInvoiceCount: i(d['historical_invoice_count']),
      historicalNetRevenue: n(d['historical_net_revenue']), historicalContributionMargin: n(d['historical_contribution_margin']),
      historicalMarginPercent: n(d['historical_margin_percent']), revenueTrendFactor: n(d['revenue_trend_factor']),
      projectedSalesRevenue: n(d['projected_sales_revenue']), projectedContributionMargin: n(d['projected_contribution_margin']),
      estimatedCollectionRate: n(d['estimated_collection_rate']), expectedReceivablesInflow: n(d['expected_receivables_inflow']),
      expectedNewSalesCashIn: n(d['expected_new_sales_cash_in']), projectedCustomerCashIn: n(d['projected_customer_cash_in']),
      existingFarmerPayables: n(d['existing_farmer_payables']), projectedProcurementSpend: n(d['projected_procurement_spend']),
      refundExposure: n(d['refund_exposure']), projectedCashOutflow: n(d['projected_cash_outflow']),
      projectedNetCashPosition: n(d['projected_net_cash_position']), forecastDemandQuantity: n(d['forecast_demand_quantity']),
      trustedSupplyQuantity: n(d['trusted_supply_quantity']), projectedProcurementQuantity: n(d['projected_procurement_quantity']),
      shortageProductCount: i(d['shortage_product_count']), criticalProductCount: i(d['critical_product_count']),
      forecastConfidence: n(d['forecast_confidence']), forecastSignal: (d['forecast_signal'] ?? 'steady').toString(),
    );
  }
}

class BusinessForecastProduct {
  final String productName;
  final String unit;
  final String demandSignal;
  final double forecastDemand;
  final double trustedSupply;
  final double projectedGap;
  final double suggestedProcurementQuantity;
  final double averageUnitCost;
  final double projectedProcurementCost;
  final double averageSellingPrice;
  final double projectedSalesValue;
  final double observedMarginPercent;
  final String riskStatus;
  final DateTime? needByDate;
  final String recommendedAction;
  const BusinessForecastProduct({required this.productName,required this.unit,required this.demandSignal,required this.forecastDemand,required this.trustedSupply,required this.projectedGap,required this.suggestedProcurementQuantity,required this.averageUnitCost,required this.projectedProcurementCost,required this.averageSellingPrice,required this.projectedSalesValue,required this.observedMarginPercent,required this.riskStatus,this.needByDate,required this.recommendedAction});
  factory BusinessForecastProduct.fromSupabase(Map<String,dynamic> d) {
    double n(dynamic v)=>v is num?v.toDouble():double.tryParse('${v??''}')??0;
    return BusinessForecastProduct(
      productName:(d['product_name']??'Produce').toString(),unit:(d['unit']??'unit').toString(),demandSignal:(d['demand_signal']??'stable').toString(),
      forecastDemand:n(d['forecast_demand']),trustedSupply:n(d['trusted_supply']),projectedGap:n(d['projected_gap']),suggestedProcurementQuantity:n(d['suggested_procurement_quantity']),
      averageUnitCost:n(d['average_unit_cost']),projectedProcurementCost:n(d['projected_procurement_cost']),averageSellingPrice:n(d['average_selling_price']),projectedSalesValue:n(d['projected_sales_value']),observedMarginPercent:n(d['observed_margin_percent']),
      riskStatus:(d['risk_status']??'covered').toString(),needByDate:DateTime.tryParse('${d['need_by_date']??''}'),recommendedAction:(d['recommended_action']??'').toString(),
    );
  }
}

class BusinessCustomerTrend {
  final String businessName;
  final double currentRevenue;
  final double previousRevenue;
  final double revenueChangePercent;
  final double contributionMargin;
  final double marginPercent;
  final int invoiceCount;
  final String trendSignal;
  const BusinessCustomerTrend({required this.businessName,required this.currentRevenue,required this.previousRevenue,required this.revenueChangePercent,required this.contributionMargin,required this.marginPercent,required this.invoiceCount,required this.trendSignal});
  factory BusinessCustomerTrend.fromSupabase(Map<String,dynamic> d) {
    double n(dynamic v)=>v is num?v.toDouble():double.tryParse('${v??''}')??0;
    int i(dynamic v)=>v is num?v.toInt():int.tryParse('${v??''}')??0;
    return BusinessCustomerTrend(businessName:(d['business_name']??'Wholesale business').toString(),currentRevenue:n(d['current_net_revenue']),previousRevenue:n(d['previous_net_revenue']),revenueChangePercent:n(d['revenue_change_percent']),contributionMargin:n(d['contribution_margin']),marginPercent:n(d['contribution_margin_percent']),invoiceCount:i(d['invoice_count']),trendSignal:(d['trend_signal']??'steady').toString());
  }
}

Future<List<dynamic>> fetchBusinessForecastBundle({required int horizonDays,int historyDays=90}) async {
  await requireAdminAccess();
  final values = await Future.wait<dynamic>([
    supabase.rpc('admin_business_forecast_summary', params:{'p_horizon_days':horizonDays,'p_history_days':historyDays}),
    supabase.rpc('admin_business_forecast_products', params:{'p_horizon_days':horizonDays,'p_history_days':historyDays,'p_limit':100}),
    supabase.rpc('admin_business_customer_trends', params:{'p_days':horizonDays,'p_limit':60}),
  ]);
  dynamic first(dynamic raw) => raw is List && raw.isNotEmpty ? raw.first : raw;
  final summary = BusinessForecastSummary.fromSupabase(Map<String,dynamic>.from(first(values[0]) as Map));
  final products = (values[1] as List).map((e)=>BusinessForecastProduct.fromSupabase(Map<String,dynamic>.from(e as Map))).toList();
  final customers = (values[2] as List).map((e)=>BusinessCustomerTrend.fromSupabase(Map<String,dynamic>.from(e as Map))).toList();
  return [summary,products,customers];
}

class BusinessForecastingScreen extends StatefulWidget {
  final int initialHorizonDays;
  const BusinessForecastingScreen({super.key,this.initialHorizonDays=30});
  @override
  State<BusinessForecastingScreen> createState()=>_BusinessForecastingScreenState();
}

class _BusinessForecastingScreenState extends State<BusinessForecastingScreen> {
  late int _days;
  late Future<List<dynamic>> _future;
  @override
  void initState(){super.initState();_days=widget.initialHorizonDays;_future=fetchBusinessForecastBundle(horizonDays:_days);}
  Future<void> _refresh() async {final next=fetchBusinessForecastBundle(horizonDays:_days);setState(()=>_future=next);await next;}
  void _setDays(int v){if(v==_days)return;setState((){_days=v;_future=fetchBusinessForecastBundle(horizonDays:_days);});}

  Widget _money(String label,double value,{String? note})=>Container(
    width:155,padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:FarmColors.cardSoft,borderRadius:BorderRadius.circular(14),border:Border.all(color:FarmColors.line)),
    child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(formatJmd(value),style:const TextStyle(color:FarmColors.ink,fontSize:14,fontWeight:FontWeight.w900)),Text(label,style:const TextStyle(color:FarmColors.mutedText,fontSize:9.5,fontWeight:FontWeight.w700)),if(note!=null)...[const SizedBox(height:4),Text(note,style:const TextStyle(color:FarmColors.mutedText,fontSize:8.5,height:1.25))]]),
  );

  @override
  Widget build(BuildContext context){
    return Scaffold(
      backgroundColor:FarmColors.background,
      appBar:AppBar(title:const Text('Business Forecast')),
      body:FutureBuilder<List<dynamic>>(future:_future,builder:(context,snapshot){
        if(snapshot.connectionState==ConnectionState.waiting&&snapshot.data==null)return const Center(child:CircularProgressIndicator());
        if(snapshot.hasError&&snapshot.data==null)return Center(child:Text(friendlyAppError(snapshot.error!)));
        final data=snapshot.data??const<dynamic>[];if(data.length<3)return const SizedBox.shrink();
        final s=data[0] as BusinessForecastSummary;final products=data[1] as List<BusinessForecastProduct>;final customers=data[2] as List<BusinessCustomerTrend>;
        return RefreshIndicator(onRefresh:_refresh,child:ListView(physics:const AlwaysScrollableScrollPhysics(),padding:const EdgeInsets.fromLTRB(16,16,16,110),children:[
          FarmCard(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            const Row(children:[Icon(Icons.trending_up_outlined,color:FarmColors.primary,size:28),SizedBox(width:10),Expanded(child:Text('Forward Business Outlook',style:TextStyle(color:FarmColors.ink,fontSize:17,fontWeight:FontWeight.w900)))]),
            const SizedBox(height:6),const Text('Rules-based planning estimate from HPJ sales history, receivables, demand, trusted supply and recorded farmer costs. It is not a guaranteed sales forecast or bank balance.',style:TextStyle(color:FarmColors.mutedText,fontSize:10.5,height:1.35,fontWeight:FontWeight.w600)),
            const SizedBox(height:12),Wrap(spacing:8,runSpacing:8,children:[7,30,60,90].map((d)=>ChoiceChip(label:Text('$d days'),selected:_days==d,onSelected:(_)=>_setDays(d))).toList()),
            const SizedBox(height:10),Text('Confidence ${s.forecastConfidence.toStringAsFixed(0)}% • ${s.forecastSignal.replaceAll('_',' ')}',style:const TextStyle(color:FarmColors.primary,fontWeight:FontWeight.w900,fontSize:10.5)),
          ])),
          const SizedBox(height:12),
          FarmCard(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            const Text('Projected commercial picture',style:TextStyle(color:FarmColors.ink,fontWeight:FontWeight.w900)),const SizedBox(height:10),
            Wrap(spacing:8,runSpacing:8,children:[
              _money('Projected sales',s.projectedSalesRevenue,note:'Trend factor ${s.revenueTrendFactor.toStringAsFixed(2)}×'),
              _money('Projected contribution',s.projectedContributionMargin,note:'Historical margin ${s.historicalMarginPercent.toStringAsFixed(1)}%'),
              _money('Customer cash in',s.projectedCustomerCashIn,note:'${(s.estimatedCollectionRate*100).toStringAsFixed(0)}% estimated collection'),
              _money('Projected cash out',s.projectedCashOutflow,note:'Payables + procurement + refund exposure'),
              _money('Projected net position',s.projectedNetCashPosition),
              _money('Procurement spend',s.projectedProcurementSpend,note:'${s.projectedProcurementQuantity.toStringAsFixed(1)} planned qty'),
            ]),
          ])),
          const SizedBox(height:12),
          FarmCard(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Row(children:[const Expanded(child:Text('Product outlook',style:TextStyle(color:FarmColors.ink,fontWeight:FontWeight.w900))),Text('${s.shortageProductCount} shortage • ${s.criticalProductCount} critical',style:const TextStyle(color:FarmColors.mutedText,fontSize:9.5,fontWeight:FontWeight.w700))]),
            const SizedBox(height:8),
            if(products.isEmpty)const Text('No product forecast rows yet.',style:TextStyle(color:FarmColors.mutedText)) else ...products.take(20).map((p)=>Padding(padding:const EdgeInsets.only(bottom:8),child:Container(padding:const EdgeInsets.all(11),decoration:BoxDecoration(color:FarmColors.cardSoft,borderRadius:BorderRadius.circular(13),border:Border.all(color:FarmColors.line)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Row(children:[Expanded(child:Text('${p.productName} • ${p.unit}',style:const TextStyle(color:FarmColors.ink,fontWeight:FontWeight.w900))),Text(p.riskStatus.toUpperCase(),style:TextStyle(color:p.riskStatus=='critical'?FarmColors.danger:p.riskStatus=='shortage'?FarmColors.warning:FarmColors.primary,fontSize:9,fontWeight:FontWeight.w900))]),
              const SizedBox(height:5),Text('Demand ${p.forecastDemand.toStringAsFixed(1)} • Trusted ${p.trustedSupply.toStringAsFixed(1)} • Gap ${p.projectedGap.toStringAsFixed(1)}',style:const TextStyle(color:FarmColors.mutedText,fontSize:10,fontWeight:FontWeight.w700)),
              const SizedBox(height:3),Text('Projected procurement ${formatJmd(p.projectedProcurementCost)} • projected sales value ${formatJmd(p.projectedSalesValue)}',style:const TextStyle(color:FarmColors.mutedText,fontSize:9.5)),
              if(p.recommendedAction.isNotEmpty)...[const SizedBox(height:4),Text(p.recommendedAction,style:const TextStyle(color:FarmColors.ink,fontSize:9.5,height:1.3))],
            ])))) ,
          ])),
          const SizedBox(height:12),
          FarmCard(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            const Text('Wholesale customer trend',style:TextStyle(color:FarmColors.ink,fontWeight:FontWeight.w900)),const SizedBox(height:8),
            if(customers.isEmpty)const Text('No customer trend history yet.',style:TextStyle(color:FarmColors.mutedText)) else ...customers.take(15).map((c)=>Padding(padding:const EdgeInsets.only(bottom:7),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[
              const Icon(Icons.business_outlined,size:17,color:FarmColors.primary),const SizedBox(width:8),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(c.businessName,style:const TextStyle(color:FarmColors.ink,fontWeight:FontWeight.w900,fontSize:10.5)),Text('${formatJmd(c.currentRevenue)} • ${c.revenueChangePercent>=0?'+':''}${c.revenueChangePercent.toStringAsFixed(1)}% vs prior period • margin ${c.marginPercent.toStringAsFixed(1)}%',style:const TextStyle(color:FarmColors.mutedText,fontSize:9.5,height:1.3))])),Text(c.trendSignal.replaceAll('_',' '),style:const TextStyle(color:FarmColors.mutedText,fontSize:9,fontWeight:FontWeight.w800))
            ]))),
          ])),
        ]));
      }),
    );
  }
}
