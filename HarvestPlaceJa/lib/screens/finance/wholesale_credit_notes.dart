part of harvest_place_app;

// ================================================================
// THE HARVEST PLACE JA
// PHASE 4D — CUSTOMER CREDITS + CREDIT NOTES
// ================================================================

class WholesaleCreditReturnCandidate {
  final String returnId, fulfillmentId, invoiceId, invoiceNumber, businessName;
  final String returnStatus, returnReason, activeCreditNoteId, activeCreditNumber, activeCreditStatus;
  final double returnedQuantity, returnValue;
  final bool canCreate;
  const WholesaleCreditReturnCandidate({required this.returnId,required this.fulfillmentId,required this.invoiceId,required this.invoiceNumber,required this.businessName,required this.returnStatus,required this.returnReason,required this.returnedQuantity,required this.returnValue,required this.activeCreditNoteId,required this.activeCreditNumber,required this.activeCreditStatus,required this.canCreate});
  factory WholesaleCreditReturnCandidate.fromSupabase(Map<String,dynamic> d) {
    double n(dynamic v)=>v is num?v.toDouble():double.tryParse(v?.toString()??'')??0;
    return WholesaleCreditReturnCandidate(
      returnId:(d['return_id']??'').toString(),fulfillmentId:(d['fulfillment_id']??'').toString(),invoiceId:(d['invoice_id']??'').toString(),
      invoiceNumber:(d['invoice_number']??'').toString().trim(),businessName:(d['business_name']??'Wholesale business').toString().trim(),
      returnStatus:(d['return_status']??'reported').toString(),returnReason:(d['return_reason']??'').toString(),returnedQuantity:n(d['returned_quantity']),returnValue:n(d['return_value']),
      activeCreditNoteId:(d['active_credit_note_id']??'').toString(),activeCreditNumber:(d['active_credit_number']??'').toString(),activeCreditStatus:(d['active_credit_status']??'').toString(),canCreate:d['can_create']==true,
    );
  }
}

class WholesaleCreditNoteRow {
  final String id, creditNumber, invoiceId, invoiceNumber, returnId, businessName, status, creditMethod, reason, notes;
  final double totalCredit; final int itemCount; final DateTime? createdAt, finalizedAt;
  const WholesaleCreditNoteRow({required this.id,required this.creditNumber,required this.invoiceId,required this.invoiceNumber,required this.returnId,required this.businessName,required this.status,required this.creditMethod,required this.reason,required this.totalCredit,required this.itemCount,required this.createdAt,required this.finalizedAt,required this.notes});
  factory WholesaleCreditNoteRow.fromSupabase(Map<String,dynamic> d){
    double n(dynamic v)=>v is num?v.toDouble():double.tryParse(v?.toString()??'')??0; int i(dynamic v)=>v is num?v.toInt():int.tryParse(v?.toString()??'')??0;
    return WholesaleCreditNoteRow(id:(d['credit_note_id']??'').toString(),creditNumber:(d['credit_number']??'').toString(),invoiceId:(d['invoice_id']??'').toString(),invoiceNumber:(d['invoice_number']??'').toString(),returnId:(d['return_id']??'').toString(),businessName:(d['business_name']??'Wholesale business').toString(),status:(d['status']??'draft').toString(),creditMethod:(d['credit_method']??'balance_reduction').toString(),reason:(d['reason']??'').toString(),totalCredit:n(d['total_credit']),itemCount:i(d['item_count']),createdAt:DateTime.tryParse((d['created_at']??'').toString()),finalizedAt:DateTime.tryParse((d['finalized_at']??'').toString()),notes:(d['notes']??'').toString());
  }
}

Future<List<WholesaleCreditReturnCandidate>> fetchWholesaleCreditReturnCandidates() async {
  await requireAdminAccess(); final response=await supabase.rpc('admin_list_credit_note_return_candidates');
  return (response as List).map((r)=>WholesaleCreditReturnCandidate.fromSupabase(Map<String,dynamic>.from(r as Map))).toList();
}
Future<List<WholesaleCreditNoteRow>> fetchWholesaleCreditNotes({String status='all',String search=''}) async {
  await requireAdminAccess(); final response=await supabase.rpc('admin_list_wholesale_credit_notes',params:{'p_status':status,'p_search':search.trim(),'p_limit':200});
  return (response as List).map((r)=>WholesaleCreditNoteRow.fromSupabase(Map<String,dynamic>.from(r as Map))).toList();
}
Future<String> createWholesaleCreditFromReturn({required WholesaleCreditReturnCandidate candidate,required String reason,required String method,String notes=''}) async {
  await requireAdminAccess(); final response=await supabase.rpc('admin_create_credit_note_from_return',params:{'p_return_id':candidate.returnId,'p_reason':reason.trim(),'p_credit_method':method,'p_notes':notes.trim()}); return response.toString();
}
Future<void> finalizeWholesaleCreditNote(String id) async { await requireAdminAccess(); await supabase.rpc('admin_finalize_wholesale_credit_note',params:{'p_credit_note_id':id}); }
Future<void> voidWholesaleCreditNote(String id,String reason) async { await requireAdminAccess(); await supabase.rpc('admin_void_wholesale_credit_note',params:{'p_credit_note_id':id,'p_reason':reason.trim()}); }

class WholesaleCreditNotesScreen extends StatefulWidget { const WholesaleCreditNotesScreen({super.key}); @override State<WholesaleCreditNotesScreen> createState()=>_WholesaleCreditNotesScreenState(); }
class _WholesaleCreditNotesScreenState extends State<WholesaleCreditNotesScreen> {
  late Future<List<dynamic>> _future; String _status='all';
  @override void initState(){super.initState();_future=_load();}
  Future<List<dynamic>> _load()=>Future.wait<dynamic>([fetchWholesaleCreditReturnCandidates(),fetchWholesaleCreditNotes(status:_status)]);
  Future<void> _refresh() async {final n=_load();setState(()=>_future=n);await n;}
  Color _color(String s){if(s=='finalized')return FarmColors.success;if(s=='void')return FarmColors.danger;return FarmColors.warning;}

  Future<void> _create(WholesaleCreditReturnCandidate c) async {
    final reason=TextEditingController(text:c.returnReason); final notes=TextEditingController(); String method='balance_reduction';
    final ok=await showDialog<bool>(context:context,builder:(dc)=>StatefulBuilder(builder:(context,setLocal)=>AlertDialog(
      title:Text('Credit ${c.invoiceNumber}'),content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text('${c.businessName} • Calculated ${formatJmd(c.returnValue)}',style:const TextStyle(fontWeight:FontWeight.w800)),const SizedBox(height:10),
        TextField(controller:reason,decoration:const InputDecoration(labelText:'Credit reason')),const SizedBox(height:8),
        DropdownButtonFormField<String>(value:method,decoration:const InputDecoration(labelText:'Credit treatment'),items:const [DropdownMenuItem(value:'balance_reduction',child:Text('Reduce invoice balance')),DropdownMenuItem(value:'account_credit',child:Text('Customer account credit'))],onChanged:(v)=>setLocal(()=>method=v??method)),
        const SizedBox(height:8),TextField(controller:notes,maxLines:2,decoration:const InputDecoration(labelText:'Finance note')),
      ])),actions:[TextButton(onPressed:()=>Navigator.of(dc).pop(false),child:const Text('Cancel')),ElevatedButton(onPressed:()=>Navigator.of(dc).pop(true),child:const Text('Create Draft'))],
    )));
    if(ok==true&&reason.text.trim().isNotEmpty){try{await createWholesaleCreditFromReturn(candidate:c,reason:reason.text,method:method,notes:notes.text);await _refresh();}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(friendlyAppError(e))));}}
    reason.dispose();notes.dispose();
  }

  Future<void> _finalize(WholesaleCreditNoteRow n) async {
    final ok=await showDialog<bool>(context:context,builder:(dc)=>AlertDialog(title:const Text('Finalize credit note?'),content:Text('${n.creditNumber} will reduce finance receivables by ${formatJmd(n.totalCredit)}. The original invoice remains unchanged.'),actions:[TextButton(onPressed:()=>Navigator.of(dc).pop(false),child:const Text('Cancel')),ElevatedButton(onPressed:()=>Navigator.of(dc).pop(true),child:const Text('Finalize'))]));
    if(ok==true){try{await finalizeWholesaleCreditNote(n.id);await _refresh();}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(friendlyAppError(e))));}}
  }

  @override Widget build(BuildContext context)=>Scaffold(backgroundColor:FarmColors.background,appBar:AppBar(title:const Text('Credits & Credit Notes')),body:FutureBuilder<List<dynamic>>(future:_future,builder:(context,s){
    if(s.connectionState==ConnectionState.waiting&&s.data==null)return const Center(child:CircularProgressIndicator()); if(s.hasError&&s.data==null)return Center(child:Text(friendlyAppError(s.error!)));
    final d=s.data??const <dynamic>[]; final candidates=d.isNotEmpty?d[0] as List<WholesaleCreditReturnCandidate>:<WholesaleCreditReturnCandidate>[]; final notes=d.length>1?d[1] as List<WholesaleCreditNoteRow>:<WholesaleCreditNoteRow>[];
    return RefreshIndicator(onRefresh:_refresh,child:ListView(physics:const AlwaysScrollableScrollPhysics(),padding:const EdgeInsets.fromLTRB(16,16,16,110),children:[
      const FarmCard(padding:EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Auditable customer credits',style:TextStyle(fontSize:17,fontWeight:FontWeight.w900)),SizedBox(height:4),Text('Create a linked credit note from a received return. HPJ preserves the original invoice and records the adjustment separately.',style:TextStyle(color:FarmColors.mutedText,fontSize:10.5,height:1.35,fontWeight:FontWeight.w600))])),
      const SizedBox(height:14),const Text('Returns awaiting finance',style:TextStyle(fontSize:16,fontWeight:FontWeight.w900)),const SizedBox(height:8),
      if(candidates.where((x)=>x.canCreate).isEmpty)const FarmCard(child:Text('No received returns are waiting for a credit note.')) else ...candidates.where((x)=>x.canCreate).map((c)=>Padding(padding:const EdgeInsets.only(bottom:8),child:FarmCard(padding:const EdgeInsets.all(12),child:Row(children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('${c.invoiceNumber} • ${c.businessName}',style:const TextStyle(fontWeight:FontWeight.w900)),Text('${formatJmd(c.returnValue)} return value • ${c.returnReason}',style:const TextStyle(color:FarmColors.mutedText,fontSize:10,fontWeight:FontWeight.w700))])),OutlinedButton(onPressed:()=>_create(c),child:const Text('Create'))])))),
      const SizedBox(height:16),SingleChildScrollView(scrollDirection:Axis.horizontal,child:Row(children:['all','draft','finalized','void'].map((v)=>Padding(padding:const EdgeInsets.only(right:7),child:ChoiceChip(label:Text(v[0].toUpperCase()+v.substring(1)),selected:_status==v,onSelected:(_){setState((){_status=v;_future=_load();});}))).toList())),const SizedBox(height:10),
      if(notes.isEmpty)const FarmEmptyState(icon:Icons.note_alt_outlined,title:'No credit notes yet',message:'Created customer credit notes will appear here.') else ...notes.map((n)=>Padding(padding:const EdgeInsets.only(bottom:9),child:FarmCard(padding:const EdgeInsets.all(13),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Expanded(child:Text('${n.creditNumber} • ${n.businessName}',style:const TextStyle(fontWeight:FontWeight.w900))),Text(n.status.toUpperCase(),style:TextStyle(color:_color(n.status),fontSize:9.5,fontWeight:FontWeight.w900))]),const SizedBox(height:5),Text('${n.invoiceNumber} • ${formatJmd(n.totalCredit)} • ${n.itemCount} item(s)',style:const TextStyle(color:FarmColors.mutedText,fontSize:10.5,fontWeight:FontWeight.w700)),if(n.status=='draft')...[const SizedBox(height:8),OutlinedButton.icon(onPressed:()=>_finalize(n),icon:const Icon(Icons.check_circle_outline,size:16),label:const Text('Finalize Credit'))]]))))
    ]));
  }));
}
