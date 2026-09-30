// HPJ INVITE & GROW — opt-in Customer, Business and Farmer invitations.
// This file is a PART, not a standalone library. Add its part line to lib/main.dart.
// No automated WhatsApp sending. Opening a chat is not proof of delivery.
part of harvest_place_app;

const List<String> _hpjInviteAudiences = <String>[
  'customer',
  'business',
  'farmer'
];

String _hpjInviteAudienceLabel(String value) {
  switch (value) {
    case 'business':
      return 'Business';
    case 'farmer':
      return 'Farmer';
    default:
      return 'Customer';
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

  factory HpjInviteTemplate.fromRow(Map<String, dynamic> row) =>
      HpjInviteTemplate(
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
          leading: const Icon(Icons.person_add_alt_1_rounded,
              color: FarmColors.primary),
          title: Text('Invite a ${_hpjInviteAudienceLabel(audience)}',
              style: const TextStyle(fontWeight: FontWeight.w900)),
          subtitle: const Text('Personal invitation • WhatsApp • share flyer'),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
                builder: (_) => HpjInviteGrowScreen(initialAudience: audience)),
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
        ? widget.initialAudience
        : 'customer';
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _organization.dispose();
    _phone.dispose();
    _source.dispose();
    _notes.dispose();
    _message.dispose();
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
      final rows = await supabase.from('hpj_invite_templates').select(
          'audience,headline,message_template,image_url,destination_url,is_enabled');
      final values = <String, HpjInviteTemplate>{};
      for (final raw in rows as List) {
        final item =
            HpjInviteTemplate.fromRow(Map<String, dynamic>.from(raw as Map));
        values[item.audience] = item;
      }
      final leads = await supabase
          .from('hpj_invite_leads')
          .select(
              'id,created_by,audience,contact_name,organization,phone_e164,status,consent_source,updated_at')
          .order('updated_at', ascending: false)
          .limit(100);
      final campaign = await hpjFetchShareCampaign();
      if (!mounted) return;
      setState(() {
        _templates
          ..clear()
          ..addAll(values);
        _history = (leads as List)
            .map((item) =>
                HpjInviteLead.fromRow(Map<String, dynamic>.from(item as Map)))
            .toList(growable: false);
        _campaignImage = campaign?.imageUrl ?? '';
        _error = null;
        _loading = false;
      });
      _updateMessage();
    } catch (error) {
      if (mounted)
        setState(() {
          _error =
              'Could not open Invite & Grow: $error\n\nRun HPJ_INVITE_GROW.sql and check your account access.';
          _loading = false;
        });
    }
  }

  String get _destination {
    switch (_audience) {
      case 'business':
        return 'https://harvestplaceja.com/business';
      case 'farmer':
        return 'https://harvestplaceja.com/farmer';
      default:
        return 'https://harvestplaceja.com/customer';
    }
  }

  String _compose() {
    final first = _hpjInviteFirstName(_name.text);
    final greeting = first.isEmpty ? 'Hi!' : 'Hi $first!';
    final destination = _destination;
    final appLink = hpjSharePlayUrl;

    switch (_audience) {
      case 'business':
        return [
          '$greeting 👋',
          '',
          'Source fresh Jamaican produce with The Harvest Place Ja (HPJ).',
          '',
          '🌿 Connect with trusted local farmers',
          '📦 Post what your business needs',
          '🚚 Manage orders and collections',
          '',
          '🏢 Business signup:',
          destination,
          '',
          '📱 Download the HPJ app:',
          appLink,
          '',
          'Fresh • Local • Jamaican 🇯🇲',
        ].join('\n');

      case 'farmer':
        return [
          '$greeting 👋',
          '',
          'Grow your farm business with The Harvest Place Ja (HPJ).',
          '',
          '🌿 Join as a trusted local farmer',
          '📦 List produce and update availability',
          '🚚 Manage collections and payouts',
          '',
          '🌾 Farmer signup:',
          destination,
          '',
          '📱 Download the HPJ app:',
          appLink,
          '',
          'Fresh • Local • Jamaican 🇯🇲',
        ].join('\n');

      default:
        return [
          '$greeting 👋',
          '',
          'Shop fresh Jamaican produce with The Harvest Place Ja (HPJ).',
          '',
          '🌿 Buy fresh local produce',
          '📦 Build your box or order what you need',
          '🚚 Choose delivery or pickup',
          '',
          '🛒 Customer signup:',
          destination,
          '',
          '📱 Download the HPJ app:',
          appLink,
          '',
          'Fresh • Local • Jamaican 🇯🇲',
        ].join('\n');
    }
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
      _name.clear();
      _organization.clear();
      _phone.clear();
      _source.clear();
      _notes.clear();
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
    if (user == null ||
        _name.text.trim().length < 2 ||
        phone.isEmpty ||
        !_consent ||
        _source.text.trim().length < 4 ||
        _message.text.trim().length < 10) {
      _notice(
          'Enter a name, international WhatsApp number, consent source and confirm permission.');
      return;
    }
    setState(() => _busy = true);
    try {
      // Never upsert an opted-out contact: an existing record is checked first.
      final existing = await supabase
          .from('hpj_invite_leads')
          .select(
              'id,created_by,audience,contact_name,organization,phone_e164,status,consent_source,updated_at')
          .eq('created_by', user.id)
          .eq('audience', _audience)
          .eq('phone_e164', phone)
          .maybeSingle();
      if (existing != null && existing['status'] == 'opted_out') {
        throw Exception(
            'This contact opted out. Do not send further invitations.');
      }
      final fields = <String, dynamic>{
        'contact_name': _name.text.trim(),
        'organization': _organization.text.trim(),
        'phone_e164': phone,
        'consent_source': _source.text.trim(),
        'consent_at': DateTime.now().toUtc().toIso8601String(),
        'message_snapshot': _message.text.trim(),
        'notes': _notes.text.trim(),
      };
      final Map<String, dynamic> saved;
      if (existing == null) {
        saved = Map<String, dynamic>.from(await supabase
            .from('hpj_invite_leads')
            .insert({...fields, 'created_by': user.id, 'audience': _audience})
            .select(
                'id,created_by,audience,contact_name,organization,phone_e164,status,consent_source,updated_at')
            .single());
      } else {
        saved = Map<String, dynamic>.from(await supabase
            .from('hpj_invite_leads')
            .update(fields)
            .eq('id', existing['id'] as String)
            .select(
                'id,created_by,audience,contact_name,organization,phone_e164,status,consent_source,updated_at')
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
      final rows = await supabase
          .from('hpj_invite_leads')
          .select(
              'id,created_by,audience,contact_name,organization,phone_e164,status,consent_source,updated_at')
          .order('updated_at', ascending: false)
          .limit(100);
      if (mounted)
        setState(() => _history = (rows as List)
            .map((row) =>
                HpjInviteLead.fromRow(Map<String, dynamic>.from(row as Map)))
            .toList(growable: false));
    } catch (error) {
      _notice('Invitation history could not refresh: $error');
    }
  }

  Future<void> _setStatus(String status) async {
    final lead = _lead;
    if (lead == null || lead.optedOut || _busy) return;
    setState(() => _busy = true);
    try {
      final values = <String, dynamic>{'status': status};
      if (status == 'opted_out') {
        values['opted_out_at'] = DateTime.now().toUtc().toIso8601String();
      }
      await supabase.from('hpj_invite_leads').update(values).eq('id', lead.id);
      if (!mounted) return;
      setState(() => _lead = HpjInviteLead(
          id: lead.id,
          creatorId: lead.creatorId,
          audience: lead.audience,
          name: lead.name,
          organization: lead.organization,
          phone: lead.phone,
          status: status,
          consentSource: lead.consentSource,
          updatedAt: DateTime.now()));
      _notice(status == 'sent'
          ? 'Marked sent by you. Delivery is not verified.'
          : status == 'reported_joined'
              ? 'Manually marked as joined; not verified by signup data.'
              : status == 'opted_out'
                  ? 'Do-not-contact status saved.'
                  : 'Invitation status updated.');
      await _refreshHistory();
    } catch (error) {
      _notice('Could not update invitation: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openWhatsApp() async {
    final lead = _lead;
    if (lead == null || lead.optedOut || !_consent || _busy) return;
    final phone = _hpjInviteNormalizePhone(_phone.text);
    if (phone != lead.phone || _message.text.trim().isEmpty) {
      _notice('Save the latest number and message before opening WhatsApp.');
      return;
    }
    final url = Uri.https('wa.me', '/${phone.substring(1)}',
        <String, String>{'text': _message.text.trim()});
    // Start the browser intent directly from the tap, BEFORE any await/DB call.
    final opening = openExternalShareUrl(url.toString());
    setState(() => _busy = true);
    try {
      final opened = await opening;
      if (!opened) {
        _notice('WhatsApp could not open. Copy the message instead.');
        return;
      }
      if (lead.status == 'draft' || lead.status == 'opened') {
        await supabase
            .from('hpj_invite_leads')
            .update({
              'status': 'opened',
              'last_opened_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('id', lead.id)
            .inFilter('status', <String>['draft', 'opened']);
        if (mounted)
          setState(() => _lead = HpjInviteLead(
              id: lead.id,
              creatorId: lead.creatorId,
              audience: lead.audience,
              name: lead.name,
              organization: lead.organization,
              phone: lead.phone,
              status: 'opened',
              consentSource: lead.consentSource,
              updatedAt: DateTime.now()));
      }
      _notice('WhatsApp opened. Review and send there; then mark Sent here.');
      await _refreshHistory();
    } catch (error) {
      _notice('WhatsApp could not open: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _shareFlyer({bool imageOnly = false}) async {
    if (_busy || _template?.enabled != true) return;
    if (_lead == null || _lead!.optedOut || !_consent) {
      _notice(
          'Save this contact’s permission before sharing a personal invitation.');
      return;
    }
    final message = _message.text.trim();
    if (message.isEmpty) {
      _notice('Compose an invitation first.');
      return;
    }
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
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
            mimeType: 'image/png',
            name: 'hpj-${_audience}-invitation.png');
      } catch (error) {
        farmDebugLog(
            'Named invitation rendering unavailable, sharing campaign artwork: $error');
        final image = _template?.imageUrl.isNotEmpty == true
            ? _template!.imageUrl
            : _campaignImage;
        imageFile =
            await hpjPrepareSharePhoto(image, 'hpj-${_audience}-invitation');
      }
      await SharePlus.instance.share(ShareParams(
        files: <XFile>[imageFile],
        fileNameOverrides: <String>[imageFile.name],
        text: imageOnly ? null : message,
        title: 'The Harvest Place Ja Invitation',
        sharePositionOrigin: hpjShareOrigin(context),
        downloadFallbackEnabled: true,
      ));
      _notice(imageOnly
          ? 'Select Save to Files or a supported save destination.'
          : 'Share sheet opened. Confirm the image, caption and recipient in WhatsApp.');
    } catch (error) {
      await Clipboard.setData(ClipboardData(text: message));
      _notice('Image sharing unavailable. Invitation text copied: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String get _flyerHeadline {
    switch (_audience) {
      case 'business':
        return 'Business Signup';
      case 'farmer':
        return 'Farmer Signup';
      default:
        return 'Customer Signup';
    }
  }

  String get _flyerSubhead {
    switch (_audience) {
      case 'business':
        return 'Source fresh Jamaican produce and connect with trusted farmers.';
      case 'farmer':
        return 'Sell fresh Jamaican produce and connect with trusted buyers.';
      default:
        return 'Shop fresh Jamaican produce from trusted local farmers.';
    }
  }

  Widget _flyer() {
    final first = _hpjInviteFirstName(_name.text);
    final audienceLabel = _hpjInviteAudienceLabel(_audience);
    final destination = _destination;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FFF2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFDDE6DA),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 92,
                height: 92,
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: const Color(0xFFE2E9DE),
                  ),
                ),
                child: Image.asset(
                  'lib/assets/images/logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.eco_rounded,
                    color: FarmColors.primary,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'The Harvest Place Ja | $_flyerHeadline',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: FarmColors.ink,
                        fontSize: 16,
                        height: 1.08,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _flyerSubhead,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: FarmColors.mutedText,
                        fontSize: 10,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'harvestplaceja.com',
                      style: TextStyle(
                        color: FarmColors.mutedText,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (first.isNotEmpty) ...[
            const SizedBox(height: 11),
            Text(
              'For $first',
              style: const TextStyle(
                color: FarmColors.deepGreen,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFDDE6DA),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.link_rounded,
                  size: 17,
                  color: FarmColors.primary,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    destination,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: FarmColors.deepGreen,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Personal invitation for a ${audienceLabel.toLowerCase()}.',
            style: const TextStyle(
              color: FarmColors.mutedText,
              fontSize: 8.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _newContact() {
    setState(() {
      _lead = null;
      _consent = false;
      _editedMessage = false;
      _name.clear();
      _organization.clear();
      _phone.clear();
      _source.clear();
      _notes.clear();
    });
    _updateMessage();
  }

  void _loadLead(HpjInviteLead item) {
    setState(() {
      _audience = item.audience;
      _lead = item;
      _name.text = item.name;
      _organization.text = item.organization;
      _phone.text = item.phone;
      _source.text = item.consentSource;
      _notes.clear();
      _consent = !item.optedOut;
      _editedMessage = false;
    });
    _updateMessage();
  }

  Widget _historyCard(HpjInviteLead item) {
    final status = item.status.replaceAll('_', ' ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => _loadLead(item),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFE1E8DE),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF5E9),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Icon(
                    Icons.person_outline_rounded,
                    color: FarmColors.primary,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: FarmColors.ink,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_hpjInviteAudienceLabel(item.audience)} • $status',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: FarmColors.mutedText,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: FarmColors.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: FarmColors.background,
        appBar: AppBar(
          title: const Text('Invite & Grow'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: FarmColors.background,
        appBar: AppBar(
          title: const Text('Invite & Grow'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF4F2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: FarmColors.danger.withOpacity(.18),
                ),
              ),
              child: Text(
                _error!,
                style: const TextStyle(
                  color: FarmColors.danger,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                setState(() => _loading = true);
                _load();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      );
    }

    final template = _template;
    final filtered =
        _history.where((row) => row.audience == _audience).toList();

    final canSend = template?.enabled == true &&
        _lead != null &&
        _lead!.status != 'opted_out' &&
        _consent &&
        !_busy;

    final audienceLabel = _hpjInviteAudienceLabel(_audience);
    final title =
        widget.adminMode ? 'Invite & Grow' : 'Invite a $audienceLabel';

    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (widget.adminMode)
            IconButton(
              tooltip: 'Edit invitation templates',
              icon: const Icon(Icons.edit_note_rounded),
              onPressed: () => Navigator.of(context)
                  .push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => const HpjInviteTemplateEditor(),
                ),
              )
                  .then((_) {
                if (mounted) {
                  setState(() => _loading = true);
                  _load();
                }
              }),
            ),
          IconButton(
            tooltip: 'New invitation',
            icon: const Icon(Icons.add_rounded),
            onPressed: _newContact,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 120),
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFDDE6DA),
                  ),
                ),
                child: Image.asset(
                  'lib/assets/images/logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.eco_rounded,
                    color: FarmColors.primary,
                    size: 21,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.adminMode
                          ? 'Personal invitations'
                          : 'Grow the HPJ community',
                      style: const TextStyle(
                        color: FarmColors.ink,
                        fontSize: 16.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Create a clean HPJ invitation and share it by WhatsApp.',
                      maxLines: 2,
                      style: const TextStyle(
                        color: FarmColors.mutedText,
                        fontSize: 8.8,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (widget.adminMode) ...[
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final item in _hpjInviteAudiences) ...[
                    ChoiceChip(
                      label: Text(_hpjInviteAudienceLabel(item)),
                      selected: _audience == item,
                      onSelected: (_) => _switchAudience(item),
                    ),
                    const SizedBox(width: 6),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (template == null || !template.enabled)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: FarmColors.warning.withOpacity(.20),
                ),
              ),
              child: const Text(
                'This invitation type is unavailable. Ask Admin to enable it.',
                style: TextStyle(
                  color: FarmColors.ink,
                  fontSize: 9.4,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else ...[
            RepaintBoundary(
              key: _flyerKey,
              child: _flyer(),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFFDDE6DA),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$audienceLabel details',
                    style: const TextStyle(
                      color: FarmColors.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    template.headline,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: FarmColors.mutedText,
                      fontSize: 8.6,
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 11),
                  TextField(
                    controller: _name,
                    maxLength: 120,
                    enabled: _lead == null,
                    onChanged: (_) {
                      setState(() {});
                      _updateMessage();
                    },
                    decoration: const InputDecoration(
                      labelText: 'Contact name *',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                      counterText: '',
                    ),
                  ),
                  if (_audience != 'customer') ...[
                    const SizedBox(height: 9),
                    TextField(
                      controller: _organization,
                      maxLength: 140,
                      enabled: _lead == null,
                      onChanged: (_) {
                        setState(() {});
                        _updateMessage();
                      },
                      decoration: InputDecoration(
                        labelText: _audience == 'farmer'
                            ? 'Farm name (optional)'
                            : 'Business name (optional)',
                        border: const OutlineInputBorder(),
                        prefixIcon: Icon(
                          _audience == 'farmer'
                              ? Icons.agriculture_outlined
                              : Icons.business_outlined,
                        ),
                        counterText: '',
                      ),
                    ),
                  ],
                  const SizedBox(height: 9),
                  TextField(
                    controller: _phone,
                    enabled: _lead == null,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'WhatsApp number *',
                      hintText: '+1876XXXXXXX',
                      helperText: 'Include the country code.',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 9),
                  TextField(
                    controller: _source,
                    maxLength: 300,
                    enabled: _lead == null,
                    decoration: const InputDecoration(
                      labelText: 'Consent source *',
                      hintText: 'Example: agreed during our call',
                      helperText:
                          'Record where they agreed to receive the invitation.',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.verified_user_outlined),
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 9),
                  TextField(
                    controller: _notes,
                    maxLength: 500,
                    enabled: _lead == null,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Private notes (optional)',
                      border: OutlineInputBorder(),
                      counterText: '',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.fromLTRB(11, 4, 8, 4),
              decoration: BoxDecoration(
                color: _consent
                    ? const Color(0xFFEAF5EC)
                    : const Color(0xFFFFF8E8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _consent
                      ? FarmColors.success.withOpacity(.18)
                      : FarmColors.warning.withOpacity(.20),
                ),
              ),
              child: CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: const Text(
                  'Permission confirmed',
                  style: TextStyle(
                    color: FarmColors.ink,
                    fontSize: 10.3,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                subtitle: const Text(
                  'They agreed to receive this HPJ invitation.',
                  style: TextStyle(
                    color: FarmColors.mutedText,
                    fontSize: 8.3,
                  ),
                ),
                value: _consent && _lead?.optedOut != true,
                onChanged: _lead?.optedOut == true || _busy
                    ? null
                    : (value) => setState(
                          () => _consent = value == true,
                        ),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFFDDE6DA),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: FarmColors.primary,
                        size: 18,
                      ),
                      SizedBox(width: 7),
                      Text(
                        'Invitation message',
                        style: TextStyle(
                          color: FarmColors.ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  TextField(
                    controller: _message,
                    maxLength: 2500,
                    maxLines: 6,
                    minLines: 4,
                    onChanged: (_) => _editedMessage = true,
                    decoration: const InputDecoration(
                      hintText: 'Preview the WhatsApp message before sharing.',
                      border: OutlineInputBorder(),
                      counterText: '',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            if (_lead == null)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _busy || !_consent ? null : _saveContact,
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: const Text('Prepare invitation'),
                ),
              ),
            if (_lead != null) ...[
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: _lead!.optedOut
                      ? const Color(0xFFFFECEB)
                      : const Color(0xFFEAF5EC),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(
                      _lead!.optedOut
                          ? Icons.block_rounded
                          : Icons.check_circle_outline_rounded,
                      color: _lead!.optedOut
                          ? FarmColors.danger
                          : FarmColors.success,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _lead!.optedOut
                            ? 'Do not contact'
                            : 'Ready to share • ${_lead!.status.replaceAll('_', ' ')}',
                        style: const TextStyle(
                          color: FarmColors.ink,
                          fontSize: 9.6,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 9),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: canSend ? _openWhatsApp : null,
                  icon: const Icon(Icons.message_outlined),
                  label: const Text('Open WhatsApp'),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: canSend ? () => _shareFlyer() : null,
                    icon: const Icon(Icons.ios_share_rounded, size: 17),
                    label: const Text('Share invitation'),
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        canSend ? () => _shareFlyer(imageOnly: true) : null,
                    icon: const Icon(Icons.save_alt_rounded, size: 17),
                    label: const Text('Save image'),
                  ),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: canSend
                  ? () => Clipboard.setData(
                        ClipboardData(
                          text: _message.text.trim(),
                        ),
                      ).then((_) {
                        _notice('Invitation copied.');
                      })
                  : null,
              icon: const Icon(Icons.copy_rounded, size: 17),
              label: const Text('Copy invitation text'),
            ),
            if (_lead != null && !_lead!.optedOut) ...[
              const Divider(height: 24),
              const Text(
                'Invitation status',
                style: TextStyle(
                  color: FarmColors.ink,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 7),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  OutlinedButton(
                    onPressed: _busy ? null : () => _setStatus('sent'),
                    child: const Text('Sent'),
                  ),
                  OutlinedButton(
                    onPressed: _busy ? null : () => _setStatus('follow_up'),
                    child: const Text('Follow up'),
                  ),
                  OutlinedButton(
                    onPressed:
                        _busy ? null : () => _setStatus('reported_joined'),
                    child: const Text('Joined'),
                  ),
                  OutlinedButton(
                    onPressed: _busy ? null : () => _setStatus('opted_out'),
                    child: const Text('Do not contact'),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            const Text(
              'WhatsApp opens a draft. You still choose the recipient and send it yourself.',
              style: TextStyle(
                fontSize: 8.2,
                color: FarmColors.mutedText,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Recent invitations (${filtered.length})',
                  style: const TextStyle(
                    color: FarmColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Refresh history',
                onPressed: _refreshHistory,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          if (filtered.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFE1E8DE),
                ),
              ),
              child: Text(
                'No saved $audienceLabel invitations yet.',
                style: const TextStyle(
                  color: FarmColors.mutedText,
                  fontSize: 9.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          for (final row in filtered.take(30)) _historyCard(row),
        ],
      ),
    );
  }
}

class HpjInviteTemplateEditor extends StatefulWidget {
  const HpjInviteTemplateEditor({super.key});
  @override
  State<HpjInviteTemplateEditor> createState() =>
      _HpjInviteTemplateEditorState();
}

class _HpjInviteTemplateEditorState extends State<HpjInviteTemplateEditor> {
  final _headline = TextEditingController();
  final _body = TextEditingController();
  final _image = TextEditingController();
  final _link = TextEditingController();
  final Map<String, HpjInviteTemplate> _templates = {};
  String _audience = 'customer';
  String? _error;
  bool _enabled = true, _busy = false, _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _headline.dispose();
    _body.dispose();
    _image.dispose();
    _link.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      await requireAdminAccess();
      final role = normalizeStaffRole(await fetchCurrentStaffRole());
      if (role != 'owner' && role != 'manager')
        throw Exception('Owner/Manager only.');
      final rows = await supabase.from('hpj_invite_templates').select(
          'audience,headline,message_template,image_url,destination_url,is_enabled');
      if (!mounted) return;
      _templates.clear();
      for (final raw in rows as List) {
        final item =
            HpjInviteTemplate.fromRow(Map<String, dynamic>.from(raw as Map));
        _templates[item.audience] = item;
      }
      _select(_audience);
      setState(() {
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (mounted)
        setState(() {
          _loading = false;
          _error = '$error';
        });
    }
  }

  void _select(String audience) {
    final item = _templates[audience];
    setState(() {
      _audience = audience;
      _headline.text = item?.headline ?? '';
      _body.text = (item?.body ?? '').replaceAll(r'\n', '\n');
      _image.text = item?.imageUrl ?? '';
      _link.text = item?.destinationUrl ?? hpjSharePlayUrl;
      _enabled = item?.enabled ?? false;
    });
  }

  Future<void> _useCampaignImage() async {
    final campaign = await hpjFetchShareCampaign();
    if (!mounted) return;
    if (campaign == null || campaign.imageUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('Publish a marketing image in Admin → Marketing first.')));
      return;
    }
    setState(() => _image.text = campaign.imageUrl);
  }

  Future<void> _save() async {
    final dest = Uri.tryParse(_link.text.trim());
    final photo = _image.text.trim();
    final imageUri = Uri.tryParse(photo);
    if (_headline.text.trim().isEmpty ||
        _body.text.trim().length < 10 ||
        dest == null ||
        dest.scheme != 'https' ||
        dest.host.isEmpty ||
        (photo.isNotEmpty &&
            (imageUri == null ||
                imageUri.scheme != 'https' ||
                imageUri.host.isEmpty))) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Enter a headline, message and valid HTTPS links.')));
      return;
    }
    setState(() => _busy = true);
    try {
      await requireAdminAccess();
      await supabase.from('hpj_invite_templates').update({
        'headline': _headline.text.trim(),
        'message_template': _body.text.trim(),
        'image_url': photo,
        'destination_url': dest.toString(),
        'is_enabled': _enabled,
        'updated_by': supabase.auth.currentUser?.id,
      }).eq('audience', _audience);
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Invitation template saved. Reopen Invite & Grow to see changes.')));
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Template save failed: $error')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Invitation templates')),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : ListView(
                    padding: const EdgeInsets.fromLTRB(17, 20, 17, 100),
                    children: [
                        const Text('Admin-managed invitation templates',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: FarmColors.deepGreen)),
                        const SizedBox(height: 12),
                        Wrap(spacing: 8, children: [
                          for (final item in _hpjInviteAudiences)
                            ChoiceChip(
                                label: Text(_hpjInviteAudienceLabel(item)),
                                selected: _audience == item,
                                onSelected: (_) => _select(item)),
                        ]),
                        const SizedBox(height: 15),
                        TextField(
                            controller: _headline,
                            maxLength: 90,
                            decoration: const InputDecoration(
                                labelText: 'Flyer headline',
                                border: OutlineInputBorder())),
                        TextField(
                            controller: _body,
                            minLines: 7,
                            maxLines: 12,
                            maxLength: 2000,
                            decoration: const InputDecoration(
                                labelText: 'Message template',
                                helperText:
                                    'Available: {first_name}, {organization}, {inviter}, {link}',
                                border: OutlineInputBorder(),
                                alignLabelWithHint: true)),
                        TextField(
                            controller: _link,
                            keyboardType: TextInputType.url,
                            decoration: const InputDecoration(
                                labelText: 'HTTPS registration / app link',
                                border: OutlineInputBorder())),
                        TextField(
                            controller: _image,
                            keyboardType: TextInputType.url,
                            decoration: const InputDecoration(
                                labelText: 'Optional HTTPS flyer image URL',
                                border: OutlineInputBorder())),
                        OutlinedButton.icon(
                            onPressed: _useCampaignImage,
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text(
                                'Use published HPJ marketing image')),
                        SwitchListTile.adaptive(
                            title: const Text(
                                'Enable invitations for this audience'),
                            value: _enabled,
                            onChanged: _busy
                                ? null
                                : (value) => setState(() => _enabled = value)),
                        FilledButton.icon(
                            onPressed: _busy ? null : _save,
                            icon: const Icon(Icons.save_outlined),
                            label: Text(_busy ? 'Saving…' : 'Save template')),
                        const SizedBox(height: 12),
                        const Text(
                            'Use verified destination links only. Until separate Business and Farmer landing pages are deployed, the prefilled link opens the existing HPJ app listing.',
                            style: TextStyle(
                                color: FarmColors.mutedText, fontSize: 12)),
                      ]),
      );
}
