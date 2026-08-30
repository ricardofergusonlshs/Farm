part of harvest_place_app;

// ================================================================
// THE HARVEST PLACE JA
// PHASE 5C — EXECUTIVE DECISION CENTER
// ================================================================

class ExecutiveDecisionSummary {
  final int criticalCount,highCount,normalCount,openCount,acknowledgedCount;
  final double estimatedImpactAmount;
  final int procurementCount,cashCollectionCount,financeControlCount,inventoryCount,commercialCount,farmerPayoutCount,reconciliationCount,cashPlanningCount;
  const ExecutiveDecisionSummary({required this.criticalCount,required this.highCount,required this.normalCount,required this.openCount,required this.acknowledgedCount,required this.estimatedImpactAmount,required this.procurementCount,required this.cashCollectionCount,required this.financeControlCount,required this.inventoryCount,required this.commercialCount,required this.farmerPayoutCount,required this.reconciliationCount,required this.cashPlanningCount});
  factory ExecutiveDecisionSummary.fromSupabase(Map<String,dynamic>d){int i(dynamic v)=>v is num?v.toInt():int.tryParse('${v??''}')??0;double n(dynamic v)=>v is num?v.toDouble():double.tryParse('${v??''}')??0;return ExecutiveDecisionSummary(criticalCount:i(d['critical_count']),highCount:i(d['high_count']),normalCount:i(d['normal_count']),openCount:i(d['open_count']),acknowledgedCount:i(d['acknowledged_count']),estimatedImpactAmount:n(d['estimated_impact_amount']),procurementCount:i(d['procurement_count']),cashCollectionCount:i(d['cash_collection_count']),financeControlCount:i(d['finance_control_count']),inventoryCount:i(d['inventory_count']),commercialCount:i(d['commercial_count']),farmerPayoutCount:i(d['farmer_payout_count']),reconciliationCount:i(d['reconciliation_count']),cashPlanningCount:i(d['cash_planning_count']));}
}

class ExecutiveDecisionRow {
  final String decisionKey,domain,priority,title,entityName,metricLabel,rationale,recommendedAction,reviewStatus,reviewNote;
  final double metricValue,impactAmount;
  final DateTime? dueDate;
  const ExecutiveDecisionRow({required this.decisionKey,required this.domain,required this.priority,required this.title,required this.entityName,required this.metricLabel,required this.metricValue,required this.impactAmount,this.dueDate,required this.rationale,required this.recommendedAction,required this.reviewStatus,required this.reviewNote});
  factory ExecutiveDecisionRow.fromSupabase(Map<String,dynamic>d){double n(dynamic v)=>v is num?v.toDouble():double.tryParse('${v??''}')??0;return ExecutiveDecisionRow(decisionKey:(d['decision_key']??'').toString(),domain:(d['domain']??'general').toString(),priority:(d['priority']??'normal').toString(),title:(d['title']??'Decision').toString(),entityName:(d['entity_name']??'').toString(),metricLabel:(d['metric_label']??'').toString(),metricValue:n(d['metric_value']),impactAmount:n(d['impact_amount']),dueDate:DateTime.tryParse('${d['due_date']??''}'),rationale:(d['rationale']??'').toString(),recommendedAction:(d['recommended_action']??'').toString(),reviewStatus:(d['review_status']??'open').toString(),reviewNote:(d['review_note']??'').toString());}
}

Future<List<dynamic>> fetchExecutiveDecisionBundle({required int horizonDays,required String status}) async {
  await requireAdminAccess();
  final values=await Future.wait<dynamic>([
    supabase.rpc('admin_executive_decision_summary',params:{'p_horizon_days':horizonDays}),
    supabase.rpc('admin_list_executive_decisions',params:{'p_horizon_days':horizonDays,'p_status':status,'p_limit':250}),
  ]);
  dynamic first(dynamic raw)=>raw is List&&raw.isNotEmpty?raw.first:raw;
  final summary=ExecutiveDecisionSummary.fromSupabase(Map<String,dynamic>.from(first(values[0]) as Map));
  final rows=(values[1] as List).map((e)=>ExecutiveDecisionRow.fromSupabase(Map<String,dynamic>.from(e as Map))).toList();
  return [summary,rows];
}

Future<void> updateExecutiveDecisionReview({required String decisionKey,required String status,String note=''}) async {
  await requireAdminAccess();
  await supabase.rpc('admin_update_executive_decision_review',params:{'p_decision_key':decisionKey,'p_status':status,'p_note':note.trim()});
}

class ExecutiveDecisionCenterScreen extends StatefulWidget {
  final int initialHorizonDays;
  const ExecutiveDecisionCenterScreen({super.key,this.initialHorizonDays=30});
  @override
  State<ExecutiveDecisionCenterScreen> createState()=>_ExecutiveDecisionCenterScreenState();
}

class _ExecutiveDecisionCenterScreenState extends State<ExecutiveDecisionCenterScreen> {
  late int _days;String _status='attention';late Future<List<dynamic>> _future;
  @override void initState(){super.initState();_days=widget.initialHorizonDays;_future=fetchExecutiveDecisionBundle(horizonDays:_days,status:_status);}
  Future<void> _refresh()async{final next=fetchExecutiveDecisionBundle(horizonDays:_days,status:_status);setState(()=>_future=next);await next;}
  void _reload(){setState(()=>_future=fetchExecutiveDecisionBundle(horizonDays:_days,status:_status));}
  Color _priorityColor(String p)=>p=='critical'?FarmColors.danger:p=='high'?FarmColors.warning:FarmColors.primary;
  String _domainLabel(String d)=>d.replaceAll('_',' ');

  Future<void> _setReview(ExecutiveDecisionRow row,String status) async {
    try{await updateExecutiveDecisionReview(decisionKey:row.decisionKey,status:status,note:row.reviewNote);if(!mounted)return;ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Decision marked $status.')));await _refresh();}
    catch(e){if(!mounted)return;ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(friendlyAppError(e))));}
  }

  @override Widget build(BuildContext context){return Scaffold(backgroundColor:FarmColors.background,appBar:AppBar(title:const Text('Decision Center')),body:FutureBuilder<List<dynamic>>(future:_future,builder:(context,snapshot){
    if(snapshot.connectionState==ConnectionState.waiting&&snapshot.data==null)return const Center(child:CircularProgressIndicator());
    if(snapshot.hasError&&snapshot.data==null)return Center(child:Text(friendlyAppError(snapshot.error!)));
    final data=snapshot.data??const<dynamic>[];if(data.length<2)return const SizedBox.shrink();final s=data[0] as ExecutiveDecisionSummary;final rows=data[1] as List<ExecutiveDecisionRow>;
    return RefreshIndicator(onRefresh:_refresh,child:ListView(physics:const AlwaysScrollableScrollPhysics(),padding:const EdgeInsets.fromLTRB(16,16,16,110),children:[
      FarmCard(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        const Row(children:[Icon(Icons.lightbulb_outline,color:FarmColors.primary,size:28),SizedBox(width:10),Expanded(child:Text('Executive Decision Center',style:TextStyle(color:FarmColors.ink,fontSize:17,fontWeight:FontWeight.w900)))]),
        const SizedBox(height:6),const Text('Prioritized actions assembled from live procurement, receivables, finance controls, inventory, pricing, payout schedules and bank reconciliation. Recommendations are advisory; source transactions are not changed here.',style:TextStyle(color:FarmColors.mutedText,fontSize:10.5,height:1.35,fontWeight:FontWeight.w600)),
        const SizedBox(height:12),Wrap(spacing:8,runSpacing:8,children:[7,30,60,90].map((d)=>ChoiceChip(label:Text('$d days'),selected:_days==d,onSelected:(_){_days=d;_reload();})).toList()),
        const SizedBox(height:8),SingleChildScrollView(scrollDirection:Axis.horizontal,child:Row(children:['attention','open','acknowledged','resolved','ignored','all'].map((v)=>Padding(padding:const EdgeInsets.only(right:7),child:ChoiceChip(label:Text(v=='attention'?'Attention':v[0].toUpperCase()+v.substring(1)),selected:_status==v,onSelected:(_){_status=v;_reload();}))).toList())),
      ])),
      const SizedBox(height:12),
      FarmCard(padding:const EdgeInsets.all(14),child:Wrap(spacing:8,runSpacing:8,children:[
        _DecisionMetric(label:'Critical',value:'${s.criticalCount}',icon:Icons.error_outline),_DecisionMetric(label:'High',value:'${s.highCount}',icon:Icons.warning_amber_rounded),_DecisionMetric(label:'Open',value:'${s.openCount}',icon:Icons.pending_actions_outlined),_DecisionMetric(label:'Acknowledged',value:'${s.acknowledgedCount}',icon:Icons.check_circle_outline),_DecisionMetric(label:'Estimated exposure',value:formatJmd(s.estimatedImpactAmount),icon:Icons.account_balance_wallet_outlined),
      ])),
      const SizedBox(height:12),
      if(rows.isEmpty)const FarmEmptyState(icon:Icons.check_circle_outline,title:'No decisions in this view',message:'HPJ has no live recommendations matching the selected status and horizon.') else ...rows.map((r)=>Padding(padding:const EdgeInsets.only(bottom:9),child:FarmCard(padding:const EdgeInsets.all(14),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Container(width:10,height:10,margin:const EdgeInsets.only(top:4),decoration:BoxDecoration(color:_priorityColor(r.priority),shape:BoxShape.circle)),const SizedBox(width:8),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(r.title,style:const TextStyle(color:FarmColors.ink,fontWeight:FontWeight.w900)),if(r.entityName.isNotEmpty)Text(r.entityName,style:const TextStyle(color:FarmColors.mutedText,fontSize:9.5,fontWeight:FontWeight.w700))])),Text(r.priority.toUpperCase(),style:TextStyle(color:_priorityColor(r.priority),fontSize:9,fontWeight:FontWeight.w900))]),
        const SizedBox(height:8),Wrap(spacing:7,runSpacing:7,children:[_DecisionTag(text:_domainLabel(r.domain)),if(r.metricLabel.isNotEmpty)_DecisionTag(text:'${r.metricLabel}: ${r.metricValue.toStringAsFixed(1)}'),if(r.dueDate!=null)_DecisionTag(text:'Due ${r.dueDate!.day}/${r.dueDate!.month}/${r.dueDate!.year}'),_DecisionTag(text:r.reviewStatus)]),
        if(r.rationale.isNotEmpty)...[const SizedBox(height:8),Text(r.rationale,style:const TextStyle(color:FarmColors.mutedText,fontSize:10,height:1.35,fontWeight:FontWeight.w600))],
        if(r.recommendedAction.isNotEmpty)...[const SizedBox(height:6),Text('Recommended: ${r.recommendedAction}',style:const TextStyle(color:FarmColors.ink,fontSize:10,height:1.35,fontWeight:FontWeight.w800))],
        const SizedBox(height:10),Wrap(spacing:7,runSpacing:7,children:[OutlinedButton.icon(onPressed:r.reviewStatus=='acknowledged'?null:()=>_setReview(r,'acknowledged'),icon:const Icon(Icons.visibility_outlined,size:16),label:const Text('Acknowledge')),OutlinedButton.icon(onPressed:()=>_setReview(r,'resolved'),icon:const Icon(Icons.check_circle_outline,size:16),label:const Text('Resolve')),TextButton(onPressed:()=>_setReview(r,'ignored'),child:const Text('Ignore'))]),
      ]))))
    ]));
  }));}
}

class _DecisionMetric extends StatelessWidget {final String label,value;final IconData icon;const _DecisionMetric({required this.label,required this.value,required this.icon});@override Widget build(BuildContext context)=>Container(width:145,padding:const EdgeInsets.all(11),decoration:BoxDecoration(color:FarmColors.cardSoft,borderRadius:BorderRadius.circular(13),border:Border.all(color:FarmColors.line)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(icon,size:17,color:FarmColors.primary),const SizedBox(height:5),Text(value,style:const TextStyle(color:FarmColors.ink,fontWeight:FontWeight.w900,fontSize:13)),Text(label,style:const TextStyle(color:FarmColors.mutedText,fontSize:9,fontWeight:FontWeight.w700))]));}
class _DecisionTag extends StatelessWidget {final String text;const _DecisionTag({required this.text});@override Widget build(BuildContext context)=>Container(padding:const EdgeInsets.symmetric(horizontal:8,vertical:5),decoration:BoxDecoration(color:FarmColors.primarySoft,borderRadius:BorderRadius.circular(20)),child:Text(text,style:const TextStyle(color:FarmColors.primary,fontSize:8.5,fontWeight:FontWeight.w900)));}
