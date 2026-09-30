part of harvest_place_app;

// ============================================================================
// HPJ CONTROLLED MARKETPLACE MESSAGING
// Customer ↔ Farmer / Business ↔ Farmer + global Messaging Mode
//
// Modes:
//   open    = eligible participants can start and reply normally.
//   limited = cross-messaging must be order-linked or Admin approved.
//   paused  = non-staff users can read history, but cannot start/send.
//
// This is intentionally NOT an open social DM system.
// ============================================================================

const String hpjMessagingModeOpen = 'open';
const String hpjMessagingModeLimited = 'limited';
const String hpjMessagingModePaused = 'paused';

const String hpjMoneyPolicyBlock = 'block';
const String hpjMoneyPolicyFlag = 'flag';
const String hpjMoneyPolicyAllow = 'allow';

String hpjMessagingModeLabel(String mode) {
  switch (mode.trim().toLowerCase()) {
    case hpjMessagingModeOpen:
      return 'Open';
    case hpjMessagingModePaused:
      return 'Paused';
    default:
      return 'Limited';
  }
}

class HpjMessagingPolicy {
  final String mode;
  final bool allowNewSupportConversations;
  final bool allowSupportReplies;
  final bool allowCustomerFarmer;
  final bool allowBusinessFarmer;
  final bool requireOrderLinkWhenLimited;
  final bool allowAttachments;
  final bool allowExternalContactSharing;
  final String moneyPolicy;
  final int autoCloseCompletedDays;
  final String expectedResponseText;

  const HpjMessagingPolicy({
    this.mode = hpjMessagingModeLimited,
    this.allowNewSupportConversations = true,
    this.allowSupportReplies = true,
    this.allowCustomerFarmer = true,
    this.allowBusinessFarmer = true,
    this.requireOrderLinkWhenLimited = true,
    this.allowAttachments = false,
    this.allowExternalContactSharing = false,
    this.moneyPolicy = hpjMoneyPolicyBlock,
    this.autoCloseCompletedDays = 7,
    this.expectedResponseText = 'HPJ will respond as soon as possible.',
  });

  factory HpjMessagingPolicy.fromMap(Map<String, dynamic> data) {
    int whole(dynamic value, int fallback) {
      if (value is num) return value.toInt();
      return int.tryParse((value ?? '').toString()) ?? fallback;
    }

    final rawMode =
        (data['mode'] ?? hpjMessagingModeLimited).toString().trim().toLowerCase();
    final mode = const <String>{
      hpjMessagingModeOpen,
      hpjMessagingModeLimited,
      hpjMessagingModePaused,
    }.contains(rawMode)
        ? rawMode
        : hpjMessagingModeLimited;

    final rawMoney =
        (data['money_policy'] ?? hpjMoneyPolicyBlock).toString().trim().toLowerCase();
    final moneyPolicy = const <String>{
      hpjMoneyPolicyBlock,
      hpjMoneyPolicyFlag,
      hpjMoneyPolicyAllow,
    }.contains(rawMoney)
        ? rawMoney
        : hpjMoneyPolicyBlock;

    return HpjMessagingPolicy(
      mode: mode,
      allowNewSupportConversations:
          data['allow_new_support_conversations'] != false,
      allowSupportReplies: data['allow_support_replies'] != false,
      allowCustomerFarmer: data['allow_customer_farmer'] != false,
      allowBusinessFarmer: data['allow_business_farmer'] != false,
      requireOrderLinkWhenLimited:
          data['require_order_link_when_limited'] != false,
      allowAttachments: data['allow_attachments'] == true,
      allowExternalContactSharing:
          data['allow_external_contact_sharing'] == true,
      moneyPolicy: moneyPolicy,
      autoCloseCompletedDays:
          whole(data['auto_close_completed_days'], 7).clamp(0, 365).toInt(),
      expectedResponseText:
          (data['expected_response_text'] ?? 'HPJ will respond as soon as possible.')
              .toString()
              .trim(),
    );
  }

  bool get isOpen => mode == hpjMessagingModeOpen;
  bool get isLimited => mode == hpjMessagingModeLimited;
  bool get isPaused => mode == hpjMessagingModePaused;

  bool get canStartSupport =>
      !isPaused && allowNewSupportConversations;

  bool get canReplySupport =>
      !isPaused && allowSupportReplies;

  bool get canSendAttachment =>
      !isPaused && allowAttachments;

  String get publicStatusMessage {
    if (isPaused) {
      return 'Messaging is temporarily paused. You can still read previous conversations.';
    }
    if (isLimited) {
      return 'Messaging is limited to support, active orders and approved marketplace conversations.';
    }
    return 'Messaging is available for eligible HPJ conversations.';
  }

  HpjMessagingPolicy copyWith({
    String? mode,
    bool? allowNewSupportConversations,
    bool? allowSupportReplies,
    bool? allowCustomerFarmer,
    bool? allowBusinessFarmer,
    bool? requireOrderLinkWhenLimited,
    bool? allowAttachments,
    bool? allowExternalContactSharing,
    String? moneyPolicy,
    int? autoCloseCompletedDays,
    String? expectedResponseText,
  }) {
    return HpjMessagingPolicy(
      mode: mode ?? this.mode,
      allowNewSupportConversations:
          allowNewSupportConversations ?? this.allowNewSupportConversations,
      allowSupportReplies: allowSupportReplies ?? this.allowSupportReplies,
      allowCustomerFarmer:
          allowCustomerFarmer ?? this.allowCustomerFarmer,
      allowBusinessFarmer:
          allowBusinessFarmer ?? this.allowBusinessFarmer,
      requireOrderLinkWhenLimited:
          requireOrderLinkWhenLimited ?? this.requireOrderLinkWhenLimited,
      allowAttachments: allowAttachments ?? this.allowAttachments,
      allowExternalContactSharing:
          allowExternalContactSharing ?? this.allowExternalContactSharing,
      moneyPolicy: moneyPolicy ?? this.moneyPolicy,
      autoCloseCompletedDays:
          autoCloseCompletedDays ?? this.autoCloseCompletedDays,
      expectedResponseText:
          expectedResponseText ?? this.expectedResponseText,
    );
  }
}

Future<HpjMessagingPolicy> fetchHpjMessagingPolicy() async {
  try {
    final response = await supabase.rpc('hpj_get_messaging_policy');

    if (response is Map) {
      return HpjMessagingPolicy.fromMap(
        Map<String, dynamic>.from(response),
      );
    }

    if (response is List && response.isNotEmpty && response.first is Map) {
      return HpjMessagingPolicy.fromMap(
        Map<String, dynamic>.from(response.first as Map),
      );
    }
  } catch (rpcError) {
    farmDebugLog('Messaging policy RPC unavailable: $rpcError');
  }

  try {
    final response = await supabase
        .from('hpj_messaging_settings')
        .select()
        .eq('id', true)
        .maybeSingle();

    if (response != null) {
      return HpjMessagingPolicy.fromMap(
        Map<String, dynamic>.from(response as Map),
      );
    }
  } catch (error) {
    farmDebugLog('Messaging settings unavailable: $error');
  }

  return const HpjMessagingPolicy();
}

Future<void> saveAdminHpjMessagingPolicy(HpjMessagingPolicy policy) async {
  await requireAdminAccess();

  await supabase.rpc(
    'hpj_save_messaging_policy',
    params: <String, dynamic>{
      'p_mode': policy.mode,
      'p_allow_new_support_conversations':
          policy.allowNewSupportConversations,
      'p_allow_support_replies': policy.allowSupportReplies,
      'p_allow_customer_farmer': policy.allowCustomerFarmer,
      'p_allow_business_farmer': policy.allowBusinessFarmer,
      'p_require_order_link_when_limited':
          policy.requireOrderLinkWhenLimited,
      'p_allow_attachments': policy.allowAttachments,
      'p_allow_external_contact_sharing':
          policy.allowExternalContactSharing,
      'p_money_policy': policy.moneyPolicy,
      'p_auto_close_completed_days': policy.autoCloseCompletedDays,
      'p_expected_response_text': policy.expectedResponseText.trim(),
    },
  );
}

Future<void> hpjRequireSupportStartAllowed() async {
  final policy = await fetchHpjMessagingPolicy();

  if (!policy.canStartSupport) {
    throw Exception(
      policy.isPaused
          ? 'HPJ messaging is currently paused. You can still read previous conversations.'
          : 'New support conversations are temporarily unavailable.',
    );
  }
}

Future<void> hpjRequireSupportReplyAllowed() async {
  final policy = await fetchHpjMessagingPolicy();

  if (!policy.canReplySupport) {
    throw Exception(
      policy.isPaused
          ? 'HPJ messaging is currently paused. This conversation is read-only for now.'
          : 'Replies are temporarily unavailable.',
    );
  }
}

Future<void> hpjRequireMessagingAttachmentAllowed() async {
  final policy = await fetchHpjMessagingPolicy();

  if (!policy.canSendAttachment) {
    throw Exception(
      policy.isPaused
          ? 'Messaging is paused.'
          : 'Photo and video attachments are currently turned off.',
    );
  }
}

Future<String> hpjCreateControlledSupportTicket({
  required String subject,
  required String message,
}) async {
  await hpjRequireSupportStartAllowed();
  return createSupportTicket(
    subject: subject,
    message: message,
  );
}

Future<void> hpjSendControlledSupportMessage({
  required String ticketId,
  String message = '',
  bool internal = false,
  String? replyToMessageId,
  String? attachmentPath,
  String? attachmentType,
  String? attachmentName,
}) async {
  if (!internal) {
    await hpjRequireSupportReplyAllowed();

    if ((attachmentPath ?? '').trim().isNotEmpty) {
      await hpjRequireMessagingAttachmentAllowed();
    }
  }

  await sendSupportMessage(
    ticketId: ticketId,
    message: message,
    internal: internal,
    replyToMessageId: replyToMessageId,
    attachmentPath: attachmentPath,
    attachmentType: attachmentType,
    attachmentName: attachmentName,
  );
}

class HpjMarketplaceThread {
  final String id;
  final String threadType;
  final String contextType;
  final String contextId;
  final String topic;
  final String status;
  final bool adminApproved;
  final String customerUserId;
  final String farmerUserId;
  final String businessUserId;
  final String farmerProfileId;
  final String farmName;
  final String otherPartyLabel;
  final String lastMessagePreview;
  final DateTime? lastMessageAt;
  final DateTime? createdAt;

  const HpjMarketplaceThread({
    required this.id,
    required this.threadType,
    required this.contextType,
    required this.contextId,
    required this.topic,
    required this.status,
    required this.adminApproved,
    required this.customerUserId,
    required this.farmerUserId,
    required this.businessUserId,
    required this.farmerProfileId,
    required this.farmName,
    required this.otherPartyLabel,
    required this.lastMessagePreview,
    required this.lastMessageAt,
    required this.createdAt,
  });

  factory HpjMarketplaceThread.fromMap(Map<String, dynamic> data) {
    return HpjMarketplaceThread(
      id: (data['id'] ?? '').toString(),
      threadType: (data['thread_type'] ?? '').toString(),
      contextType: (data['context_type'] ?? '').toString(),
      contextId: (data['context_id'] ?? '').toString(),
      topic: (data['topic'] ?? 'Marketplace message').toString().trim(),
      status: (data['status'] ?? 'active').toString().trim().toLowerCase(),
      adminApproved: data['admin_approved'] == true,
      customerUserId: (data['customer_user_id'] ?? '').toString(),
      farmerUserId: (data['farmer_user_id'] ?? '').toString(),
      businessUserId: (data['business_user_id'] ?? '').toString(),
      farmerProfileId: (data['farmer_profile_id'] ?? '').toString(),
      farmName: (data['farm_name'] ?? '').toString().trim(),
      otherPartyLabel:
          (data['other_party_label'] ?? 'HPJ Partner').toString().trim(),
      lastMessagePreview:
          (data['last_message_preview'] ?? '').toString().trim(),
      lastMessageAt: parseProductDate(data['last_message_at']),
      createdAt: parseProductDate(data['created_at']),
    );
  }

  bool get isClosed => status == 'closed' || status == 'archived';

  String get contextLabel {
    switch (contextType) {
      case 'order':
        return 'Order conversation';
      case 'product':
        return 'Product question';
      case 'farm':
        return 'Farm question';
      case 'business_request':
        return 'Business sourcing';
      default:
        return 'Marketplace conversation';
    }
  }
}

class HpjMarketplaceMessage {
  final String id;
  final String threadId;
  final String senderUserId;
  final String senderRole;
  final String body;
  final bool flagged;
  final String flagReason;
  final DateTime? createdAt;

  const HpjMarketplaceMessage({
    required this.id,
    required this.threadId,
    required this.senderUserId,
    required this.senderRole,
    required this.body,
    required this.flagged,
    required this.flagReason,
    required this.createdAt,
  });

  factory HpjMarketplaceMessage.fromMap(Map<String, dynamic> data) {
    return HpjMarketplaceMessage(
      id: (data['id'] ?? '').toString(),
      threadId: (data['thread_id'] ?? '').toString(),
      senderUserId: (data['sender_user_id'] ?? '').toString(),
      senderRole: (data['sender_role'] ?? 'member').toString(),
      body: (data['body'] ?? '').toString(),
      flagged: data['flagged'] == true,
      flagReason: (data['flag_reason'] ?? '').toString(),
      createdAt: parseProductDate(data['created_at']),
    );
  }
}

Future<List<HpjMarketplaceThread>> fetchMyHpjMarketplaceThreads() async {
  final user = supabase.auth.currentUser;
  if (user == null) return const <HpjMarketplaceThread>[];

  try {
    final response = await supabase.rpc('hpj_get_my_marketplace_threads');

    if (response is! List) return const <HpjMarketplaceThread>[];

    return response
        .whereType<Map>()
        .map(
          (row) => HpjMarketplaceThread.fromMap(
            Map<String, dynamic>.from(row),
          ),
        )
        .where((item) => item.id.isNotEmpty)
        .toList(growable: false);
  } catch (error) {
    farmDebugLog('Marketplace messages unavailable: $error');
    return const <HpjMarketplaceThread>[];
  }
}

Stream<List<HpjMarketplaceMessage>> watchHpjMarketplaceMessages(
  String threadId,
) {
  final cleanId = threadId.trim();
  if (cleanId.isEmpty) {
    return Stream<List<HpjMarketplaceMessage>>.value(
      const <HpjMarketplaceMessage>[],
    );
  }

  return supabase
      .from('hpj_marketplace_messages')
      .stream(primaryKey: const ['id'])
      .eq('thread_id', cleanId)
      .order('created_at', ascending: true)
      .map(
        (rows) => rows
            .map(
              (row) => HpjMarketplaceMessage.fromMap(
                Map<String, dynamic>.from(row),
              ),
            )
            .toList(growable: false),
      );
}

Future<String> createHpjFarmerConversation({
  required String farmerProfileId,
  String contextType = 'farm',
  String contextId = '',
  String topic = 'Question for farmer',
}) async {
  final cleanFarmer = farmerProfileId.trim();
  if (cleanFarmer.isEmpty) {
    throw Exception('Farmer could not be identified.');
  }

  final policy = await fetchHpjMessagingPolicy();

  if (policy.isPaused) {
    throw Exception('Marketplace messaging is currently paused.');
  }

  if (!policy.allowCustomerFarmer && !policy.allowBusinessFarmer) {
    throw Exception('Direct marketplace messaging is currently unavailable.');
  }

  final response = await supabase.rpc(
    'hpj_create_farmer_conversation',
    params: <String, dynamic>{
      'p_farmer_profile_id': cleanFarmer,
      'p_context_type': contextType.trim().toLowerCase(),
      'p_context_id': contextId.trim(),
      'p_topic': topic.trim(),
    },
  );

  final id = response?.toString().trim() ?? '';
  if (id.isEmpty) {
    throw Exception('Could not open the marketplace conversation.');
  }
  return id;
}

Future<void> sendHpjMarketplaceMessage({
  required String threadId,
  required String message,
}) async {
  final cleanId = threadId.trim();
  final cleanMessage = message.trim();

  if (cleanId.isEmpty || cleanMessage.isEmpty) {
    throw Exception('Write a message first.');
  }

  if (cleanMessage.length > 2000) {
    throw Exception('Keep marketplace messages under 2,000 characters.');
  }

  await supabase.rpc(
    'hpj_send_marketplace_message',
    params: <String, dynamic>{
      'p_thread_id': cleanId,
      'p_message': cleanMessage,
    },
  );
}

Future<void> adminUpdateHpjMarketplaceThread({
  required String threadId,
  bool? approved,
  String? status,
}) async {
  await requireAdminAccess();

  await supabase.rpc(
    'hpj_admin_update_marketplace_thread',
    params: <String, dynamic>{
      'p_thread_id': threadId.trim(),
      'p_approved': approved,
      'p_status': status?.trim().toLowerCase(),
    },
  );
}

class HpjMessageFarmerButton extends StatefulWidget {
  final String farmerProfileId;
  final String contextType;
  final String contextId;
  final String topic;
  final bool compact;

  const HpjMessageFarmerButton({
    super.key,
    required this.farmerProfileId,
    this.contextType = 'farm',
    this.contextId = '',
    this.topic = 'Question for farmer',
    this.compact = false,
  });

  @override
  State<HpjMessageFarmerButton> createState() => _HpjMessageFarmerButtonState();
}

class _HpjMessageFarmerButtonState extends State<HpjMessageFarmerButton> {
  bool busy = false;

  Future<void> _open() async {
    if (busy) return;

    if (supabase.auth.currentUser == null) {
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => const LoginScreen(returnToPrevious: true),
        ),
      );
      if (result != true && supabase.auth.currentUser == null) return;
    }

    setState(() => busy = true);
    try {
      final threadId = await createHpjFarmerConversation(
        farmerProfileId: widget.farmerProfileId,
        contextType: widget.contextType,
        contextId: widget.contextId,
        topic: widget.topic,
      );

      final rows = await fetchMyHpjMarketplaceThreads();
      HpjMarketplaceThread? thread;
      for (final item in rows) {
        if (item.id == threadId) {
          thread = item;
          break;
        }
      }

      if (!mounted) return;

      if (thread != null) {
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => HpjMarketplaceConversationScreen(
              thread: thread!,
            ),
          ),
        );
      } else {
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => const HpjMarketplaceInboxScreen(),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyAppError(error))),
      );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.compact
        ? OutlinedButton.icon(
            onPressed: busy ? null : _open,
            icon: busy
                ? const SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.chat_bubble_outline_rounded, size: 17),
            label: const Text('Message'),
          )
        : SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: busy ? null : _open,
              icon: busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.chat_bubble_outline_rounded),
              label: Text(busy ? 'Opening…' : 'Message farmer'),
            ),
          );
  }
}

class HpjMarketplaceInboxScreen extends StatefulWidget {
  const HpjMarketplaceInboxScreen({super.key});

  @override
  State<HpjMarketplaceInboxScreen> createState() =>
      _HpjMarketplaceInboxScreenState();
}

class _HpjMarketplaceInboxScreenState
    extends State<HpjMarketplaceInboxScreen> {
  late Future<List<HpjMarketplaceThread>> future;
  late Future<HpjMessagingPolicy> policyFuture;

  @override
  void initState() {
    super.initState();
    future = fetchMyHpjMarketplaceThreads();
    policyFuture = fetchHpjMessagingPolicy();
  }

  Future<void> _refresh() async {
    final next = fetchMyHpjMarketplaceThreads();
    final nextPolicy = fetchHpjMessagingPolicy();
    setState(() {
      future = next;
      policyFuture = nextPolicy;
    });
    await Future.wait<dynamic>([next, nextPolicy]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: AppBar(
        title: const Text('Marketplace Messages'),
        backgroundColor: FarmColors.background,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 110),
          children: [
            FutureBuilder<HpjMessagingPolicy>(
              future: policyFuture,
              builder: (context, snapshot) {
                final policy =
                    snapshot.data ?? const HpjMessagingPolicy();
                return _HpjMessagingModeBanner(policy: policy);
              },
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<HpjMarketplaceThread>>(
              future: future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final threads =
                    snapshot.data ?? const <HpjMarketplaceThread>[];

                if (threads.isEmpty) {
                  return const FarmEmptyState(
                    icon: Icons.forum_outlined,
                    title: 'No marketplace conversations',
                    message:
                        'Eligible farmer and business conversations will appear here.',
                    compact: true,
                  );
                }

                return Column(
                  children: threads
                      .map(
                        (thread) => Padding(
                          padding: const EdgeInsets.only(bottom: 9),
                          child: _HpjMarketplaceThreadCard(
                            thread: thread,
                            onTap: () async {
                              await Navigator.of(context).push<void>(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      HpjMarketplaceConversationScreen(
                                    thread: thread,
                                  ),
                                ),
                              );
                              if (mounted) await _refresh();
                            },
                          ),
                        ),
                      )
                      .toList(growable: false),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HpjMessagingModeBanner extends StatelessWidget {
  final HpjMessagingPolicy policy;

  const _HpjMessagingModeBanner({required this.policy});

  @override
  Widget build(BuildContext context) {
    final paused = policy.isPaused;
    final limited = policy.isLimited;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: paused
            ? const Color(0xFFFFF2F0)
            : limited
                ? const Color(0xFFFFF8E8)
                : const Color(0xFFF1F7EF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: paused
              ? const Color(0xFFF3C7C0)
              : limited
                  ? const Color(0xFFEFD9A1)
                  : const Color(0xFFD5E5D0),
        ),
      ),
      child: Row(
        children: [
          Icon(
            paused
                ? Icons.pause_circle_outline_rounded
                : limited
                    ? Icons.shield_outlined
                    : Icons.chat_bubble_outline_rounded,
            color: paused
                ? FarmColors.danger
                : limited
                    ? FarmColors.warning
                    : FarmColors.green,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Messaging ${hpjMessagingModeLabel(policy.mode)}',
                  style: const TextStyle(
                    color: FarmColors.ink,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  policy.publicStatusMessage,
                  style: const TextStyle(
                    color: FarmColors.mutedText,
                    fontSize: 9,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
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

class _HpjMarketplaceThreadCard extends StatelessWidget {
  final HpjMarketplaceThread thread;
  final VoidCallback onTap;

  const _HpjMarketplaceThreadCard({
    required this.thread,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: FarmColors.line),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: FarmColors.primarySoft,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  thread.threadType == 'business_farmer'
                      ? Icons.business_outlined
                      : Icons.agriculture_outlined,
                  color: FarmColors.green,
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      thread.otherPartyLabel.isNotEmpty
                          ? thread.otherPartyLabel
                          : thread.farmName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: FarmColors.ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      thread.lastMessagePreview.isNotEmpty
                          ? thread.lastMessagePreview
                          : thread.topic,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: FarmColors.mutedText,
                        fontSize: 9.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      thread.contextLabel,
                      style: const TextStyle(
                        color: FarmColors.green,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: FarmColors.mutedText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HpjMarketplaceConversationScreen extends StatefulWidget {
  final HpjMarketplaceThread thread;

  const HpjMarketplaceConversationScreen({
    super.key,
    required this.thread,
  });

  @override
  State<HpjMarketplaceConversationScreen> createState() =>
      _HpjMarketplaceConversationScreenState();
}

class _HpjMarketplaceConversationScreenState
    extends State<HpjMarketplaceConversationScreen> {
  final controller = TextEditingController();
  bool sending = false;
  late Future<HpjMessagingPolicy> policyFuture;

  @override
  void initState() {
    super.initState();
    policyFuture = fetchHpjMessagingPolicy();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _send(HpjMessagingPolicy policy) async {
    if (sending || policy.isPaused || widget.thread.isClosed) return;

    final message = controller.text.trim();
    if (message.isEmpty) return;

    setState(() => sending = true);
    try {
      await sendHpjMarketplaceMessage(
        threadId: widget.thread.id,
        message: message,
      );
      controller.clear();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyAppError(error))),
      );
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = supabase.auth.currentUser?.id ?? '';

    return FutureBuilder<HpjMessagingPolicy>(
      future: policyFuture,
      builder: (context, policySnapshot) {
        final policy =
            policySnapshot.data ?? const HpjMessagingPolicy();
        final readOnly = policy.isPaused || widget.thread.isClosed;

        return Scaffold(
          backgroundColor: FarmColors.background,
          appBar: AppBar(
            title: Text(
              widget.thread.otherPartyLabel.isNotEmpty
                  ? widget.thread.otherPartyLabel
                  : widget.thread.farmName,
            ),
            backgroundColor: FarmColors.background,
          ),
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 5),
                  child: _HpjMessagingModeBanner(policy: policy),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 2, 14, 8),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.shield_outlined,
                        size: 15,
                        color: FarmColors.green,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          policy.moneyPolicy == hpjMoneyPolicyBlock
                              ? 'Payments and off-platform deal arrangements are restricted.'
                              : policy.moneyPolicy == hpjMoneyPolicyFlag
                                  ? 'Payment and off-platform deal messages may be flagged for review.'
                                  : 'Keep payments and agreed pricing inside HPJ.',
                          style: const TextStyle(
                            color: FarmColors.mutedText,
                            fontSize: 8.7,
                            height: 1.25,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<List<HpjMarketplaceMessage>>(
                    stream: watchHpjMarketplaceMessages(
                      widget.thread.id,
                    ),
                    builder: (context, snapshot) {
                      final messages =
                          snapshot.data ?? const <HpjMarketplaceMessage>[];

                      if (snapshot.connectionState ==
                              ConnectionState.waiting &&
                          messages.isEmpty) {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }

                      if (messages.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'Start with a question about the order, produce, availability, collection or delivery.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: FarmColors.mutedText,
                                fontSize: 10,
                                height: 1.35,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                          12,
                          8,
                          12,
                          18,
                        ),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final mine =
                              message.senderUserId == userId;

                          return Align(
                            alignment: mine
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              constraints:
                                  const BoxConstraints(maxWidth: 320),
                              margin:
                                  const EdgeInsets.only(bottom: 7),
                              padding: const EdgeInsets.fromLTRB(
                                11,
                                9,
                                11,
                                8,
                              ),
                              decoration: BoxDecoration(
                                color: mine
                                    ? FarmColors.primarySoft
                                    : Colors.white,
                                borderRadius:
                                    BorderRadius.circular(15),
                                border: Border.all(
                                  color: message.flagged
                                      ? FarmColors.warning
                                      : FarmColors.line,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    message.body,
                                    style: const TextStyle(
                                      color: FarmColors.ink,
                                      fontSize: 11.2,
                                      height: 1.32,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (message.flagged) ...[
                                    const SizedBox(height: 5),
                                    const Text(
                                      'Flagged for HPJ review',
                                      style: TextStyle(
                                        color: FarmColors.warning,
                                        fontSize: 8,
                                        fontWeight:
                                            FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(
                    12,
                    8,
                    12,
                    12,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: FarmColors.line),
                    ),
                  ),
                  child: readOnly
                      ? Text(
                          policy.isPaused
                              ? 'Messaging is paused. This conversation is read-only.'
                              : 'This conversation is closed.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: FarmColors.mutedText,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: controller,
                                minLines: 1,
                                maxLines: 4,
                                maxLength: 2000,
                                decoration:
                                    const InputDecoration(
                                  hintText:
                                      'Ask about produce, order or delivery…',
                                  counterText: '',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filled(
                              tooltip: 'Send',
                              onPressed:
                                  sending ? null : () => _send(policy),
                              icon: sending
                                  ? const SizedBox(
                                      width: 17,
                                      height: 17,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.send_rounded,
                                      size: 19,
                                    ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class AdminHpjMessagingControlsScreen extends StatefulWidget {
  const AdminHpjMessagingControlsScreen({super.key});

  @override
  State<AdminHpjMessagingControlsScreen> createState() =>
      _AdminHpjMessagingControlsScreenState();
}

class _AdminHpjMessagingControlsScreenState
    extends State<AdminHpjMessagingControlsScreen> {
  late Future<HpjMessagingPolicy> future;
  HpjMessagingPolicy? draft;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    future = fetchHpjMessagingPolicy();
  }

  Future<void> _save() async {
    final policy = draft;
    if (policy == null || saving) return;

    setState(() => saving = true);
    try {
      await saveAdminHpjMessagingPolicy(policy);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Messaging controls saved.')),
      );
      setState(() {
        future = fetchHpjMessagingPolicy();
        draft = null;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyAppError(error))),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Widget _switch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      value: value,
      onChanged: saving ? null : onChanged,
      title: Text(
        title,
        style: const TextStyle(
          color: FarmColors.ink,
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: FarmColors.mutedText,
          fontSize: 9,
          height: 1.3,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: AppBar(
        title: const Text('Messaging Controls'),
        backgroundColor: FarmColors.background,
      ),
      body: FutureBuilder<HpjMessagingPolicy>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return FarmEmptyState(
              icon: Icons.error_outline_rounded,
              title: 'Could not load messaging controls',
              message: friendlyAppError(snapshot.error!),
              actionLabel: 'Retry',
              onAction: () => setState(
                () => future = fetchHpjMessagingPolicy(),
              ),
            );
          }

          draft ??=
              snapshot.data ?? const HpjMessagingPolicy();
          final policy = draft!;

          return ListView(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 110),
            children: [
              const Text(
                'Messaging mode',
                style: TextStyle(
                  color: FarmColors.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Control how much messaging access HPJ offers without deleting the messaging system.',
                style: TextStyle(
                  color: FarmColors.mutedText,
                  fontSize: 9.5,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment<String>(
                    value: hpjMessagingModeOpen,
                    label: Text('Open'),
                    icon: Icon(Icons.chat_bubble_outline_rounded),
                  ),
                  ButtonSegment<String>(
                    value: hpjMessagingModeLimited,
                    label: Text('Limited'),
                    icon: Icon(Icons.shield_outlined),
                  ),
                  ButtonSegment<String>(
                    value: hpjMessagingModePaused,
                    label: Text('Paused'),
                    icon: Icon(Icons.pause_circle_outline_rounded),
                  ),
                ],
                selected: <String>{policy.mode},
                onSelectionChanged: saving
                    ? null
                    : (values) {
                        if (values.isEmpty) return;
                        setState(
                          () => draft =
                              policy.copyWith(mode: values.first),
                        );
                      },
              ),
              const SizedBox(height: 12),
              _HpjMessagingModeBanner(policy: policy),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: FarmColors.line),
                ),
                child: Column(
                  children: [
                    _switch(
                      title: 'New HPJ support conversations',
                      subtitle:
                          'Allow signed-in users to start a new support conversation.',
                      value: policy.allowNewSupportConversations,
                      onChanged: (value) => setState(
                        () => draft = policy.copyWith(
                          allowNewSupportConversations: value,
                        ),
                      ),
                    ),
                    _switch(
                      title: 'Replies to HPJ support',
                      subtitle:
                          'Allow users to continue existing support conversations.',
                      value: policy.allowSupportReplies,
                      onChanged: (value) => setState(
                        () => draft = policy.copyWith(
                          allowSupportReplies: value,
                        ),
                      ),
                    ),
                    _switch(
                      title: 'Customer ↔ Farmer',
                      subtitle:
                          'Allow eligible customer-to-farmer marketplace conversations.',
                      value: policy.allowCustomerFarmer,
                      onChanged: (value) => setState(
                        () => draft = policy.copyWith(
                          allowCustomerFarmer: value,
                        ),
                      ),
                    ),
                    _switch(
                      title: 'Business ↔ Farmer',
                      subtitle:
                          'Allow eligible business sourcing conversations with farmers.',
                      value: policy.allowBusinessFarmer,
                      onChanged: (value) => setState(
                        () => draft = policy.copyWith(
                          allowBusinessFarmer: value,
                        ),
                      ),
                    ),
                    _switch(
                      title: 'Require order link in Limited mode',
                      subtitle:
                          'Customer-farmer chat must be connected to an HPJ order unless Admin approves it.',
                      value: policy.requireOrderLinkWhenLimited,
                      onChanged: (value) => setState(
                        () => draft = policy.copyWith(
                          requireOrderLinkWhenLimited: value,
                        ),
                      ),
                    ),
                    _switch(
                      title: 'Photo/video attachments',
                      subtitle:
                          'Allow media attachments in support conversations.',
                      value: policy.allowAttachments,
                      onChanged: (value) => setState(
                        () => draft = policy.copyWith(
                          allowAttachments: value,
                        ),
                      ),
                    ),
                    _switch(
                      title: 'External contact sharing',
                      subtitle:
                          'Allow phone numbers, email addresses and external links in marketplace messages.',
                      value: policy.allowExternalContactSharing,
                      onChanged: (value) => setState(
                        () => draft = policy.copyWith(
                          allowExternalContactSharing: value,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: policy.moneyPolicy,
                decoration: const InputDecoration(
                  labelText: 'Money / off-platform deal messages',
                ),
                items: const [
                  DropdownMenuItem(
                    value: hpjMoneyPolicyBlock,
                    child: Text('Block'),
                  ),
                  DropdownMenuItem(
                    value: hpjMoneyPolicyFlag,
                    child: Text('Flag for review'),
                  ),
                  DropdownMenuItem(
                    value: hpjMoneyPolicyAllow,
                    child: Text('Allow'),
                  ),
                ],
                onChanged: saving
                    ? null
                    : (value) {
                        if (value == null) return;
                        setState(
                          () => draft =
                              policy.copyWith(moneyPolicy: value),
                        );
                      },
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: saving ? null : _save,
                  icon: saving
                      ? const SizedBox(
                          width: 17,
                          height: 17,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    saving ? 'Saving…' : 'Save messaging controls',
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
