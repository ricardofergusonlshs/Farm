part of harvest_place_app;

// ================================================================
// PHASE 4G — CASH FLOW COMMAND CENTER
// Planning visibility; this screen does not claim to be a bank balance.
// ================================================================

class WholesaleCashFlowSummary {
  final int horizonDays;
  final double receipts30;
  final double settlementsPaid30;
  final double refundsPaid30;
  final double netRecorded30;
  final double receivablesDue;
  final double overdueReceivables;
  final double unpaidFarmerObligations;
  final double unbatchedFarmerObligations;
  final double refundExposure;
  final double supplierClaimsRecoverable;
  final double netPlanningPosition;
  final int overdueInvoiceCount;
  final int approvedSettlementCount;

  const WholesaleCashFlowSummary({required this.horizonDays,required this.receipts30,required this.settlementsPaid30,required this.refundsPaid30,required this.netRecorded30,required this.receivablesDue,required this.overdueReceivables,required this.unpaidFarmerObligations,required this.unbatchedFarmerObligations,required this.refundExposure,required this.supplierClaimsRecoverable,required this.netPlanningPosition,required this.overdueInvoiceCount,required this.approvedSettlementCount});

  factory WholesaleCashFlowSummary.fromSupabase(Map<String,dynamic> d){
    double n(dynamic v)=>v is num?v.toDouble():double.tryParse(v?.toString()??'')??0;
    int i(dynamic v)=>v is num?v.toInt():int.tryParse(v?.toString()??'')??0;
    return WholesaleCashFlowSummary(
      horizonDays:i(d['horizon_days']),receipts30:n(d['confirmed_customer_receipts_30']),settlementsPaid30:n(d['farmer_settlements_paid_30']),refundsPaid30:n(d['customer_refunds_paid_30']),netRecorded30:n(d['net_recorded_cash_movement_30']),receivablesDue:n(d['receivables_due_horizon']),overdueReceivables:n(d['overdue_receivables']),unpaidFarmerObligations:n(d['unpaid_farmer_obligations']),unbatchedFarmerObligations:n(d['unbatched_farmer_obligations']),refundExposure:n(d['refund_exposure']),supplierClaimsRecoverable:n(d['supplier_claims_recoverable']),netPlanningPosition:n(d['net_planning_position']),overdueInvoiceCount:i(d['overdue_invoice_count']),approvedSettlementCount:i(d['approved_settlement_count']));
  }
}

Future<WholesaleCashFlowSummary> fetchWholesaleCashFlowSummary(int horizonDays) async {
  await requireAdminAccess();
  final response=await supabase.rpc('admin_cash_flow_command_summary',params:{'p_horizon_days':horizonDays});
  if(response is List&&response.isNotEmpty)return WholesaleCashFlowSummary.fromSupabase(Map<String,dynamic>.from(response.first as Map));
  if(response is Map)return WholesaleCashFlowSummary.fromSupabase(Map<String,dynamic>.from(response));
  throw Exception('Cash-flow summary could not be loaded.');
}

class WholesaleCashFlowScreen extends StatefulWidget { const WholesaleCashFlowScreen({super.key}); @override State<WholesaleCashFlowScreen> createState()=>_WholesaleCashFlowScreenState(); }
class _WholesaleCashFlowScreenState extends State<WholesaleCashFlowScreen>{
  int _horizon=30; late Future<List<dynamic>> _future;
  @override void initState(){super.initState();_future=_load();}
  Future<List<dynamic>> _load()=>Future.wait<dynamic>([fetchWholesaleCashFlowSummary(_horizon),fetchWholesaleReceivables(status:'open')]);
  Future<void> _refresh()async{final next=_load();setState(()=>_future=next);await next;}
  Widget _metric(String label,double value,IconData icon,{bool signed=false})=>Container(width:150,padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:FarmColors.cardSoft,borderRadius:BorderRadius.circular(14),border:Border.all(color:FarmColors.line)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(icon,color:FarmColors.primary,size:18),const SizedBox(height:7),Text('${signed&&value>0?'+ ':''}${formatJmd(value)}',style:const TextStyle(fontSize:14,fontWeight:FontWeight.w900)),Text(label,style:const TextStyle(color:FarmColors.mutedText,fontSize:9.5,fontWeight:FontWeight.w700))]));
  @override Widget build(BuildContext context)=>Scaffold(backgroundColor:FarmColors.background,appBar:AppBar(title:const Text('Cash Flow')),body:FutureBuilder<List<dynamic>>(future:_future,builder:(context,snapshot){
    if(snapshot.connectionState==ConnectionState.waiting&&snapshot.data==null)return const Center(child:CircularProgressIndicator());
    if(snapshot.hasError&&snapshot.data==null)return Center(child:Text(friendlyAppError(snapshot.error!)));
    final data=snapshot.data??const<dynamic>[]; if(data.length<2)return const SizedBox.shrink();
    final s=data[0] as WholesaleCashFlowSummary; final receivables=data[1] as List<WholesaleReceivableRow>;
    return RefreshIndicator(onRefresh:_refresh,child:ListView(physics:const AlwaysScrollableScrollPhysics(),padding:const EdgeInsets.fromLTRB(16,16,16,110),children:[
      const FarmCard(padding:EdgeInsets.all(16),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(Icons.account_balance_outlined,color:FarmColors.primary,size:30),SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Cash Flow Command Center',style:TextStyle(fontSize:17,fontWeight:FontWeight.w900)),SizedBox(height:4),Text('This is a planning view of expected money in, known obligations and recent recorded cash movement. It is not the live balance of your bank account.',style:TextStyle(color:FarmColors.mutedText,fontSize:10.5,height:1.35,fontWeight:FontWeight.w600))]))])),
      const SizedBox(height:12),SingleChildScrollView(scrollDirection:Axis.horizontal,child:Row(children:[7,30,60,90].map((d)=>Padding(padding:const EdgeInsets.only(right:7),child:ChoiceChip(label:Text('$d days'),selected:_horizon==d,onSelected:(_){setState((){_horizon=d;_future=_load();});}))).toList())),
      const SizedBox(height:12),SingleChildScrollView(scrollDirection:Axis.horizontal,child:Row(children:[_metric('Receivables due',s.receivablesDue,Icons.receipt_long_outlined),const SizedBox(width:8),_metric('Farmer obligations',s.unpaidFarmerObligations,Icons.agriculture_outlined),const SizedBox(width:8),_metric('Refund exposure',s.refundExposure,Icons.assignment_return_outlined),const SizedBox(width:8),_metric('Planning position',s.netPlanningPosition,Icons.analytics_outlined,signed:true)])),
      const SizedBox(height:10),FarmCard(padding:const EdgeInsets.all(14),child:Wrap(spacing:14,runSpacing:8,children:[Text('Overdue ${formatJmd(s.overdueReceivables)}',style:const TextStyle(fontWeight:FontWeight.w900,color:FarmColors.warning)),Text('Unbatched farmer ${formatJmd(s.unbatchedFarmerObligations)}',style:const TextStyle(fontWeight:FontWeight.w800)),Text('Claims recoverable ${formatJmd(s.supplierClaimsRecoverable)}',style:const TextStyle(fontWeight:FontWeight.w800)),Text('${s.overdueInvoiceCount} overdue invoice(s)',style:const TextStyle(fontWeight:FontWeight.w800)),Text('${s.approvedSettlementCount} approved settlement(s)',style:const TextStyle(fontWeight:FontWeight.w800))])),
      const SizedBox(height:16),const Text('Recorded Cash Movement • Last 30 Days',style:TextStyle(fontSize:16,fontWeight:FontWeight.w900)),const SizedBox(height:8),FarmCard(padding:const EdgeInsets.all(14),child:Wrap(spacing:12,runSpacing:10,children:[_CashFlowValue(label:'Customer receipts',value:s.receipts30),_CashFlowValue(label:'Farmer settlements',value:s.settlementsPaid30),_CashFlowValue(label:'Customer refunds',value:s.refundsPaid30),_CashFlowValue(label:'Net recorded',value:s.netRecorded30)])),
      const SizedBox(height:18),const Text('Next Receivables',style:TextStyle(fontSize:16,fontWeight:FontWeight.w900)),const SizedBox(height:8),if(receivables.isEmpty)const FarmEmptyState(icon:Icons.receipt_long_outlined,title:'No open receivables',message:'Issued unpaid wholesale invoices will appear here.')else ...receivables.take(10).map((r)=>Padding(padding:const EdgeInsets.only(bottom:8),child:FarmCard(padding:const EdgeInsets.all(12),child:Row(children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('${r.invoiceNumber} • ${r.businessName}',style:const TextStyle(fontWeight:FontWeight.w900)),Text(r.isOverdue?'${r.daysOverdue} day(s) overdue':r.agingBucket,style:TextStyle(color:r.isOverdue?FarmColors.warning:FarmColors.mutedText,fontSize:10,fontWeight:FontWeight.w700))])),Text(formatJmd(r.amountDue),style:const TextStyle(fontWeight:FontWeight.w900))]))))
    ]));
  }));
}
class _CashFlowValue extends StatelessWidget{final String label;final double value;const _CashFlowValue({required this.label,required this.value});@override Widget build(BuildContext context)=>Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:8),decoration:BoxDecoration(color:FarmColors.cardSoft,borderRadius:BorderRadius.circular(12),border:Border.all(color:FarmColors.line)),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(label,style:const TextStyle(color:FarmColors.mutedText,fontSize:9,fontWeight:FontWeight.w700)),Text(formatJmd(value),style:const TextStyle(fontWeight:FontWeight.w900))]));}
