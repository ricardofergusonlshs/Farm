// HPJ INVITE & GROW — opt-in Customer, Business and Farmer invitations.
// This file is a PART, not a standalone library. Add its part line to lib/main.dart.
// No automated WhatsApp sending. Opening a chat is not proof of delivery.
part of harvest_place_app;

const List<String> _hpjInviteAudiences = <String>['customer', 'business', 'farmer'];

String _hpjInviteAudienceLabel(String value) {
  switch (value) {
    case 'business': return 'Business';
    case 'farmer': return 'Farmer';
    default: return 'Customer';
  }
}

String _hpjInviteNormalizePhone(String input) {
  var digits = input.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.length == 10 &&
      (digits.startsWith('876') || digits.startsWith('658'))) {
    digits = '1$digits';
  }
  if (!RegExp(r'^[1-9][0-9]{7,14}$').hasMatch(digits)) return '';
  return '+$digits';
}

String _hpjInviteFirstName(String fullName) {
  final trimmed = fullName.trim();
  if (trimmed.isEmpty) return '';
  return trimmed.split(RegExp(r'\s+')).first;
}

String _hpjInviteSenderName() {
  final user = supabase.auth.currentUser;
  final metadata = user?.userMetadata ?? const <String, dynamic>{};
  for (final key in const <String>['full_name', 'display_name', 'name']) {
    final result = metadata[key]?.toString().trim() ?? '';
    if (result.isNotEmpty) return result;
  }
  return 'HPJ Team';
}

class HpjInviteTemplate {
  final String audience;
  final String headline;
  final String body;
  final String imageUrl;
  final String destinationUrl;
  final bool enabled;

  const HpjInviteTemplate({
    required this.audience,
    required this.headline,
    required this.body,
    required this.imageUrl,
    required this.destinationUrl,
    required this.enabled,
  });

  factory HpjInviteTemplate.fromRow(Map<String, dynamic> row) => HpjInviteTemplate(
    audience: (row['audience'] ?? 'customer').toString(),
    headline: (row['headline'] ?? '').toString(),
    body: (row['message_template'] ?? '').toString(),
    imageUrl: (row['image_url'] ?? '').toString(),
    destinationUrl: (row['destination_url'] ?? hpjSharePlayUrl).toString(),
    enabled: row['is_enabled'] == true,
  );
}

class HpjInviteLead {
  final String id;
  final String creatorId;
  final String audience;
  final String name;
  final String organization;
  final String phone;
  final String status;
  final String consentSource;
  final DateTime? updatedAt;

  const HpjInviteLead({
    required this.id,
    required this.creatorId,
    required this.audience,
    required this.name,
    required this.organization,
    required this.phone,
    required this.status,
    required this.consentSource,
    required this.updatedAt,
  });

  bool get optedOut => status == 'opted_out';

  factory HpjInviteLead.fromRow(Map<String, dynamic> row) => HpjInviteLead(
    id: (row['id'] ?? '').toString(),
    creatorId: (row['created_by'] ?? '').toString(),
    audience: (row['audience'] ?? 'customer').toString(),
    name: (row['contact_name'] ?? '').toString(),
    organization: (row['organization'] ?? '').toString(),
    phone: (row['phone_e164'] ?? '').toString(),
    status: (row['status'] ?? 'draft').toString(),
    consentSource: (row['consent_source'] ?? '').toString(),
    updatedAt: parseProductDate(row['updated_at']),
  );
}

class HpjInviteGrowthShortcut extends StatelessWidget {
  final String audience;
  const HpjInviteGrowthShortcut({super.key, required this.audience});

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    color: FarmColors.card,
    child: ListTile(
      leading: const Icon(Icons.person_add_alt_1_rounded, color: FarmColors.primary),
      title: Text('Invite a ${_hpjInviteAudienceLabel(audience)}',
        style: const TextStyle(fontWeight: FontWeight.w900)),
      subtitle: const Text('Personal invitation • WhatsApp • share flyer'),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => Navigator.of(context).push<void>(
        MaterialPageRoute<void>(builder: (_) =>
          HpjInviteGrowScreen(initialAudience: audience)),
      ),
    ),
  );
}

class HpjInviteGrowScreen extends StatefulWidget {
  final String initialAudience;
  final bool adminMode;
  const HpjInviteGrowScreen({
    super.key,
    this.initialAudience = 'customer',
    this.adminMode = false,
  });

  @override
  State<HpjInviteGrowScreen> createState() => _HpjInviteGrowScreenState();
}

class _HpjInviteGrowScreenState extends State<HpjInviteGrowScreen> {
  final _name = TextEditingController();
  final _organization = TextEditingController();
  final _phone = TextEditingController();
  final _source = TextEditingController();
  final _notes = TextEditingController();
  final _message = TextEditingController();
  final _flyerKey = GlobalKey();
  final Map<String, HpjInviteTemplate> _templates = {};
  List<HpjInviteLead> _history = const [];
  String _audience = 'customer';
  String _campaignImage = '';
  String? _error;
  HpjInviteLead? _lead;
  bool _loading = true;
  bool _busy = false;
  bool _consent = false;
  bool _editedMessage = false;

  HpjInviteTemplate? get _template => _templates[_audience];

  @override
  void initState() {
    super.initState();
    _audience = _hpjInviteAudiences.contains(widget.initialAudience)
        ? widget.initialAudience : 'customer';
    _load();
  }

  @override
  void dispose() {
    _name.dispose(); _organization.dispose(); _phone.dispose();
    _source.dispose(); _notes.dispose(); _message.dispose();
    super.dispose();
  }

  Future<void> _checkAccess() async {
    if (supabase.auth.currentUser == null) {
      throw Exception('Sign in before creating an invitation.');
    }
    if (widget.adminMode) {
      await requireAdminAccess();
      final role = normalizeStaffRole(await fetchCurrentStaffRole());
      if (role != 'owner' && role != 'manager') {
        throw Exception('Only Owner and Manager can manage all invitations.');
      }
    } else if (_audience == 'business') {
      final account = await fetchCurrentBusinessAccount();
      if (account == null || !account.isApproved) {
        throw Exception('An approved Business account is required.');
      }
    } else if (_audience == 'farmer') {
      final profile = await fetchCurrentFarmerProfile();
      if (profile == null || !profile.isApproved) {
        throw Exception('An approved Farmer account is required.');
      }
    }
  }

  Future<void> _load() async {
    try {
      await _checkAccess();
      final rows = await supabase.from('hpj_invite_templates')
          .select('audience,headline,message_template,image_url,destination_url,is_enabled');
      final values = <String,HpjInviteTemplate>{};
      for (final raw in rows as List) {
        final item = HpjInviteTemplate.fromRow(Map<String,dynamic>.from(raw as Map));
        values[item.audience] = item;
      }
      final leads = await supabase.from('hpj_invite_leads')
          .select('id,created_by,audience,contact_name,organization,phone_e164,status,consent_source,updated_at')
          .order('updated_at', ascending: false).limit(100);
      final campaign = await hpjFetchShareCampaign();
      if (!mounted) return;
      setState(() {
        _templates..clear()..addAll(values);
        _history = (leads as List).map((item) => HpjInviteLead.fromRow(
          Map<String,dynamic>.from(item as Map))).toList(growable: false);
        _campaignImage = campaign?.imageUrl ?? '';
        _error = null;
        _loading = false;
      });
      _updateMessage();
    } catch (error) {
      if (mounted) setState(() {
        _error = 'Could not open Invite & Grow: $error\n\nRun HPJ_INVITE_GROW.sql and check your account access.';
        _loading = false;
      });
    }
  }

  String get _destination {
    final raw = _template?.destinationUrl ?? hpjSharePlayUrl;
    return hpjShareSafeDestination(raw);
  }

  String _compose() {
    final first = _hpjInviteFirstName(_name.text);
    final person = first.isEmpty ? 'there' : first;
    final organization = _organization.text.trim().isNotEmpty
        ? _organization.text.trim()
        : _audience == 'farmer' ? 'your farm'
          : _audience == 'business' ? 'your business' : 'you';
    return (_template?.body ?? '')
        .replaceAll(r'\n', '\n')
        .replaceAll('{first_name}', person)
        .replaceAll('{organization}', organization)
        .replaceAll('{inviter}', _hpjInviteSenderName())
        .replaceAll('{link}', _destination);
  }

  void _updateMessage() {
    if (_editedMessage || !mounted) return;
    _message.text = _compose();
  }

  void _switchAudience(String audience) {
    if (audience == _audience) return;
    setState(() {
      _audience = audience;
      _lead = null;
      _name.clear(); _organization.clear(); _phone.clear();
      _source.clear(); _notes.clear();
      _consent = false;
      _editedMessage = false;
    });
    _updateMessage();
  }

  void _notice(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _saveContact() async {
    if (_busy || _template?.enabled != true) return;
    final user = supabase.auth.currentUser;
    final phone = _hpjInviteNormalizePhone(_phone.text);
    if (user == null || _name.text.trim().length < 2 || phone.isEmpty ||
        !_consent || _source.text.trim().length < 4 ||
        _message.text.trim().length < 10) {
      _notice('Enter a name, international WhatsApp number, consent source and confirm permission.');
      return;
    }
    setState(() => _busy = true);
    try {
      // Never upsert an opted-out contact: an existing record is checked first.
      final existing = await supabase.from('hpj_invite_leads')
          .select('id,created_by,audience,contact_name,organization,phone_e164,status,consent_source,updated_at')
          .eq('created_by', user.id).eq('audience', _audience)
          .eq('phone_e164', phone).maybeSingle();
      if (existing != null && existing['status'] == 'opted_out') {
        throw Exception('This contact opted out. Do not send further invitations.');
      }
      final fields = <String,dynamic>{
        'contact_name': _name.text.trim(),
        'organization': _organization.text.trim(),
        'phone_e164': phone,
        'consent_source': _source.text.trim(),
        'consent_at': DateTime.now().toUtc().toIso8601String(),
        'message_snapshot': _message.text.trim(),
        'notes': _notes.text.trim(),
      };
      final Map<String,dynamic> saved;
      if (existing == null) {
        saved = Map<String,dynamic>.from(await supabase.from('hpj_invite_leads')
          .insert({...fields, 'created_by': user.id, 'audience': _audience})
          .select('id,created_by,audience,contact_name,organization,phone_e164,status,consent_source,updated_at')
          .single());
      } else {
        saved = Map<String,dynamic>.from(await supabase.from('hpj_invite_leads')
          .update(fields).eq('id', existing['id'] as String)
          .select('id,created_by,audience,contact_name,organization,phone_e164,status,consent_source,updated_at')
          .single());
      }
      if (!mounted) return;
      setState(() => _lead = HpjInviteLead.fromRow(saved));
      _notice('Contact saved. Review the invitation before opening WhatsApp.');
      await _refreshHistory();
    } catch (error) {
      _notice('Could not save invitation: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _refreshHistory() async {
    try {
      final rows = await supabase.from('hpj_invite_leads')
        .select('id,created_by,audience,contact_name,organization,phone_e164,status,consent_source,updated_at')
        .order('updated_at', ascending: false).limit(100);
      if (mounted) setState(() => _history = (rows as List)
        .map((row) => HpjInviteLead.fromRow(Map<String,dynamic>.from(row as Map)))
        .toList(growable: false));
    } catch (error) { _notice('Invitation history could not refresh: $error'); }
  }

  Future<void> _setStatus(String status) async {
    final lead = _lead;
    if (lead == null || lead.optedOut || _busy) return;
    setState(() => _busy = true);
    try {
      final values = <String,dynamic>{'status': status};
      if (status == 'opted_out') {
        values['opted_out_at'] = DateTime.now().toUtc().toIso8601String();
      }
      await supabase.from('hpj_invite_leads').update(values).eq('id',lead.id);
      if (!mounted) return;
      setState(() => _lead = HpjInviteLead(
        id:lead.id, creatorId:lead.creatorId, audience:lead.audience,
        name:lead.name, organization:lead.organization, phone:lead.phone,
        status:status, consentSource:lead.consentSource, updatedAt:DateTime.now()));
      _notice(status == 'sent' ? 'Marked sent by you. Delivery is not verified.'
        : status == 'reported_joined' ? 'Manually marked as joined; not verified by signup data.'
        : status == 'opted_out' ? 'Do-not-contact status saved.' : 'Invitation status updated.');
      await _refreshHistory();
    } catch (error) { _notice('Could not update invitation: $error'); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _openWhatsApp() async {
    final lead = _lead;
    if (lead == null || lead.optedOut || !_consent || _busy) return;
    final phone = _hpjInviteNormalizePhone(_phone.text);
    if (phone != lead.phone || _message.text.trim().isEmpty) {
      _notice('Save the latest number and message before opening WhatsApp.');
      return;
    }
    final url = Uri.https('wa.me','/${phone.substring(1)}',
      <String,String>{'text': _message.text.trim()});
    // Start the browser intent directly from the tap, BEFORE any await/DB call.
    final opening = openExternalShareUrl(url.toString());
    setState(() => _busy = true);
    try {
      final opened = await opening;
      if (!opened) { _notice('WhatsApp could not open. Copy the message instead.'); return; }
      if (lead.status == 'draft' || lead.status == 'opened') {
        await supabase.from('hpj_invite_leads').update({
          'status': 'opened',
          'last_opened_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('id',lead.id).inFilter('status', <String>['draft','opened']);
        if (mounted) setState(() => _lead = HpjInviteLead(
          id:lead.id,creatorId:lead.creatorId,audience:lead.audience,
          name:lead.name,organization:lead.organization,phone:lead.phone,
          status:'opened',consentSource:lead.consentSource,updatedAt:DateTime.now()));
      }
      _notice('WhatsApp opened. Review and send there; then mark Sent here.');
      await _refreshHistory();
    } catch (error) { _notice('WhatsApp could not open: $error'); }
    finally { if (mounted) setState(() => _busy = false); }
  }

  Future<void> _shareFlyer({bool imageOnly = false}) async {
    if (_busy || _template?.enabled != true) return;
    if (_lead == null || _lead!.optedOut || !_consent) {
      _notice('Save this contact’s permission before sharing a personal invitation.');
      return;
    }
    final message = _message.text.trim();
    if (message.isEmpty) { _notice('Compose an invitation first.'); return; }
    setState(() => _busy = true);
    try {
      XFile imageFile;
      try {
        final boundary = _flyerKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
        if (boundary == null) throw StateError('Flyer preview unavailable');
        final captured = await boundary.toImage(pixelRatio: 2);
        final data = await captured.toByteData(format: ImageByteFormat.png);
        captured.dispose();
        if (data == null) throw StateError('Flyer could not be rendered');
        imageFile = XFile.fromData(
          data.buffer.asUint8List(data.offsetInBytes,data.lengthInBytes),
          mimeType: 'image/png', name: 'hpj-${_audience}-invitation.png');
      } catch (error) {
        farmDebugLog('Named invitation rendering unavailable, sharing campaign artwork: $error');
        final image = _template?.imageUrl.isNotEmpty == true
          ? _template!.imageUrl : _campaignImage;
        imageFile = await hpjPrepareSharePhoto(image, 'hpj-${_audience}-invitation');
      }
      await SharePlus.instance.share(ShareParams(
        files: <XFile>[imageFile],
        fileNameOverrides: <String>[imageFile.name],
        text: imageOnly ? null : message,
        title: 'The Harvest Place Ja Invitation',
        sharePositionOrigin: hpjShareOrigin(context),
        downloadFallbackEnabled: true,
      ));
      _notice(imageOnly ? 'Select Save to Files or a supported save destination.'
        : 'Share sheet opened. Confirm the image, caption and recipient in WhatsApp.');
    } catch (error) {
      await Clipboard.setData(ClipboardData(text:message));
      _notice('Image sharing unavailable. Invitation text copied: $error');
    } finally { if (mounted) setState(() => _busy = false); }
  }

  Widget _flyer() {
    final photo = cleanHostedImageUrl(_template?.imageUrl.isNotEmpty == true
        ? _template!.imageUrl : _campaignImage);
    final first = _hpjInviteFirstName(_name.text);
    return Container(
      width: double.infinity, height: 246,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(colors:[Color(0xFF123E2A),Color(0xFF266B43)]),
      ),
      child: Stack(fit: StackFit.expand, children: [
        if (photo != null) Image.network(photo,fit:BoxFit.cover,
          errorBuilder:(_,__,___)=>const SizedBox.shrink()),
        const DecoratedBox(decoration:BoxDecoration(gradient:LinearGradient(
          begin:Alignment.topCenter,end:Alignment.bottomCenter,
          colors:[Color(0xE0103022),Color(0xF2113725)]))),
        Padding(padding:const EdgeInsets.all(16),child:Column(
          crossAxisAlignment:CrossAxisAlignment.start, children:[
            Row(children:[
              Container(width:43,height:43,padding:const EdgeInsets.all(3),
                decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(10)),
                child:Image.asset('lib/assets/images/logo.png',fit:BoxFit.contain)),
              const SizedBox(width:9),
              const Expanded(child:Text('THE HARVEST PLACE JA',maxLines:2,
                style:TextStyle(color:Colors.white,fontWeight:FontWeight.w900,fontSize:13))),
            ]),
            const Spacer(),
            const Text('A PERSONAL INVITATION',style:TextStyle(
              color:Color(0xFFF4D375),fontSize:10,letterSpacing:1,fontWeight:FontWeight.w900)),
            const SizedBox(height:5),
            Text('You are invited${first.isEmpty ? '' : ', $first'}!',
              maxLines:2,overflow:TextOverflow.ellipsis,
              style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w900,fontSize:25)),
            const SizedBox(height:5),
            Text(_template?.headline ?? 'Discover HPJ',maxLines:2,
              style:const TextStyle(color:Colors.white,fontSize:12,fontWeight:FontWeight.w700)),
            const SizedBox(height:9),
            const Text('FRESH • LOCAL • JAMAICAN',style:TextStyle(
              color:Color(0xFFF4D375),fontWeight:FontWeight.w900,fontSize:10)),
          ],
        )),
      ]),
    );
  }

  void _newContact() {
    setState(() {
      _lead=null; _consent=false; _editedMessage=false;
      _name.clear();_organization.clear();_phone.clear();_source.clear();_notes.clear();
    });
    _updateMessage();
  }

  void _loadLead(HpjInviteLead item) {
    setState(() {
      _audience=item.audience;
      _lead=item;
      _name.text=item.name;
      _organization.text=item.organization;
      _phone.text=item.phone;
      _source.text=item.consentSource;
      _notes.clear();
      _consent=!item.optedOut;
      _editedMessage=false;
    });
    _updateMessage();
  }

  Widget _historyCard(HpjInviteLead item) {
    return Card(child:ListTile(
      title:Text('${item.name} • ${_hpjInviteAudienceLabel(item.audience)}',
        maxLines:1,overflow:TextOverflow.ellipsis),
      subtitle:Text('${item.phone}  |  ${item.status.replaceAll('_',' ')}',
        maxLines:2),
      trailing:const Icon(Icons.chevron_right_rounded),
      onTap:()=>_loadLead(item),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return Scaffold(appBar:AppBar(title:const Text('Invite & Grow')),
      body:const Center(child:CircularProgressIndicator()));
    if (_error != null) return Scaffold(appBar:AppBar(title:const Text('Invite & Grow')),
      body:ListView(padding:const EdgeInsets.all(22),children:[
        Text(_error!,style:const TextStyle(color:FarmColors.danger)),
        const SizedBox(height:12),
        OutlinedButton(onPressed:(){setState(()=>_loading=true);_load();},
          child:const Text('Try again')),
      ]));
    final template=_template;
    final filtered=_history.where((row)=>row.audience==_audience).toList();
    final canSend=template?.enabled == true && _lead != null &&
      _lead!.status != 'opted_out' && _consent && !_busy;
    return Scaffold(
      backgroundColor:FarmColors.background,
      appBar:AppBar(
        title:const Text('Invite & Grow'),
        actions: [
          if(widget.adminMode) IconButton(
            tooltip:'Edit invitation templates',
            icon:const Icon(Icons.edit_note_rounded),
            onPressed:()=>Navigator.of(context).push<void>(
              MaterialPageRoute<void>(builder:(_)=>const HpjInviteTemplateEditor()))
              .then((_){ if(mounted){setState(()=>_loading=true);_load();} }),
          ),
          IconButton(tooltip:'New invitation',icon:const Icon(Icons.add_rounded),
            onPressed:_newContact),
        ],
      ),
      body:ListView(padding:const EdgeInsets.fromLTRB(15,16,15,120),children:[
        const Text('Personal invitations',style:TextStyle(
          fontSize:23,color:FarmColors.deepGreen,fontWeight:FontWeight.w900)),
        const SizedBox(height:4),
        const Text('One contact at a time. You choose the recipient and press Send in WhatsApp.',
          style:TextStyle(color:FarmColors.mutedText)),
        const SizedBox(height:14),
        if(widget.adminMode) Wrap(spacing:8,runSpacing:6,children:[
          for(final item in _hpjInviteAudiences)
            ChoiceChip(label:Text(_hpjInviteAudienceLabel(item)),selected:_audience==item,
              onSelected:(_)=>_switchAudience(item)),
        ]),
        if(widget.adminMode) const SizedBox(height:12),
        if(template==null || !template.enabled)
          const Card(child:Padding(padding:EdgeInsets.all(16),
            child:Text('This invitation type is unavailable. Ask Admin to enable its template.')))
        else ...[
          RepaintBoundary(key:_flyerKey,child:_flyer()),
          const SizedBox(height:12),
          Text(template.headline,style:const TextStyle(fontSize:18,
            color:FarmColors.deepGreen,fontWeight:FontWeight.w900)),
          const SizedBox(height:12),
          TextField(controller:_name,maxLength:120,
            enabled:_lead==null,onChanged:(_){setState((){});_updateMessage();},
            decoration:const InputDecoration(labelText:'Contact name *',
              border:OutlineInputBorder(),prefixIcon:Icon(Icons.person_outline))),
          if(_audience!='customer') ...[
            const SizedBox(height:7),
            TextField(controller:_organization,maxLength:140,
              enabled:_lead==null,onChanged:(_){setState((){});_updateMessage();},
              decoration:InputDecoration(
                labelText:_audience=='farmer' ? 'Farm name (optional)' : 'Business name (optional)',
                border:const OutlineInputBorder(),prefixIcon:const Icon(Icons.business_outlined))),
          ],
          const SizedBox(height:7),
          TextField(controller:_phone,enabled:_lead==null,
            keyboardType:TextInputType.phone,
            decoration:const InputDecoration(labelText:'WhatsApp number with country code *',
              hintText:'+1876XXXXXXX',border:OutlineInputBorder(),
              prefixIcon:Icon(Icons.phone_outlined))),
          const SizedBox(height:7),
          TextField(controller:_source,maxLength:300,enabled:_lead==null,
            decoration:const InputDecoration(labelText:'Where they agreed to receive the invitation *',
              hintText:'Requested it at market / during our call',
              border:OutlineInputBorder(),prefixIcon:Icon(Icons.verified_user_outlined))),
          const SizedBox(height:7),
          TextField(controller:_notes,maxLength:500,enabled:_lead==null,
            maxLines:2,decoration:const InputDecoration(
              labelText:'Private notes (optional)',border:OutlineInputBorder())),
          const SizedBox(height:10),
          CheckboxListTile(
            contentPadding:EdgeInsets.zero,
            title:const Text('They explicitly agreed to receive this HPJ invitation',
              style:TextStyle(fontWeight:FontWeight.w800,fontSize:13)),
            subtitle:const Text('A phone number alone is not marketing permission.'),
            value:_consent && _lead?.optedOut != true,
            onChanged:_lead?.optedOut == true || _busy ? null :
              (value)=>setState(()=>_consent=value==true),
          ),
          const SizedBox(height:8),
          TextField(controller:_message,maxLength:2500,maxLines:10,minLines:6,
            onChanged:(_)=>_editedMessage=true,
            decoration:const InputDecoration(labelText:'Review / edit invitation message',
              border:OutlineInputBorder(),alignLabelWithHint:true)),
          const SizedBox(height:8),
          if(_lead==null) FilledButton.icon(
            onPressed:_busy || !_consent ? null : _saveContact,
            icon:const Icon(Icons.save_outlined),
            label:const Text('Save consent & prepare invitation')),
          if(_lead!=null) ...[
            Card(color:_lead!.optedOut ? const Color(0xFFFFECEB) :
                const Color(0xFFEAF5EC),child:Padding(padding:const EdgeInsets.all(12),
              child:Text('Invitation record: ${_lead!.status.replaceAll('_',' ')}${_lead!.optedOut ? ' — DO NOT CONTACT' : ''}',
                style:const TextStyle(fontWeight:FontWeight.w800)))),
            FilledButton.icon(onPressed:canSend ? _openWhatsApp:null,
              icon:const Icon(Icons.message_outlined),
              label:const Text('Open personalized WhatsApp chat')),
          ],
          const SizedBox(height:7),
          OutlinedButton.icon(onPressed:canSend ? ()=>_shareFlyer() : null,
            icon:const Icon(Icons.ios_share_rounded),
            label:const Text('Share personalized invitation image')),
          OutlinedButton.icon(onPressed:canSend ? ()=>_shareFlyer(imageOnly:true) : null,
            icon:const Icon(Icons.save_alt_rounded),
            label:const Text('Save image / device share sheet')),
          TextButton.icon(onPressed:canSend ? ()=>Clipboard.setData(
              ClipboardData(text:_message.text.trim())).then((_){_notice('Invitation copied.');}) : null,
            icon:const Icon(Icons.copy_rounded),label:const Text('Copy invitation text')),
          if(_lead!=null && !_lead!.optedOut) ...[
            const Divider(height:24),
            Wrap(spacing:8,runSpacing:6,children:[
              OutlinedButton(onPressed:_busy ? null :()=>_setStatus('sent'),
                child:const Text('Mark sent (manual)')),
              OutlinedButton(onPressed:_busy ? null :()=>_setStatus('follow_up'),
                child:const Text('Follow up')),
              OutlinedButton(onPressed:_busy ? null :()=>_setStatus('reported_joined'),
                child:const Text('Reported joined')),
              OutlinedButton(onPressed:_busy ? null :()=>_setStatus('opted_out'),
                child:const Text('Do not contact')),
            ]),
          ],
          const SizedBox(height:6),
          const Text('WhatsApp opens a draft, not an automatic send. Image captions may not be retained by WhatsApp. Saving uses your device share/save options. "Joined" is staff-reported, not verified signup attribution.',
            style:TextStyle(fontSize:11,color:FarmColors.mutedText,height:1.4)),
        ],
        const Divider(height:35),
        Row(children:[
          Expanded(child:Text('Invitation history (${filtered.length})',
            style:const TextStyle(fontSize:16,fontWeight:FontWeight.w900))),
          IconButton(tooltip:'Refresh history',onPressed:_refreshHistory,
            icon:const Icon(Icons.refresh_rounded)),
        ]),
        if(filtered.isEmpty) const Text('No saved invitations for this audience yet.'),
        for(final row in filtered.take(30)) _historyCard(row),
      ]),
    );
  }
}

class HpjInviteTemplateEditor extends StatefulWidget {
  const HpjInviteTemplateEditor({super.key});
  @override
  State<HpjInviteTemplateEditor> createState()=>_HpjInviteTemplateEditorState();
}

class _HpjInviteTemplateEditorState extends State<HpjInviteTemplateEditor> {
  final _headline=TextEditingController();
  final _body=TextEditingController();
  final _image=TextEditingController();
  final _link=TextEditingController();
  final Map<String,HpjInviteTemplate> _templates={};
  String _audience='customer';
  String? _error;
  bool _enabled=true, _busy=false, _loading=true;

  @override
  void initState(){super.initState();_load();}
  @override
  void dispose(){_headline.dispose();_body.dispose();_image.dispose();_link.dispose();super.dispose();}

  Future<void> _load() async {
    try {
      await requireAdminAccess();
      final role=normalizeStaffRole(await fetchCurrentStaffRole());
      if(role!='owner' && role!='manager') throw Exception('Owner/Manager only.');
      final rows=await supabase.from('hpj_invite_templates').select(
        'audience,headline,message_template,image_url,destination_url,is_enabled');
      if(!mounted)return;
      _templates.clear();
      for(final raw in rows as List){
        final item=HpjInviteTemplate.fromRow(Map<String,dynamic>.from(raw as Map));
        _templates[item.audience]=item;
      }
      _select(_audience);
      setState((){_loading=false;_error=null;});
    }catch(error){if(mounted)setState((){_loading=false;_error='$error';});}
  }

  void _select(String audience){
    final item=_templates[audience];
    setState((){
      _audience=audience;
      _headline.text=item?.headline ?? '';
      _body.text=(item?.body ?? '').replaceAll(r'\n','\n');
      _image.text=item?.imageUrl ?? '';
      _link.text=item?.destinationUrl ?? hpjSharePlayUrl;
      _enabled=item?.enabled ?? false;
    });
  }

  Future<void> _useCampaignImage() async {
    final campaign=await hpjFetchShareCampaign();
    if(!mounted)return;
    if(campaign==null || campaign.imageUrl.isEmpty){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content:Text('Publish a marketing image in Admin → Marketing first.')));
      return;
    }
    setState(()=>_image.text=campaign.imageUrl);
  }

  Future<void> _save() async {
    final dest=Uri.tryParse(_link.text.trim());
    final photo=_image.text.trim();
    final imageUri=Uri.tryParse(photo);
    if(_headline.text.trim().isEmpty || _body.text.trim().length<10 ||
       dest==null || dest.scheme!='https' || dest.host.isEmpty ||
       (photo.isNotEmpty && (imageUri==null || imageUri.scheme!='https' || imageUri.host.isEmpty))){
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content:Text('Enter a headline, message and valid HTTPS links.')));
      return;
    }
    setState(()=>_busy=true);
    try {
      await requireAdminAccess();
      await supabase.from('hpj_invite_templates').update({
        'headline':_headline.text.trim(),
        'message_template':_body.text.trim(),
        'image_url':photo,
        'destination_url':dest.toString(),
        'is_enabled':_enabled,
        'updated_by':supabase.auth.currentUser?.id,
      }).eq('audience',_audience);
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content:Text('Invitation template saved. Reopen Invite & Grow to see changes.')));
    }catch(error){if(mounted)ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content:Text('Template save failed: $error')));}
    finally{if(mounted)setState(()=>_busy=false);}
  }

  @override
  Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Invitation templates')),
    body:_loading?const Center(child:CircularProgressIndicator()):
      _error!=null?Center(child:Text(_error!)):
      ListView(padding:const EdgeInsets.fromLTRB(17,20,17,100),children:[
        const Text('Admin-managed invitation templates',style:TextStyle(
          fontSize:20,fontWeight:FontWeight.w900,color:FarmColors.deepGreen)),
        const SizedBox(height:12),
        Wrap(spacing:8,children:[
          for(final item in _hpjInviteAudiences) ChoiceChip(
            label:Text(_hpjInviteAudienceLabel(item)),selected:_audience==item,
            onSelected:(_)=>_select(item)),
        ]),
        const SizedBox(height:15),
        TextField(controller:_headline,maxLength:90,
          decoration:const InputDecoration(labelText:'Flyer headline',border:OutlineInputBorder())),
        TextField(controller:_body,minLines:7,maxLines:12,maxLength:2000,
          decoration:const InputDecoration(labelText:'Message template',
            helperText:'Available: {first_name}, {organization}, {inviter}, {link}',
            border:OutlineInputBorder(),alignLabelWithHint:true)),
        TextField(controller:_link,keyboardType:TextInputType.url,
          decoration:const InputDecoration(labelText:'HTTPS registration / app link',
            border:OutlineInputBorder())),
        TextField(controller:_image,keyboardType:TextInputType.url,
          decoration:const InputDecoration(labelText:'Optional HTTPS flyer image URL',
            border:OutlineInputBorder())),
        OutlinedButton.icon(onPressed:_useCampaignImage,
          icon:const Icon(Icons.photo_library_outlined),
          label:const Text('Use published HPJ marketing image')),
        SwitchListTile.adaptive(title:const Text('Enable invitations for this audience'),
          value:_enabled,onChanged:_busy?null:(value)=>setState(()=>_enabled=value)),
        FilledButton.icon(onPressed:_busy?null:_save,icon:const Icon(Icons.save_outlined),
          label:Text(_busy?'Saving…':'Save template')),
        const SizedBox(height:12),
        const Text('Use verified destination links only. Until separate Business and Farmer landing pages are deployed, the prefilled link opens the existing HPJ app listing.',
          style:TextStyle(color:FarmColors.mutedText,fontSize:12)),
      ]),
  );
}
