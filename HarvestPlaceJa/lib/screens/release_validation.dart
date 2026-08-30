part of harvest_place_app;

// ================================================================
// THE HARVEST PLACE JA
// PHASE 5G — RELEASE VALIDATION CENTER
// ================================================================

class ReleaseValidationCheck {
  final String key;
  final String area;
  final String severity;
  final String status;
  final String title;
  final String detail;
  final double metricValue;
  final double targetValue;
  const ReleaseValidationCheck({required this.key,required this.area,required this.severity,required this.status,required this.title,required this.detail,required this.metricValue,required this.targetValue});
  factory ReleaseValidationCheck.fromSupabase(Map<String,dynamic> d) {
    double n(dynamic v)=>v is num?v.toDouble():double.tryParse('${v??''}')??0;
    return ReleaseValidationCheck(
      key:(d['check_key']??'').toString(),area:(d['area']??'').toString(),severity:(d['severity']??'normal').toString(),
      status:(d['check_status']??'warning').toString(),title:(d['title']??'Check').toString(),detail:(d['detail']??'').toString(),
      metricValue:n(d['metric_value']),targetValue:n(d['target_value']));
  }
}

class ReleaseValidationSummary {
  final int totalChecks,passCount,warningCount,failCount;
  final double score;
  final String status;
  const ReleaseValidationSummary({required this.totalChecks,required this.passCount,required this.warningCount,required this.failCount,required this.score,required this.status});
  factory ReleaseValidationSummary.fromSupabase(Map<String,dynamic>d){
    int i(dynamic v)=>v is num?v.toInt():int.tryParse('${v??''}')??0; double n(dynamic v)=>v is num?v.toDouble():double.tryParse('${v??''}')??0;
    return ReleaseValidationSummary(totalChecks:i(d['total_checks']),passCount:i(d['pass_count']),warningCount:i(d['warning_count']),failCount:i(d['fail_count']),score:n(d['validation_score']),status:(d['validation_status']??'review').toString());
  }
}

Future<ReleaseValidationSummary> fetchReleaseValidationSummary(int days) async {
  await requireAdminAccess();
  final r=await supabase.rpc('admin_release_validation_summary',params:{'p_horizon_days':days});
  if(r is List && r.isNotEmpty)return ReleaseValidationSummary.fromSupabase(Map<String,dynamic>.from(r.first as Map));
  if(r is Map)return ReleaseValidationSummary.fromSupabase(Map<String,dynamic>.from(r));
  throw Exception('Release validation summary could not be loaded.');
}
Future<List<ReleaseValidationCheck>> fetchReleaseValidationChecks(int days) async {
  await requireAdminAccess();
  final r=await supabase.rpc('admin_list_release_validation_checks',params:{'p_horizon_days':days});
  return (r as List? ?? const []).map((e)=>ReleaseValidationCheck.fromSupabase(Map<String,dynamic>.from(e as Map))).toList();
}
Future<void> captureReleaseValidationRun(int days,{String note=''}) async {
  await requireAdminAccess();
  await supabase.rpc('admin_capture_release_validation_run',params:{'p_horizon_days':days,'p_note':note});
}

class ReleaseValidationScreen extends StatefulWidget {
  final int initialHorizonDays;
  const ReleaseValidationScreen({super.key,this.initialHorizonDays=30});
  @override State<ReleaseValidationScreen> createState()=>_ReleaseValidationScreenState();
}
class _ReleaseValidationScreenState extends State<ReleaseValidationScreen>{
  late int _days; late Future<(ReleaseValidationSummary,List<ReleaseValidationCheck>)> _future; bool _capturing=false;
  @override void initState(){super.initState();_days=widget.initialHorizonDays;_load();}
  void _load(){_future=Future.wait([fetchReleaseValidationSummary(_days),fetchReleaseValidationChecks(_days)]).then((v)=>(v[0] as ReleaseValidationSummary,v[1] as List<ReleaseValidationCheck>));}
  Future<void> _refresh()async{setState(_load);await _future;}
  Color _color(String s)=>s=='fail'?FarmColors.danger:s=='warning'?FarmColors.warning:FarmColors.success;
  IconData _icon(String s)=>s=='fail'?Icons.error_outline:s=='warning'?Icons.warning_amber_rounded:Icons.check_circle_outline;
  Future<void> _capture()async{if(_capturing)return;setState(()=>_capturing=true);try{await captureReleaseValidationRun(_days,note:'Pre-test validation');if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Validation snapshot captured.')));}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(friendlyAppError(e))));}finally{if(mounted)setState(()=>_capturing=false);}}
  @override Widget build(BuildContext context){
    return Scaffold(appBar:AppBar(title:const Text('Release Validation')),body:FutureBuilder<(ReleaseValidationSummary,List<ReleaseValidationCheck>)>(future:_future,builder:(context,s){
      if(s.connectionState==ConnectionState.waiting&&s.data==null)return const Center(child:CircularProgressIndicator());
      if(s.hasError&&s.data==null)return Center(child:Text(friendlyAppError(s.error!)));
      final data=s.data;if(data==null)return const SizedBox.shrink();final summary=data.$1;final checks=data.$2;
      return RefreshIndicator(onRefresh:_refresh,child:ListView(physics:const AlwaysScrollableScrollPhysics(),padding:const EdgeInsets.fromLTRB(16,16,16,100),children:[
        FarmCard(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          const Row(children:[Icon(Icons.fact_check_outlined,color:FarmColors.primary),SizedBox(width:10),Expanded(child:Text('Pre-test validation gate',style:TextStyle(fontSize:17,fontWeight:FontWeight.w900,color:FarmColors.ink)))]),
          const SizedBox(height:8),const Text('Checks schema dependencies, RLS, finance integrity, forecast snapshot shape and current data-quality warnings. Business warnings do not automatically block testing.',style:TextStyle(color:FarmColors.mutedText,fontSize:10.5,height:1.35)),
          const SizedBox(height:12),Wrap(spacing:8,children:[7,30,60,90].map((d)=>ChoiceChip(label:Text('$d days'),selected:_days==d,onSelected:(_){setState((){_days=d;_load();});})).toList()),
          const SizedBox(height:12),Wrap(spacing:12,runSpacing:8,children:[Text('Score ${summary.score.toStringAsFixed(0)}%',style:TextStyle(fontWeight:FontWeight.w900,color:_color(summary.status=='blocked'?'fail':summary.status=='review'?'warning':'pass'))),Text('${summary.passCount} pass'),Text('${summary.warningCount} warning'),Text('${summary.failCount} fail')]),
          const SizedBox(height:12),SizedBox(width:double.infinity,child:OutlinedButton.icon(onPressed:_capturing?null:_capture,icon:const Icon(Icons.save_outlined),label:Text(_capturing?'Saving…':'Capture Validation Snapshot'))),
        ])),
        const SizedBox(height:12),...checks.map((c)=>Padding(padding:const EdgeInsets.only(bottom:8),child:FarmCard(padding:const EdgeInsets.all(13),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(_icon(c.status),color:_color(c.status),size:22),const SizedBox(width:10),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(c.title,style:const TextStyle(fontWeight:FontWeight.w900,color:FarmColors.ink)),const SizedBox(height:3),Text(c.detail,style:const TextStyle(color:FarmColors.mutedText,fontSize:10,height:1.35)),const SizedBox(height:5),Text('${c.area.toUpperCase()} • ${c.severity.toUpperCase()} • ${c.status.toUpperCase()}',style:TextStyle(fontSize:9,fontWeight:FontWeight.w900,color:_color(c.status)))]) )])))).toList(),
      ]));
    }));
  }
}
