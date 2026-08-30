part of harvest_place_app;

// ================================================================
// THE HARVEST PLACE JA
// PHASE 5E — SCENARIO PLANNING
// ================================================================

class BusinessScenarioPreview {
  final int horizonDays;final String scenarioSignal;
  final double baselineSalesRevenue,scenarioSalesRevenue,salesDelta,baselineContributionMargin,scenarioContributionMargin,scenarioMarginPercent,contributionDelta,baselineNetCashPosition,scenarioNetCashPosition,cashDelta,baselineForecastDemand,scenarioForecastDemand,baselineTrustedSupply,scenarioTrustedSupply,baselineProcurementQuantity,scenarioProcurementQuantity,baselineCollectionRate,scenarioCollectionRate,scenarioProcurementSpend,scenarioDeliveryCost;
  const BusinessScenarioPreview({required this.horizonDays,required this.scenarioSignal,required this.baselineSalesRevenue,required this.scenarioSalesRevenue,required this.salesDelta,required this.baselineContributionMargin,required this.scenarioContributionMargin,required this.scenarioMarginPercent,required this.contributionDelta,required this.baselineNetCashPosition,required this.scenarioNetCashPosition,required this.cashDelta,required this.baselineForecastDemand,required this.scenarioForecastDemand,required this.baselineTrustedSupply,required this.scenarioTrustedSupply,required this.baselineProcurementQuantity,required this.scenarioProcurementQuantity,required this.baselineCollectionRate,required this.scenarioCollectionRate,required this.scenarioProcurementSpend,required this.scenarioDeliveryCost});
  factory BusinessScenarioPreview.fromSupabase(Map<String,dynamic>d){double n(dynamic v)=>v is num?v.toDouble():double.tryParse('${v??''}')??0;int i(dynamic v)=>v is num?v.toInt():int.tryParse('${v??''}')??0;return BusinessScenarioPreview(horizonDays:i(d['horizon_days']),scenarioSignal:(d['scenario_signal']??'balanced').toString(),baselineSalesRevenue:n(d['baseline_sales_revenue']),scenarioSalesRevenue:n(d['scenario_sales_revenue']),salesDelta:n(d['sales_delta']),baselineContributionMargin:n(d['baseline_contribution_margin']),scenarioContributionMargin:n(d['scenario_contribution_margin']),scenarioMarginPercent:n(d['scenario_margin_percent']),contributionDelta:n(d['contribution_delta']),baselineNetCashPosition:n(d['baseline_net_cash_position']),scenarioNetCashPosition:n(d['scenario_net_cash_position']),cashDelta:n(d['cash_delta']),baselineForecastDemand:n(d['baseline_forecast_demand']),scenarioForecastDemand:n(d['scenario_forecast_demand']),baselineTrustedSupply:n(d['baseline_trusted_supply']),scenarioTrustedSupply:n(d['scenario_trusted_supply']),baselineProcurementQuantity:n(d['baseline_procurement_quantity']),scenarioProcurementQuantity:n(d['scenario_procurement_quantity']),baselineCollectionRate:n(d['baseline_collection_rate']),scenarioCollectionRate:n(d['scenario_collection_rate']),scenarioProcurementSpend:n(d['scenario_procurement_spend']),scenarioDeliveryCost:n(d['scenario_delivery_cost']));}
}

class SavedBusinessScenario {
  final String scenarioNumber,scenarioName,scenarioSignal,note;final int horizonDays;final double salesChangePercent,supplyChangePercent,scenarioSalesRevenue,scenarioContributionMargin,scenarioMarginPercent,scenarioNetCashPosition,scenarioProcurementQuantity;final DateTime? createdAt;
  const SavedBusinessScenario({required this.scenarioNumber,required this.scenarioName,required this.scenarioSignal,required this.note,required this.horizonDays,required this.salesChangePercent,required this.supplyChangePercent,required this.scenarioSalesRevenue,required this.scenarioContributionMargin,required this.scenarioMarginPercent,required this.scenarioNetCashPosition,required this.scenarioProcurementQuantity,this.createdAt});
  factory SavedBusinessScenario.fromSupabase(Map<String,dynamic>d){double n(dynamic v)=>v is num?v.toDouble():double.tryParse('${v??''}')??0;int i(dynamic v)=>v is num?v.toInt():int.tryParse('${v??''}')??0;return SavedBusinessScenario(scenarioNumber:(d['scenario_number']??'').toString(),scenarioName:(d['scenario_name']??'Scenario').toString(),scenarioSignal:(d['scenario_signal']??'balanced').toString(),note:(d['note']??'').toString(),horizonDays:i(d['horizon_days']),salesChangePercent:n(d['sales_change_percent']),supplyChangePercent:n(d['supply_change_percent']),scenarioSalesRevenue:n(d['scenario_sales_revenue']),scenarioContributionMargin:n(d['scenario_contribution_margin']),scenarioMarginPercent:n(d['scenario_margin_percent']),scenarioNetCashPosition:n(d['scenario_net_cash_position']),scenarioProcurementQuantity:n(d['scenario_procurement_quantity']),createdAt:DateTime.tryParse('${d['created_at']??''}'));}
}

class ProductPriceScenarioPreview {
  final String productName,unit,pricingStatus,scenarioNote;final double currentAveragePrice,scenarioPrice,priceChangePercent,forecastDemand,projectedSalesBefore,projectedSalesAfter,landedCostPerUnit,observedMarginPercent,scenarioMarginPercent,projectedContributionBefore,projectedContributionAfter,contributionDelta;
  const ProductPriceScenarioPreview({required this.productName,required this.unit,required this.pricingStatus,required this.scenarioNote,required this.currentAveragePrice,required this.scenarioPrice,required this.priceChangePercent,required this.forecastDemand,required this.projectedSalesBefore,required this.projectedSalesAfter,required this.landedCostPerUnit,required this.observedMarginPercent,required this.scenarioMarginPercent,required this.projectedContributionBefore,required this.projectedContributionAfter,required this.contributionDelta});
  factory ProductPriceScenarioPreview.fromSupabase(Map<String,dynamic>d){double n(dynamic v)=>v is num?v.toDouble():double.tryParse('${v??''}')??0;return ProductPriceScenarioPreview(productName:(d['product_name']??'').toString(),unit:(d['unit']??'').toString(),pricingStatus:(d['pricing_status']??'').toString(),scenarioNote:(d['scenario_note']??'').toString(),currentAveragePrice:n(d['current_average_price']),scenarioPrice:n(d['scenario_price']),priceChangePercent:n(d['price_change_percent']),forecastDemand:n(d['forecast_demand']),projectedSalesBefore:n(d['projected_sales_before']),projectedSalesAfter:n(d['projected_sales_after']),landedCostPerUnit:n(d['landed_cost_per_unit']),observedMarginPercent:n(d['observed_margin_percent']),scenarioMarginPercent:n(d['scenario_margin_percent']),projectedContributionBefore:n(d['projected_contribution_before']),projectedContributionAfter:n(d['projected_contribution_after']),contributionDelta:n(d['contribution_delta']));}
}

class ScenarioPlanningScreen extends StatefulWidget {final int initialHorizonDays;const ScenarioPlanningScreen({super.key,this.initialHorizonDays=30});@override State<ScenarioPlanningScreen> createState()=>_ScenarioPlanningScreenState();}
class _ScenarioPlanningScreenState extends State<ScenarioPlanningScreen>{
  late int _days;double _sales=0,_supply=0,_procCost=0,_delivery=0,_collection=0;BusinessScenarioPreview? _preview;ProductPriceScenarioPreview? _productPreview;bool _loading=false,_saving=false,_productLoading=false;List<SavedBusinessScenario> _saved=[];
  final _name=TextEditingController(text:'Planning scenario');final _product=TextEditingController();final _unit=TextEditingController();final _priceChange=TextEditingController(text:'10');
  @override void initState(){super.initState();_days=widget.initialHorizonDays;_runPreview();}
  @override void dispose(){_name.dispose();_product.dispose();_unit.dispose();_priceChange.dispose();super.dispose();}
  dynamic _first(dynamic raw)=>raw is List&&raw.isNotEmpty?raw.first:raw;
  Future<void> _loadSaved()async{final raw=await supabase.rpc('admin_list_business_scenarios',params:{'p_limit':20});if(!mounted)return;setState(()=>_saved=(raw as List).map((e)=>SavedBusinessScenario.fromSupabase(Map<String,dynamic>.from(e as Map))).toList());}
  Future<void> _runPreview()async{setState(()=>_loading=true);try{await requireAdminAccess();final raw=await supabase.rpc('admin_preview_business_scenario',params:{'p_horizon_days':_days,'p_sales_change_percent':_sales,'p_supply_change_percent':_supply,'p_procurement_cost_change_percent':_procCost,'p_delivery_cost_change_percent':_delivery,'p_collection_rate_change_points':_collection});final p=BusinessScenarioPreview.fromSupabase(Map<String,dynamic>.from(_first(raw) as Map));if(!mounted)return;setState(()=>_preview=p);await _loadSaved();}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(friendlyAppError(e))));}finally{if(mounted)setState(()=>_loading=false);}}
  Future<void> _save()async{if(_saving)return;setState(()=>_saving=true);try{await requireAdminAccess();await supabase.rpc('admin_save_business_scenario',params:{'p_scenario_name':_name.text.trim(),'p_horizon_days':_days,'p_sales_change_percent':_sales,'p_supply_change_percent':_supply,'p_procurement_cost_change_percent':_procCost,'p_delivery_cost_change_percent':_delivery,'p_collection_rate_change_points':_collection,'p_note':''});if(!mounted)return;ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Scenario saved.')));await _loadSaved();}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(friendlyAppError(e))));}finally{if(mounted)setState(()=>_saving=false);}}
  Future<void> _previewProduct()async{setState(()=>_productLoading=true);try{await requireAdminAccess();final raw=await supabase.rpc('admin_preview_product_price_scenario',params:{'p_product_name':_product.text.trim(),'p_unit':_unit.text.trim(),'p_price_change_percent':double.tryParse(_priceChange.text.trim())??0,'p_horizon_days':_days,'p_history_days':90});final p=ProductPriceScenarioPreview.fromSupabase(Map<String,dynamic>.from(_first(raw) as Map));if(!mounted)return;setState(()=>_productPreview=p);}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(friendlyAppError(e))));}finally{if(mounted)setState(()=>_productLoading=false);}}
  Widget _slider(String label,double value,double min,double max,ValueChanged<double> onChanged,{String suffix='%'})=>Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Expanded(child:Text(label,style:const TextStyle(color:FarmColors.ink,fontWeight:FontWeight.w800,fontSize:10.5))),Text('${value>=0?'+':''}${value.toStringAsFixed(0)}$suffix',style:const TextStyle(color:FarmColors.primary,fontWeight:FontWeight.w900,fontSize:10))]),Slider(value:value,min:min,max:max,divisions:((max-min)/5).round(),label:value.toStringAsFixed(0),onChanged:onChanged)]);
  Widget _metric(String label,String value,{String? delta})=>Container(width:150,padding:const EdgeInsets.all(11),decoration:BoxDecoration(color:FarmColors.cardSoft,borderRadius:BorderRadius.circular(13),border:Border.all(color:FarmColors.line)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(value,style:const TextStyle(color:FarmColors.ink,fontWeight:FontWeight.w900,fontSize:13)),Text(label,style:const TextStyle(color:FarmColors.mutedText,fontSize:9,fontWeight:FontWeight.w700)),if(delta!=null)Text(delta,style:const TextStyle(color:FarmColors.primary,fontSize:8.5,fontWeight:FontWeight.w800))]));
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: AppBar(title: const Text('Scenario Planner')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
        children: [
          FarmCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.science_outlined, color: FarmColors.primary, size: 28),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Business What-If Planner',
                        style: TextStyle(color: FarmColors.ink, fontSize: 17, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Change assumptions without changing live HPJ prices, supply, invoices or payouts. Scenario results are planning estimates.',
                  style: TextStyle(color: FarmColors.mutedText, fontSize: 10.5, height: 1.35, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [7, 30, 60, 90]
                      .map((d) => ChoiceChip(
                            label: Text('$d days'),
                            selected: _days == d,
                            onSelected: (_) => setState(() => _days = d),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Scenario name', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),
                _slider('Sales / demand change', _sales, -50, 100, (v) => setState(() => _sales = v)),
                _slider('Trusted supply change', _supply, -100, 100, (v) => setState(() => _supply = v)),
                _slider('Procurement cost change', _procCost, -50, 100, (v) => setState(() => _procCost = v)),
                _slider('Delivery cost change', _delivery, -50, 100, (v) => setState(() => _delivery = v)),
                _slider('Collection rate change', _collection, -50, 50, (v) => setState(() => _collection = v), suffix: ' pts'),
                Wrap(
                  spacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _loading ? null : _runPreview,
                      icon: _loading
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.play_arrow, size: 18),
                      label: const Text('Run Scenario'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _preview == null || _saving ? null : _save,
                      icon: const Icon(Icons.save_outlined, size: 17),
                      label: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_preview != null) ...[
            const SizedBox(height: 12),
            FarmCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Scenario result • ${_preview!.scenarioSignal.replaceAll('_', ' ')}',
                    style: const TextStyle(color: FarmColors.ink, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _metric('Sales', formatJmd(_preview!.scenarioSalesRevenue), delta: 'Δ ${formatJmd(_preview!.salesDelta)}'),
                      _metric('Contribution', formatJmd(_preview!.scenarioContributionMargin), delta: '${_preview!.scenarioMarginPercent.toStringAsFixed(1)}% margin'),
                      _metric('Cash position', formatJmd(_preview!.scenarioNetCashPosition), delta: 'Δ ${formatJmd(_preview!.cashDelta)}'),
                      _metric('Demand', _preview!.scenarioForecastDemand.toStringAsFixed(1), delta: 'base ${_preview!.baselineForecastDemand.toStringAsFixed(1)}'),
                      _metric('Trusted supply', _preview!.scenarioTrustedSupply.toStringAsFixed(1), delta: 'base ${_preview!.baselineTrustedSupply.toStringAsFixed(1)}'),
                      _metric('Procurement need', _preview!.scenarioProcurementQuantity.toStringAsFixed(1), delta: formatJmd(_preview!.scenarioProcurementSpend)),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          FarmCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Product price sensitivity', style: TextStyle(color: FarmColors.ink, fontWeight: FontWeight.w900)),
                const SizedBox(height: 5),
                const Text(
                  'This keeps forecast volume static so you can see price/margin sensitivity without pretending HPJ knows customer price elasticity.',
                  style: TextStyle(color: FarmColors.mutedText, fontSize: 9.5, height: 1.3),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _product,
                  decoration: const InputDecoration(labelText: 'Product name', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _unit,
                        decoration: const InputDecoration(labelText: 'Unit', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _priceChange,
                        keyboardType: const TextInputType.numberWithOptions(signed: true, decimal: true),
                        decoration: const InputDecoration(labelText: 'Price change %', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _productLoading ? null : _previewProduct,
                  icon: const Icon(Icons.calculate_outlined, size: 17),
                  label: const Text('Preview Price Change'),
                ),
                if (_productPreview != null) ...[
                  const SizedBox(height: 10),
                  Text('${_productPreview!.productName} • ${_productPreview!.unit}', style: const TextStyle(color: FarmColors.ink, fontWeight: FontWeight.w900)),
                  Text(
                    '${formatJmd(_productPreview!.currentAveragePrice)} → ${formatJmd(_productPreview!.scenarioPrice)} • margin ${_productPreview!.observedMarginPercent.toStringAsFixed(1)}% → ${_productPreview!.scenarioMarginPercent.toStringAsFixed(1)}%',
                    style: const TextStyle(color: FarmColors.mutedText, fontSize: 10, height: 1.35),
                  ),
                  Text(
                    'Projected contribution change: ${formatJmd(_productPreview!.contributionDelta)}',
                    style: const TextStyle(color: FarmColors.primary, fontSize: 10, fontWeight: FontWeight.w800),
                  ),
                  Text(_productPreview!.scenarioNote, style: const TextStyle(color: FarmColors.mutedText, fontSize: 9, height: 1.3)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          FarmCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Saved scenarios • ${_saved.length}', style: const TextStyle(color: FarmColors.ink, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                if (_saved.isEmpty)
                  const Text('No saved scenarios yet.', style: TextStyle(color: FarmColors.mutedText, fontSize: 10))
                else
                  ..._saved.take(10).map(
                    (s) => Container(
                      margin: const EdgeInsets.only(bottom: 7),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: FarmColors.cardSoft,
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(color: FarmColors.line),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.scenarioName, style: const TextStyle(color: FarmColors.ink, fontWeight: FontWeight.w800)),
                          Text(
                            '${s.horizonDays} days • sales ${s.salesChangePercent >= 0 ? '+' : ''}${s.salesChangePercent.toStringAsFixed(0)}% • supply ${s.supplyChangePercent >= 0 ? '+' : ''}${s.supplyChangePercent.toStringAsFixed(0)}% • ${s.scenarioSignal.replaceAll('_', ' ')}',
                            style: const TextStyle(color: FarmColors.mutedText, fontSize: 9.5),
                          ),
                          Text(
                            'Sales ${formatJmd(s.scenarioSalesRevenue)} • margin ${s.scenarioMarginPercent.toStringAsFixed(1)}% • cash ${formatJmd(s.scenarioNetCashPosition)}',
                            style: const TextStyle(color: FarmColors.mutedText, fontSize: 9.5),
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
  }
}
