part of harvest_place_app;

// ================================================================
// THE HARVEST PLACE JA
// PHASE 5F — BUSINESS ALERTS
// ================================================================

class BusinessAlertSummary {final int criticalCount,highCount,normalCount,openCount,acknowledgedCount,supplyCount,cashCount,marginCount,receivableCount,farmerPayoutCount,demandCount,supplierCount,financeHealthCount;const BusinessAlertSummary({required this.criticalCount,required this.highCount,required this.normalCount,required this.openCount,required this.acknowledgedCount,required this.supplyCount,required this.cashCount,required this.marginCount,required this.receivableCount,required this.farmerPayoutCount,required this.demandCount,required this.supplierCount,required this.financeHealthCount});factory BusinessAlertSummary.fromSupabase(Map<String,dynamic>d){int i(dynamic v)=>v is num?v.toInt():int.tryParse('${v??''}')??0;return BusinessAlertSummary(criticalCount:i(d['critical_count']),highCount:i(d['high_count']),normalCount:i(d['normal_count']),openCount:i(d['open_count']),acknowledgedCount:i(d['acknowledged_count']),supplyCount:i(d['supply_count']),cashCount:i(d['cash_count']),marginCount:i(d['margin_count']),receivableCount:i(d['receivable_count']),farmerPayoutCount:i(d['farmer_payout_count']),demandCount:i(d['demand_count']),supplierCount:i(d['supplier_count']),financeHealthCount:i(d['finance_health_count']));}}
class BusinessAlertRow {final String alertKey,category,severity,title,entityName,metricLabel,rationale,recommendedAction,reviewStatus,reviewNote;final double metricValue,thresholdValue;final DateTime? dueDate;const BusinessAlertRow({required this.alertKey,required this.category,required this.severity,required this.title,required this.entityName,required this.metricLabel,required this.rationale,required this.recommendedAction,required this.reviewStatus,required this.reviewNote,required this.metricValue,required this.thresholdValue,this.dueDate});factory BusinessAlertRow.fromSupabase(Map<String,dynamic>d){double n(dynamic v)=>v is num?v.toDouble():double.tryParse('${v??''}')??0;return BusinessAlertRow(alertKey:(d['alert_key']??'').toString(),category:(d['category']??'general').toString(),severity:(d['severity']??'normal').toString(),title:(d['title']??'Business alert').toString(),entityName:(d['entity_name']??'').toString(),metricLabel:(d['metric_label']??'').toString(),rationale:(d['rationale']??'').toString(),recommendedAction:(d['recommended_action']??'').toString(),reviewStatus:(d['review_status']??'open').toString(),reviewNote:(d['review_note']??'').toString(),metricValue:n(d['metric_value']),thresholdValue:n(d['threshold_value']),dueDate:DateTime.tryParse('${d['due_date']??''}'));}}
Future<List<dynamic>> fetchBusinessAlertBundle({required int horizonDays,required String status})async{await requireAdminAccess();final values=await Future.wait<dynamic>([supabase.rpc('admin_business_alert_summary',params:{'p_horizon_days':horizonDays}),supabase.rpc('admin_list_business_alerts',params:{'p_horizon_days':horizonDays,'p_status':status,'p_limit':300})]);dynamic first(dynamic raw)=>raw is List&&raw.isNotEmpty?raw.first:raw;return[BusinessAlertSummary.fromSupabase(Map<String,dynamic>.from(first(values[0]) as Map)),(values[1] as List).map((e)=>BusinessAlertRow.fromSupabase(Map<String,dynamic>.from(e as Map))).toList()];}
Future<void> updateBusinessAlertReview({required String alertKey,required String status,String note=''})async{await requireAdminAccess();await supabase.rpc('admin_update_business_alert_review',params:{'p_alert_key':alertKey,'p_status':status,'p_note':note.trim()});}
class BusinessAlertsScreen extends StatefulWidget{final int initialHorizonDays;const BusinessAlertsScreen({super.key,this.initialHorizonDays=30});@override State<BusinessAlertsScreen> createState()=>_BusinessAlertsScreenState();}
class _BusinessAlertsScreenState extends State<BusinessAlertsScreen>{late int _days;String _status='attention';late Future<List<dynamic>> _future;@override void initState(){super.initState();_days=widget.initialHorizonDays;_future=fetchBusinessAlertBundle(horizonDays:_days,status:_status);}Future<void> _refresh()async{final next=fetchBusinessAlertBundle(horizonDays:_days,status:_status);setState(()=>_future=next);await next;}void _reload()=>setState(()=>_future=fetchBusinessAlertBundle(horizonDays:_days,status:_status));Color _color(String s)=>s=='critical'?FarmColors.danger:s=='high'?FarmColors.warning:FarmColors.primary;Future<void> _set(BusinessAlertRow r,String status)async{try{await updateBusinessAlertReview(alertKey:r.alertKey,status:status,note:r.reviewNote);if(!mounted)return;ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Alert marked $status.')));await _refresh();}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(friendlyAppError(e))));}}
Widget _count(String label,int value,IconData icon)=>Container(width:140,padding:const EdgeInsets.all(10),decoration:BoxDecoration(color:FarmColors.cardSoft,borderRadius:BorderRadius.circular(12),border:Border.all(color:FarmColors.line)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(icon,size:17,color:FarmColors.primary),const SizedBox(height:4),Text('$value',style:const TextStyle(color:FarmColors.ink,fontWeight:FontWeight.w900,fontSize:13)),Text(label,style:const TextStyle(color:FarmColors.mutedText,fontSize:9,fontWeight:FontWeight.w700))]));
@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: FarmColors.background,
    appBar: AppBar(title: const Text('Business Alerts')),
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
        if (data.length < 2) return const SizedBox.shrink();
        final s = data[0] as BusinessAlertSummary;
        final rows = data[1] as List<BusinessAlertRow>;

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
                        Icon(Icons.notifications_active_outlined, color: FarmColors.primary, size: 28),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Business Early-Warning Alerts',
                            style: TextStyle(color: FarmColors.ink, fontSize: 17, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Live alerts combine forecast ranges, supply gaps, receivables, margin controls, farmer payouts, demand shifts, supplier performance and finance health. Alerts are advisory.',
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
                                onSelected: (_) {
                                  _days = d;
                                  _reload();
                                },
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 7),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['attention', 'open', 'acknowledged', 'resolved', 'ignored', 'all']
                            .map((v) => Padding(
                                  padding: const EdgeInsets.only(right: 7),
                                  child: ChoiceChip(
                                    label: Text(v == 'attention' ? 'Attention' : v[0].toUpperCase() + v.substring(1)),
                                    selected: _status == v,
                                    onSelected: (_) {
                                      _status = v;
                                      _reload();
                                    },
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              FarmCard(
                padding: const EdgeInsets.all(14),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _count('Critical', s.criticalCount, Icons.error_outline),
                    _count('High', s.highCount, Icons.warning_amber_rounded),
                    _count('Open', s.openCount, Icons.pending_actions_outlined),
                    _count('Supply', s.supplyCount, Icons.inventory_2_outlined),
                    _count('Cash', s.cashCount, Icons.account_balance_wallet_outlined),
                    _count('Receivables', s.receivableCount, Icons.receipt_long_outlined),
                    _count('Farmer payouts', s.farmerPayoutCount, Icons.agriculture_outlined),
                    _count('Demand shifts', s.demandCount, Icons.show_chart_rounded),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (rows.isEmpty)
                const FarmEmptyState(
                  icon: Icons.check_circle_outline,
                  title: 'No alerts in this view',
                  message: 'HPJ has no live early-warning alerts matching the selected horizon and status.',
                )
              else
                ...rows.map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: FarmCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                margin: const EdgeInsets.only(top: 4),
                                decoration: BoxDecoration(color: _color(r.severity), shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(r.title, style: const TextStyle(color: FarmColors.ink, fontWeight: FontWeight.w900)),
                                    if (r.entityName.isNotEmpty)
                                      Text(r.entityName, style: const TextStyle(color: FarmColors.mutedText, fontSize: 9.5, fontWeight: FontWeight.w700)),
                                  ],
                                ),
                              ),
                              Text(r.severity.toUpperCase(), style: TextStyle(color: _color(r.severity), fontSize: 9, fontWeight: FontWeight.w900)),
                            ],
                          ),
                          const SizedBox(height: 7),
                          Wrap(
                            spacing: 7,
                            runSpacing: 7,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                decoration: BoxDecoration(color: FarmColors.primarySoft, borderRadius: BorderRadius.circular(20)),
                                child: Text(r.category.replaceAll('_', ' '), style: const TextStyle(color: FarmColors.primary, fontSize: 8.5, fontWeight: FontWeight.w900)),
                              ),
                              if (r.metricLabel.isNotEmpty)
                                Text('${r.metricLabel}: ${r.metricValue.toStringAsFixed(1)}', style: const TextStyle(color: FarmColors.mutedText, fontSize: 9, fontWeight: FontWeight.w700)),
                              if (r.dueDate != null)
                                Text('Due ${r.dueDate!.day}/${r.dueDate!.month}/${r.dueDate!.year}', style: const TextStyle(color: FarmColors.mutedText, fontSize: 9, fontWeight: FontWeight.w700)),
                            ],
                          ),
                          if (r.rationale.isNotEmpty) ...[
                            const SizedBox(height: 7),
                            Text(r.rationale, style: const TextStyle(color: FarmColors.mutedText, fontSize: 10, height: 1.35, fontWeight: FontWeight.w600)),
                          ],
                          if (r.recommendedAction.isNotEmpty) ...[
                            const SizedBox(height: 5),
                            Text('Recommended: ${r.recommendedAction}', style: const TextStyle(color: FarmColors.ink, fontSize: 10, height: 1.35, fontWeight: FontWeight.w800)),
                          ],
                          const SizedBox(height: 9),
                          Wrap(
                            spacing: 7,
                            children: [
                              OutlinedButton.icon(
                                onPressed: r.reviewStatus == 'acknowledged' ? null : () => _set(r, 'acknowledged'),
                                icon: const Icon(Icons.visibility_outlined, size: 16),
                                label: const Text('Acknowledge'),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => _set(r, 'resolved'),
                                icon: const Icon(Icons.check_circle_outline, size: 16),
                                label: const Text('Resolve'),
                              ),
                              TextButton(onPressed: () => _set(r, 'ignored'), child: const Text('Ignore')),
                            ],
                          ),
                        ],
                      ),
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
