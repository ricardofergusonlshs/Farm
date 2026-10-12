part of harvest_place_app;

// ============================================================================

// HPJ 9/10 MVP — GROWTH & OPERATIONS CONTROL CENTER

// Audience, conversion, needs-attention, substitutions, app releases, health.

// ============================================================================

class AdminMvpProductionControlCenter extends StatefulWidget {
  final int refreshKey;

  const AdminMvpProductionControlCenter({super.key, this.refreshKey = 0});

  @override
  State<AdminMvpProductionControlCenter> createState() =>
      _AdminMvpProductionControlCenterState();
}

class _AdminMvpProductionControlCenterState
    extends State<AdminMvpProductionControlCenter> {
  int _days = 30;
  String _healthFilter = 'all';
  bool _groupHealthSignals = true;
  bool _showAllHealthSignals = false;
  Map<String, Map<String, dynamic>> _issueRecords = {};
  bool _issuesLoading = false;
  String? _issueLoadError;

  Future<void> _loadReliabilityIssues() async {
    if (!mounted) return;
    setState(() {
      _issuesLoading = true;
      _issueLoadError = null;
    });
    try {
      final records = await fetchHpjReliabilityIssues();
      if (mounted) setState(() => _issueRecords = records);
    } catch (error) {
      if (mounted) setState(() => _issueLoadError = error.toString());
    } finally {
      if (mounted) setState(() => _issuesLoading = false);
    }
  }

  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();

    _reload();
    _loadReliabilityIssues();
  }

  @override
  void didUpdateWidget(covariant AdminMvpProductionControlCenter oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.refreshKey != widget.refreshKey) _reload();
  }

  Future<List<dynamic>> _load() {
    return Future.wait<dynamic>([
      fetchHpjAdminAudienceSnapshot(days: _days),
      fetchHpjAdminNeedsAttention(),
      fetchHpjAdminPlatformHealth(days: 7),
      fetchHpjAdminOrderSubstitutions(limit: 100),
      fetchHpjPublicAppReleaseControl(),
    ]);
  }

  void _reload() {
    final next = _load();

    if (mounted) {
      setState(() {
        _future = next;
      });
    } else {
      _future = next;
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });

    await _future;
  }

  Widget _sectionHeader(
    String title,
    String subtitle, {
    IconData icon = Icons.insights_outlined,
    Widget? trailing,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: FarmColors.primarySoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: FarmColors.deepGreen, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: FarmColors.ink,
                  fontSize: 16,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (subtitle.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: FarmColors.mutedText,
                    fontSize: 11,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          trailing,
        ],
      ],
    );
  }

  Widget _metric({
    required String label,
    required String value,
    required String detail,
    required IconData icon,
    double? width,
  }) {
    return Container(
      width: width ?? 164,
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: FarmColors.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 31,
            height: 31,
            decoration: BoxDecoration(
              color: FarmColors.primarySoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: FarmColors.deepGreen, size: 17),
          ),
          const SizedBox(height: 9),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: FarmColors.ink,
              fontSize: 21,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: FarmColors.deepGreen,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            detail,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: FarmColors.mutedText,
              fontSize: 9.7,
              height: 1.25,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showOperationsDetails({
    required String title,
    required String summary,
    required List<String> details,
    VoidCallback? manage,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        color: FarmColors.ink)),
                const SizedBox(height: 8),
                Text(summary,
                    style: const TextStyle(
                        color: FarmColors.mutedText, height: 1.4)),
                const SizedBox(height: 15),
                for (final detail in details)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 11),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle_outline,
                              color: FarmColors.deepGreen, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Text(detail,
                                  style: const TextStyle(
                                      color: FarmColors.ink, height: 1.35))),
                        ]),
                  ),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                      child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      _reload();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh data'),
                  )),
                  if (manage != null) ...[
                    const SizedBox(width: 9),
                    Expanded(
                        child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        manage();
                      },
                      icon: const Icon(Icons.tune),
                      label: const Text('Manage'),
                    )),
                  ],
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAttentionDetails(String label, int count, String detail) {
    _showOperationsDetails(
      title: label,
      summary: '$count outstanding signal(s) • $detail',
      details: [
        'This count is taken from the current HPJ operational snapshot.',
        'Review the corresponding Orders, Products, Messages, Substitutions or Reliability workspace to act on individual records.',
        'Refresh after resolving items to see the updated total.',
      ],
    );
  }

  Widget _attentionRow({
    required IconData icon,
    required String label,
    required int count,
    required String detail,
    bool urgent = false,
  }) {
    final active = count > 0;

    final tone = urgent ? FarmColors.danger : FarmColors.warning;

    return InkWell(
      onTap: () => _showAttentionDetails(label, count, detail),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
        decoration: BoxDecoration(
          color: active
              ? urgent
                  ? FarmColors.dangerSoft
                  : FarmColors.warningSoft
              : FarmColors.cardSoft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active
                ? tone.withOpacity(.16)
                : FarmColors.line.withOpacity(.6),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 31,
              height: 31,
              decoration: BoxDecoration(
                color: active ? Colors.white.withOpacity(.75) : Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 17,
                color: active ? tone : FarmColors.mutedText,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
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
                    detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: FarmColors.mutedText,
                      fontSize: 9.7,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              constraints: const BoxConstraints(minWidth: 30),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: active ? FarmColors.deepGreen : FarmColors.mutedText,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusPill({
    required IconData icon,
    required String label,
    bool positive = false,
    bool warning = false,
    VoidCallback? onTap,
  }) {
    final background = warning
        ? FarmColors.warningSoft
        : positive
            ? FarmColors.primarySoft
            : FarmColors.cardSoft;

    final foreground = warning ? FarmColors.warning : FarmColors.deepGreen;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: foreground,
                fontSize: 9.8,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topHeader(
    HpjAudienceSnapshot audience,
    HpjNeedsAttentionSnapshot attention,
    HpjAppReleaseControl release,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 14, 12, 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: FarmColors.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.025),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: FarmColors.deepGreen,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.space_dashboard_rounded,
                  color: Colors.white,
                  size: 21,
                ),
              ),
              const SizedBox(width: 11),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Growth & Operations',
                      style: TextStyle(
                        color: FarmColors.ink,
                        fontSize: 20,
                        height: 1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Live signals for demand, operations and app health.',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: FarmColors.mutedText,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: 'Refresh',
                onPressed: _reload,
                icon: const Icon(Icons.refresh_rounded, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              _statusPill(
                icon: Icons.people_alt_outlined,
                label: '${audience.visitorsToday} visitors',
                positive: true,
                onTap: _openVisitorIntelligence,
              ),
              _statusPill(
                icon: attention.total > 0
                    ? Icons.notification_important_outlined
                    : Icons.check_circle_outline_rounded,
                label: attention.total > 0
                    ? '${attention.total} need attention'
                    : 'Operations clear',
                positive: attention.total == 0,
                warning: attention.total > 0,
                onTap: () => _showOperationsDetails(
                  title: 'Needs attention',
                  summary:
                      '${attention.total} operational signals require review',
                  details: [
                    'Bank transfers: ${attention.paymentReviews}',
                    'Orders preparing too long: ${attention.ordersPreparingTooLong}',
                    'Overdue orders: ${attention.overdueOrders}',
                    'Low stock: ${attention.lowStockProducts}',
                    'Unanswered messages: ${attention.unansweredMessages}',
                    'Replacement approvals: ${attention.pendingSubstitutions}',
                    'Platform errors (24h): ${attention.platformErrors24h}',
                  ],
                ),
              ),
              _statusPill(
                icon: Icons.android_rounded,
                label: 'Play build ${release.latestAndroidBuild}',
                positive: !release.forceLatestUpdate,
                warning: release.forceLatestUpdate,
                onTap: () => _showOperationsDetails(
                  title: 'Android release control',
                  summary: 'Google Play build ${release.latestAndroidBuild}',
                  details: [
                    'Minimum supported build: ${release.minAndroidBuild}',
                    'Latest build: ${release.latestAndroidBuild}',
                    'Force latest update: ${release.forceLatestUpdate ? 'ON' : 'OFF'}',
                    'Snooze window: ${release.snoozeHours} hours',
                  ],
                  manage: () => _manageReleaseControl(release),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _manageReleaseControl(HpjAppReleaseControl current) async {
    final minController =
        TextEditingController(text: '${current.minAndroidBuild}');

    final latestController =
        TextEditingController(text: '${current.latestAndroidBuild}');

    final titleController = TextEditingController(text: current.updateTitle);

    final messageController =
        TextEditingController(text: current.updateMessage);

    final snoozeController =
        TextEditingController(text: '${current.snoozeHours}');

    var forceLatest = current.forceLatestUpdate;

    var saving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> save() async {
              if (saving) return;

              final minBuild = int.tryParse(minController.text.trim());

              final latestBuild = int.tryParse(latestController.text.trim());

              final snooze = int.tryParse(snoozeController.text.trim());

              if (minBuild == null ||
                  latestBuild == null ||
                  latestBuild < minBuild) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Enter valid builds. Latest build must be at least the minimum build.'),
                  ),
                );

                return;
              }

              setDialogState(() => saving = true);

              try {
                await updateHpjAdminAppReleaseControl(
                  HpjAppReleaseControl(
                    minAndroidBuild: minBuild,
                    latestAndroidBuild: latestBuild,
                    forceLatestUpdate: forceLatest,
                    updateTitle: titleController.text.trim(),
                    updateMessage: messageController.text.trim(),
                    playStoreUrl: current.playStoreUrl,
                    snoozeHours: (snooze ?? 12).clamp(1, 168),
                  ),
                );

                if (!dialogContext.mounted) return;

                Navigator.of(dialogContext).pop();

                _reload();
              } catch (error) {
                if (!dialogContext.mounted) return;

                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(content: Text(friendlyAppError(error))),
                );
              } finally {
                if (dialogContext.mounted) {
                  setDialogState(() => saving = false);
                }
              }
            }

            return AlertDialog(
              title: const Text('App Update Control'),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: minController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Minimum supported build',
                                helperText: 'Builds below this must update.',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: latestController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Latest Play build',
                                helperText: 'Newest published build.',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: forceLatest,
                        title: const Text(
                            'Force everyone below latest build to update'),
                        subtitle: const Text(
                          'Use only for critical security, checkout or incompatible database releases.',
                        ),
                        onChanged: (value) =>
                            setDialogState(() => forceLatest = value),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: titleController,
                        decoration:
                            const InputDecoration(labelText: 'Update title'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: messageController,
                        maxLines: 3,
                        decoration:
                            const InputDecoration(labelText: 'Update message'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: snoozeController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Optional update snooze (hours)',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      saving ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton.icon(
                  onPressed: saving ? null : save,
                  icon: saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(saving ? 'Saving...' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _proposeSubstitution() async {
    try {
      final loaded = await Future.wait<dynamic>([
        fetchHpjSubstitutionOrderCandidates(),
        fetchAllProducts(),
      ]);

      if (!mounted) return;

      final orders =
          List<HpjSubstitutionOrderCandidate>.from(loaded[0] as List);

      final products = List<Product>.from(loaded[1] as List)
          .where((p) => p.canAddToCart && !p.isSampleProduct)
          .toList(growable: false);

      if (orders.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'No unpaid active orders are available for substitution.')),
        );

        return;
      }

      if (products.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'No live in-stock products are available as replacements.')),
        );

        return;
      }

      HpjSubstitutionOrderCandidate? selectedOrder;

      HpjSubstitutionOrderItemCandidate? selectedItem;

      Product? replacement;

      final noteController = TextEditingController();

      var saving = false;

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (sheetContext) {
          return StatefulBuilder(
            builder: (context, setSheetState) {
              final eligibleProducts = products
                  .where((p) =>
                      selectedItem == null || p.id != selectedItem!.productId)
                  .toList(growable: false);

              Future<void> save() async {
                if (saving ||
                    selectedOrder == null ||
                    selectedItem == null ||
                    replacement == null) return;

                setSheetState(() => saving = true);

                try {
                  await hpjAdminProposeOrderSubstitution(
                    orderId: selectedOrder!.orderId,
                    originalProductId: selectedItem!.productId,
                    replacementProductId: replacement!.id,
                    note: noteController.text,
                  );

                  if (!sheetContext.mounted) return;

                  Navigator.of(sheetContext).pop();

                  _reload();

                  if (mounted) {
                    ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Replacement proposal sent to the customer.')),
                    );
                  }
                } catch (error) {
                  if (!sheetContext.mounted) return;

                  ScaffoldMessenger.of(sheetContext).showSnackBar(
                    SnackBar(content: Text(friendlyAppError(error))),
                  );
                } finally {
                  if (sheetContext.mounted) setSheetState(() => saving = false);
                }
              }

              return Padding(
                padding: EdgeInsets.fromLTRB(
                  18,
                  6,
                  18,
                  18 + MediaQuery.viewInsetsOf(sheetContext).bottom,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Propose Fresh Item Replacement',
                        style: TextStyle(
                          color: FarmColors.ink,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'MVP safety: substitutions are whole-line changes and are only available before payment is verified.',
                        style: TextStyle(
                          color: FarmColors.mutedText,
                          fontSize: 12,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<HpjSubstitutionOrderCandidate>(
                        value: selectedOrder,
                        decoration: const InputDecoration(labelText: 'Order'),
                        items: orders
                            .map(
                              (o) => DropdownMenuItem(
                                value: o,
                                child: Text(
                                    '#${shortIdLabel(o.orderId)} • ${friendlyLabel(o.orderStatus)}'),
                              ),
                            )
                            .toList(),
                        onChanged: saving
                            ? null
                            : (value) {
                                setSheetState(() {
                                  selectedOrder = value;

                                  selectedItem = null;

                                  replacement = null;
                                });
                              },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<
                          HpjSubstitutionOrderItemCandidate>(
                        value: selectedItem,
                        decoration: const InputDecoration(
                            labelText: 'Unavailable order item'),
                        items: (selectedOrder?.items ??
                                const <HpjSubstitutionOrderItemCandidate>[])
                            .map(
                              (item) => DropdownMenuItem(
                                value: item,
                                child: Text(
                                    '${item.productName} × ${item.quantity}'),
                              ),
                            )
                            .toList(),
                        onChanged: selectedOrder == null || saving
                            ? null
                            : (value) {
                                setSheetState(() {
                                  selectedItem = value;

                                  replacement = null;
                                });
                              },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<Product>(
                        value: replacement,
                        isExpanded: true,
                        decoration: const InputDecoration(
                            labelText: 'Replacement product'),
                        items: eligibleProducts
                            .take(120)
                            .map(
                              (p) => DropdownMenuItem(
                                value: p,
                                child: Text(
                                    '${p.name} • ${p.formattedEffectivePrice} • ${p.stockQuantity} in stock'),
                              ),
                            )
                            .toList(),
                        onChanged: selectedItem == null || saving
                            ? null
                            : (value) =>
                                setSheetState(() => replacement = value),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: noteController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Message to customer (optional)',
                          hintText:
                              'Example: Scotch Bonnet from another approved Jamaican farm is available today.',
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: selectedOrder == null ||
                                  selectedItem == null ||
                                  replacement == null ||
                                  saving
                              ? null
                              : save,
                          icon: saving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.send_outlined),
                          label: Text(saving
                              ? 'Sending...'
                              : 'Send for customer approval'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyAppError(error))),
      );
    }
  }

  Widget _releaseCard(HpjAppReleaseControl control) {
    final forced = control.forceLatestUpdate;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: forced ? FarmColors.warningSoft : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: forced ? FarmColors.warning.withOpacity(.28) : FarmColors.line,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 39,
                height: 39,
                decoration: BoxDecoration(
                  color: forced ? Colors.white : FarmColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.system_update_alt_rounded,
                  color: forced ? FarmColors.warning : FarmColors.deepGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'App Release',
                      style: TextStyle(
                        color: FarmColors.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Android update control',
                      style: TextStyle(
                        color: FarmColors.mutedText,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: () => _manageReleaseControl(control),
                icon: const Icon(Icons.tune_rounded, size: 17),
                label: const Text('Manage'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = ((constraints.maxWidth - 14) / 3)
                  .clamp(88.0, 220.0)
                  .toDouble();

              return Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  _releaseStat(
                    width: itemWidth,
                    label: 'Minimum',
                    onTap: () => _showOperationsDetails(
                      title: 'Minimum',
                      summary:
                          'The oldest Android build currently allowed by your release policy.',
                      details: [
                        'Minimum build: ${control.minAndroidBuild}',
                        'Latest build: ${control.latestAndroidBuild}',
                        'Force update: ${control.forceLatestUpdate ? 'ON' : 'OFF'}',
                      ],
                      manage: () => _manageReleaseControl(control),
                    ),
                    value: '${control.minAndroidBuild}',
                    icon: Icons.security_update_warning_outlined,
                  ),
                  _releaseStat(
                    width: itemWidth,
                    label: 'Latest',
                    onTap: () => _showOperationsDetails(
                      title: 'Latest',
                      summary:
                          'The latest Android build configured in HPJ release control.',
                      details: [
                        'Minimum build: ${control.minAndroidBuild}',
                        'Latest build: ${control.latestAndroidBuild}',
                        'Force update: ${control.forceLatestUpdate ? 'ON' : 'OFF'}',
                      ],
                      manage: () => _manageReleaseControl(control),
                    ),
                    value: '${control.latestAndroidBuild}',
                    icon: Icons.new_releases_outlined,
                  ),
                  _releaseStat(
                    width: itemWidth,
                    label: 'Force update',
                    onTap: () => _showOperationsDetails(
                      title: 'Force update',
                      summary:
                          'When enabled, older app builds may be required to update.',
                      details: [
                        'Minimum build: ${control.minAndroidBuild}',
                        'Latest build: ${control.latestAndroidBuild}',
                        'Force update: ${control.forceLatestUpdate ? 'ON' : 'OFF'}',
                      ],
                      manage: () => _manageReleaseControl(control),
                    ),
                    value: forced ? 'ON' : 'OFF',
                    icon: Icons.shield_outlined,
                    warning: forced,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 9),
          Text(
            forced
                ? 'Critical update mode is active. Builds below the latest release must update.'
                : 'Normal update mode • users may snooze for ${control.snoozeHours} hours.',
            style: TextStyle(
              color: forced ? FarmColors.warning : FarmColors.mutedText,
              fontSize: 10,
              height: 1.3,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _releaseStat({
    required double width,
    required String label,
    required String value,
    required IconData icon,
    bool warning = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: FarmColors.line.withOpacity(.8)),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: warning ? FarmColors.warning : FarmColors.green,
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: FarmColors.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: FarmColors.mutedText,
                      fontSize: 9.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _substitutionSection(List<HpjOrderSubstitution> substitutions) {
    final pending = substitutions.where((s) => s.awaitingCustomer).toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: FarmColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            'Fresh Substitutions',
            pending.isEmpty
                ? 'No customer decisions are waiting.'
                : '${pending.length} waiting for customer approval.',
            icon: Icons.swap_horiz_rounded,
            trailing: IconButton.filledTonal(
              tooltip: 'Propose substitution',
              onPressed: _proposeSubstitution,
              icon: const Icon(Icons.add_rounded, size: 19),
            ),
          ),
          const SizedBox(height: 11),
          if (substitutions.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: FarmColors.cardSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'No substitution records yet.',
                style: TextStyle(
                  color: FarmColors.mutedText,
                  fontSize: 10.8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            for (final item in substitutions.take(6)) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 7),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                decoration: BoxDecoration(
                  color: item.awaitingCustomer
                      ? FarmColors.warningSoft
                      : FarmColors.cardSoft,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '#${shortIdLabel(item.orderId)} • ${item.originalProductName} → ${item.replacementProductName}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: FarmColors.ink,
                              fontSize: 10.8,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${item.quantity} item(s) • ${formatJmd(item.replacementLineTotal)}',
                            style: const TextStyle(
                              color: FarmColors.mutedText,
                              fontSize: 9.6,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _statusPill(
                      icon: item.awaitingCustomer
                          ? Icons.schedule_rounded
                          : Icons.check_circle_outline_rounded,
                      label: friendlyLabel(item.status),
                      positive: !item.awaitingCustomer,
                      warning: item.awaitingCustomer,
                    ),
                  ],
                ),
              ),
            ],
        ],
      ),
    );
  }

  Future<void> _editReliabilityIssue(Map<String, dynamic> event) async {
    final key = hpjReliabilityIssueKey(event);
    final existing = _issueRecords[key] ?? const <String, dynamic>{};
    var status = (existing['status'] ?? 'new').toString();
    if (!{'new', 'investigating', 'resolved', 'reopened'}.contains(status)) {
      status = 'new';
    }
    final note =
        TextEditingController(text: (existing['admin_note'] ?? '').toString());
    final owner =
        TextEditingController(text: (existing['assigned_to'] ?? '').toString());
    var saving = false;
    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, updateDialog) => AlertDialog(
            title: const Text('Manage reliability issue'),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(key, style: const TextStyle(fontSize: 11)),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: status,
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: const [
                          DropdownMenuItem(value: 'new', child: Text('New')),
                          DropdownMenuItem(
                              value: 'investigating',
                              child: Text('Investigating')),
                          DropdownMenuItem(
                              value: 'resolved', child: Text('Resolved')),
                          DropdownMenuItem(
                              value: 'reopened', child: Text('Reopened')),
                        ],
                        onChanged: saving
                            ? null
                            : (value) {
                                if (value != null)
                                  updateDialog(() => status = value);
                              },
                      ),
                      const SizedBox(height: 10),
                      TextField(
                          controller: owner,
                          decoration: const InputDecoration(
                              labelText: 'Assigned to (name)')),
                      const SizedBox(height: 10),
                      TextField(
                          controller: note,
                          maxLines: 4,
                          decoration: const InputDecoration(
                              labelText: 'Investigation notes')),
                    ]),
              ),
            ),
            actions: [
              TextButton(
                  onPressed: saving ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel')),
              FilledButton(
                  onPressed: saving
                      ? null
                      : () async {
                          updateDialog(() => saving = true);
                          try {
                            await saveHpjReliabilityIssue(
                                issueKey: key,
                                status: status,
                                note: note.text,
                                assignedTo: owner.text);
                            if (dialogContext.mounted)
                              Navigator.pop(dialogContext);
                            await _loadReliabilityIssues();
                          } catch (error) {
                            if (dialogContext.mounted) {
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'Could not save issue: $error')));
                              updateDialog(() => saving = false);
                            }
                          }
                        },
                  child: Text(saving ? 'Saving…' : 'Save issue')),
            ],
          ),
        ),
      );
    } finally {
      // Defer disposal until the dialog's closing animation has completed.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        note.dispose();
        owner.dispose();
      });
    }
  }

  Future<void> _openHpjHealthReport(Map<String, dynamic> event) async {
    final rawMetadata = event['metadata'];
    final metadata = rawMetadata is Map
        ? Map<String, dynamic>.from(rawMetadata)
        : <String, dynamic>{};
    String field(String key, [String fallback = 'Not recorded']) {
      final value = event[key] ?? metadata[key];
      final result = value?.toString().trim() ?? '';
      return result.isEmpty ? fallback : result;
    }

    final severity = field('severity');
    final area = field('area');
    final eventKey = field('event_key');
    final message = field('message');
    final captured = field('created_at', field('captured_at_client'));
    final stack = field('stack_trace', 'No stack trace recorded');
    final report = <String>[
      'HPJ RELIABILITY REPORT',
      'Severity: $severity',
      'Area: $area',
      'Event: $eventKey',
      'Time: $captured',
      'Platform: ${field('platform')}',
      'Version: ${field('app_version')}',
      'Build: ${field('build_number')}',
      'Message: $message',
      'Stack trace: $stack',
      'Metadata: $metadata',
    ].join('\n');

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reliability event details'),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: SelectableText(report),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _editReliabilityIssue(event);
            },
            icon: const Icon(Icons.assignment_turned_in_outlined),
            label: const Text('Manage issue'),
          ),
          TextButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: report));
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reliability report copied')),
              );
            },
            icon: const Icon(Icons.copy_outlined),
            label: const Text('Copy report'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Phase 3: local investigation tools. No new database tables required.
  DateTime? _healthTimestamp(Map<String, dynamic> row) {
    final metadata = row['metadata'];
    final fallback = metadata is Map ? metadata['captured_at_client'] : null;
    return DateTime.tryParse((row['created_at'] ?? fallback ?? '').toString());
  }

  String _healthSeverity(Map<String, dynamic> row) =>
      (row['severity'] ?? '').toString().toLowerCase();

  List<Map<String, dynamic>> _visibleHealthSignals(
      HpjPlatformHealthSnapshot health) {
    final now = DateTime.now();
    final filtered = health.recent.where((row) {
      final severity = _healthSeverity(row);
      if (_healthFilter == 'fatal' &&
          severity != 'fatal' &&
          severity != 'critical') return false;
      if (_healthFilter == 'error' && severity != 'error') return false;
      if (_healthFilter == 'warning' &&
          severity != 'warning' &&
          severity != 'warn') return false;
      if (_healthFilter == '24h') {
        final time = _healthTimestamp(row);
        if (time == null ||
            now.difference(time).inHours >= 24 ||
            time.isAfter(now)) return false;
      }
      return true;
    }).toList();
    filtered.sort((a, b) {
      final at = _healthTimestamp(a);
      final bt = _healthTimestamp(b);
      if (at == null) return bt == null ? 0 : 1;
      if (bt == null) return -1;
      return bt.compareTo(at);
    });
    if (!_groupHealthSignals) return filtered;
    final grouped = <String, Map<String, dynamic>>{};
    for (final row in filtered) {
      final key =
          '${row['area'] ?? 'app'}|${row['event_key'] ?? row['message'] ?? 'unknown'}|${_healthSeverity(row)}';
      if (grouped.containsKey(key)) {
        grouped[key]!['_phase3_count'] =
            (grouped[key]!['_phase3_count'] as int) + 1;
      } else {
        grouped[key] = {...row, '_phase3_count': 1};
      }
    }
    return grouped.values.toList();
  }

  Widget _healthSection(HpjPlatformHealthSnapshot health) {
    final healthy = health.errors24h == 0 && health.fatals24h == 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: FarmColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            'Reliability',
            healthy
                ? 'No critical health signals in the last 24 hours.'
                : '${health.errors24h + health.fatals24h} health signal(s) need review.',
            icon: Icons.monitor_heart_outlined,
            trailing: _statusPill(
              icon: healthy
                  ? Icons.check_circle_rounded
                  : Icons.warning_amber_rounded,
              label: healthy ? 'Healthy' : 'Review',
              positive: healthy,
              warning: !healthy,
            ),
          ),
          const SizedBox(height: 11),
          LayoutBuilder(
            builder: (context, constraints) {
              final tileWidth = constraints.maxWidth >= 620
                  ? (constraints.maxWidth - 16) / 3
                  : (constraints.maxWidth - 8) / 2;

              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _metric(
                    width: tileWidth,
                    label: 'Errors • 24h',
                    value: '${health.errors24h}',
                    detail: 'Caught failures',
                    icon: Icons.error_outline_rounded,
                  ),
                  _metric(
                    width: tileWidth,
                    label: 'Fatal • 24h',
                    value: '${health.fatals24h}',
                    detail: 'Critical failures',
                    icon: Icons.crisis_alert_outlined,
                  ),
                  _metric(
                    width: tileWidth,
                    label: 'Health events',
                    value: '${health.eventsPeriod}',
                    detail: 'Last ${health.days} days',
                    icon: Icons.timeline_outlined,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          if (_issuesLoading) const LinearProgressIndicator(),
          if (_issueLoadError != null)
            Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                    'Issue tracking unavailable. Run Phase 4 SQL and check admin access. $_issueLoadError',
                    style: const TextStyle(color: Colors.red, fontSize: 10))),
          TextButton.icon(
              onPressed: _issuesLoading ? null : _loadReliabilityIssues,
              icon: const Icon(Icons.sync_rounded, size: 16),
              label: const Text('Refresh issue statuses')),
          const Text('Investigate signals',
              style: TextStyle(
                  color: FarmColors.ink,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              for (final choice in const <String, String>{
                'all': 'All',
                'fatal': 'Fatal',
                'error': 'Errors',
                'warning': 'Warnings',
                '24h': 'Last 24h',
              }.entries)
                ChoiceChip(
                  label: Text(choice.value),
                  selected: _healthFilter == choice.key,
                  onSelected: (_) => setState(() => _healthFilter = choice.key),
                ),
              FilterChip(
                label: const Text('Group repeats'),
                selected: _groupHealthSignals,
                onSelected: (value) =>
                    setState(() => _groupHealthSignals = value),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_visibleHealthSignals(health).isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('No signals match this filter.',
                  style: TextStyle(color: FarmColors.mutedText)),
            ),
          for (final row in (_showAllHealthSignals
              ? _visibleHealthSignals(health)
              : _visibleHealthSignals(health).take(8)))
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Material(
                color: FarmColors.cardSoft,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _openHpjHealthReport(row),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                    child: Row(
                      children: [
                        Icon(
                          _healthSeverity(row) == 'fatal' ||
                                  _healthSeverity(row) == 'critical'
                              ? Icons.report_rounded
                              : Icons.bug_report_outlined,
                          color: _healthSeverity(row) == 'fatal' ||
                                  _healthSeverity(row) == 'critical'
                              ? Colors.red.shade700
                              : FarmColors.deepGreen,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${row['area'] ?? 'app'} • ${row['event_key'] ?? 'event'}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: FarmColors.ink,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                '${row['message'] ?? 'No message'}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: FarmColors.mutedText,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if ((row['_phase3_count'] ?? 1) != 1)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Text('×${row['_phase3_count']}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w900)),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(right: 5),
                          child: Text(
                            (_issueRecords[hpjReliabilityIssueKey(row)]
                                        ?['status'] ??
                                    'new')
                                .toString()
                                .toUpperCase(),
                            style: const TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                color: FarmColors.deepGreen),
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            color: FarmColors.deepGreen, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (_visibleHealthSignals(health).length > 8)
            TextButton.icon(
              onPressed: () => setState(
                  () => _showAllHealthSignals = !_showAllHealthSignals),
              icon: Icon(_showAllHealthSignals
                  ? Icons.expand_less_rounded
                  : Icons.expand_more_rounded),
              label: Text(_showAllHealthSignals
                  ? 'Show fewer signals'
                  : 'Show all ${_visibleHealthSignals(health).length} signals'),
            ),
        ],
      ),
    );
  }

  Widget _audienceSection(HpjAudienceSnapshot audience) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: FarmColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            'Audience & Conversion',
            'Live customer activity across web and Android.',
            icon: Icons.groups_2_outlined,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final value in const [7, 30, 90])
                ChoiceChip(
                  label: Text(
                    value == 7
                        ? '7 days'
                        : value == 30
                            ? '30 days'
                            : '90 days',
                  ),
                  selected: _days == value,
                  onSelected: (_) {
                    if (_days == value) return;

                    setState(() {
                      _days = value;

                      _future = _load();
                    });
                  },
                  visualDensity: VisualDensity.compact,
                  labelStyle: TextStyle(
                    color: _days == value ? Colors.white : FarmColors.deepGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                  selectedColor: FarmColors.deepGreen,
                  backgroundColor: FarmColors.cardSoft,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 11),
          LayoutBuilder(
            builder: (context, constraints) {
              final tileWidth = constraints.maxWidth >= 760
                  ? (constraints.maxWidth - 24) / 4
                  : (constraints.maxWidth - 8) / 2;

              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _metric(
                    width: tileWidth,
                    label: 'Visitors today',
                    value: '${audience.visitorsToday}',
                    detail: 'Unique estimate',
                    icon: Icons.today_outlined,
                  ),
                  _metric(
                    width: tileWidth,
                    label: 'Active now',
                    value: '${audience.activeNow}',
                    detail: 'About 5 minutes',
                    icon: Icons.online_prediction_outlined,
                  ),
                  _metric(
                    width: tileWidth,
                    label: 'Conversion',
                    value: '${audience.conversionPct.toStringAsFixed(1)}%',
                    detail: 'Visitors → orders',
                    icon: Icons.trending_up_rounded,
                  ),
                  _metric(
                    width: tileWidth,
                    label: 'Orders',
                    value: '${audience.ordersCompleted}',
                    detail: 'Completed checkout',
                    icon: Icons.receipt_long_outlined,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              _miniSignal(
                Icons.language_rounded,
                'Web',
                '${audience.webVisitors}',
              ),
              _miniSignal(
                Icons.android_rounded,
                'Android',
                '${audience.androidVisitors}',
              ),
              _miniSignal(
                Icons.shopping_cart_checkout_outlined,
                'Checkout',
                '${audience.checkoutStarts}',
              ),
              _miniSignal(
                Icons.replay_rounded,
                'Returning',
                '${audience.returningVisitors}',
              ),
              _miniSignal(
                Icons.person_add_alt_1_outlined,
                'New',
                '${audience.newVisitors}',
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openVisitorIntelligence,
              icon: const Icon(Icons.public_rounded, size: 17),
              label: const Text('Visitor locations & behaviour'),
            ),
          ),
          if (audience.appVersions.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),
            const Text(
              'Android adoption',
              style: TextStyle(
                color: FarmColors.ink,
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: audience.appVersions.take(6).map((row) {
                return _statusPill(
                  icon: Icons.android_rounded,
                  label:
                      '${row['version'] ?? 'Unknown'} (${row['build'] ?? 0}) • ${row['visitors'] ?? 0}',
                  positive: true,
                );
              }).toList(growable: false),
            ),
          ],
        ],
      ),
    );
  }

  // Location is voluntarily supplied; never infer a street address.
  Future<void> _openVisitorIntelligence() async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: .88,
        child: _HpjVisitorIntelligencePanel(days: _days),
      ),
    );
  }

  Widget _miniSignal(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: FarmColors.cardSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: FarmColors.green),
          const SizedBox(width: 6),
          Text(
            '$label ',
            style: const TextStyle(
              color: FarmColors.mutedText,
              fontSize: 9.8,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: FarmColors.ink,
              fontSize: 10.2,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _attentionSection(HpjNeedsAttentionSnapshot attention) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: attention.total > 0
              ? FarmColors.warning.withOpacity(.28)
              : FarmColors.line,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            'Needs Attention',
            attention.total == 0
                ? 'No current operational exceptions.'
                : '${attention.total} signal(s) need review.',
            icon: Icons.notification_important_outlined,
            trailing: _statusPill(
              icon: attention.total == 0
                  ? Icons.check_circle_outline_rounded
                  : Icons.priority_high_rounded,
              label: attention.total == 0 ? 'Clear' : '${attention.total}',
              positive: attention.total == 0,
              warning: attention.total > 0,
            ),
          ),
          const SizedBox(height: 11),
          _attentionRow(
            icon: Icons.payments_outlined,
            label: 'Bank transfer reviews',
            count: attention.paymentReviews,
            detail: 'Payment verification waiting',
          ),
          const SizedBox(height: 6),
          _attentionRow(
            icon: Icons.timer_outlined,
            label: 'Orders preparing too long',
            count: attention.ordersPreparingTooLong,
            detail: 'Preparing for more than 4 hours',
            urgent: true,
          ),
          const SizedBox(height: 6),
          _attentionRow(
            icon: Icons.event_busy_outlined,
            label: 'Overdue orders',
            count: attention.overdueOrders,
            detail: 'Scheduled date passed',
            urgent: true,
          ),
          const SizedBox(height: 6),
          _attentionRow(
            icon: Icons.inventory_2_outlined,
            label: 'Low-stock live products',
            count: attention.lowStockProducts,
            detail: '5 or fewer units',
          ),
          const SizedBox(height: 6),
          _attentionRow(
            icon: Icons.mark_chat_unread_outlined,
            label: 'Customer messages',
            count: attention.unansweredMessages,
            detail: 'Waiting for staff reply',
          ),
          const SizedBox(height: 6),
          _attentionRow(
            icon: Icons.swap_horiz_rounded,
            label: 'Replacement approvals',
            count: attention.pendingSubstitutions,
            detail: 'Customer decision pending',
          ),
          const SizedBox(height: 6),
          _attentionRow(
            icon: Icons.monitor_heart_outlined,
            label: 'Platform errors',
            count: attention.platformErrors24h,
            detail: 'Last 24 hours',
            urgent: true,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            snapshot.data == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.dashboard_customize_outlined,
                    size: 42,
                    color: FarmColors.mutedText,
                  ),
                  const SizedBox(height: 11),
                  const Text(
                    'Growth & Operations is not ready yet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: FarmColors.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    friendlyAppError(snapshot.error!),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: FarmColors.mutedText,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 13),
                  FilledButton.icon(
                    onPressed: _reload,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Try again'),
                  ),
                ],
              ),
            ),
          );
        }

        final data = snapshot.data!;

        final audience = data[0] as HpjAudienceSnapshot;

        final attention = data[1] as HpjNeedsAttentionSnapshot;

        final health = data[2] as HpjPlatformHealthSnapshot;

        final substitutions = List<HpjOrderSubstitution>.from(data[3] as List);

        final release = data[4] as HpjAppReleaseControl;

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 110),
            children: [
              _topHeader(audience, attention, release),
              const SizedBox(height: 10),
              _releaseCard(release),
              const SizedBox(height: 10),
              _attentionSection(attention),
              const SizedBox(height: 10),
              _audienceSection(audience),
              const SizedBox(height: 10),
              _substitutionSection(substitutions),
              const SizedBox(height: 10),
              _healthSection(health),
            ],
          ),
        );
      },
    );
  }
}

// Standalone admin-only aggregate viewer. No raw IP addresses or precise GPS.
class _HpjVisitorIntelligencePanel extends StatefulWidget {
  final int days;
  const _HpjVisitorIntelligencePanel({required this.days});
  @override
  State<_HpjVisitorIntelligencePanel> createState() =>
      _HpjVisitorIntelligencePanelState();
}

class _HpjVisitorIntelligencePanelState
    extends State<_HpjVisitorIntelligencePanel> {
  late Future<Map<String, dynamic>> _report;
  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _report = _fetch();
    });
  }

  Future<Map<String, dynamic>> _fetch() async {
    final result = await Supabase.instance.client.rpc(
      'hpj_admin_visitor_intelligence',
      params: {'p_days': widget.days},
    );
    if (result is Map) return Map<String, dynamic>.from(result);
    if (result == null) {
      throw StateError(
          'No analytics report returned. Verify admin access and the Supabase reporting function.');
    }
    throw StateError(
        'Unexpected analytics response type: ${result.runtimeType}');
  }

  Widget _group(String title, dynamic raw, String nameKey) {
    final items = raw is List ? raw : const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 15, bottom: 8),
          child: Text(title,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15,
              )),
        ),
        if (items.isEmpty)
          const Text('No tracked data yet.',
              style: TextStyle(color: Colors.black54))
        else
          ...items.take(12).map((item) {
            final row = item is Map ? item : <String, dynamic>{};
            final name = (row[nameKey] ?? 'Unknown').toString();
            final count = (row['visitors'] ?? row['events'] ?? 0).toString();
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(name),
              trailing: Text(count,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            );
          }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Expanded(
                  child: Text('Visitor Intelligence',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w900))),
              IconButton(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh'),
              IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  tooltip: 'Close'),
            ]),
            Text('Last ${widget.days} days • aggregated visitor activity',
                style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 10),
            Expanded(
                child: FutureBuilder<Map<String, dynamic>>(
              future: _report,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return ListView(children: [
                    const Text('Visitor analytics are not available yet.',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('${snapshot.error}'),
                    const SizedBox(height: 8),
                    const Text('Run the included SQL migration and ensure '
                        'your account has admin access.'),
                  ]);
                }
                final report = snapshot.data ?? {};
                return ListView(children: [
                  Card(
                      child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            '${report['unique_visitors'] ?? 0} tracked visitors',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18)),
                        Text('${report['total_events'] ?? 0} tracked events'),
                        const SizedBox(height: 6),
                        const Text(
                            'Location is self-reported and optional. '
                            'Unknown locations are shown separately; '
                            'these counts may differ from existing audience estimates.',
                            style:
                                TextStyle(fontSize: 12, color: Colors.black54)),
                      ],
                    ),
                  )),
                  _group('Countries', report['countries'], 'country'),
                  _group('Jamaican parishes / regions', report['parishes'],
                      'parish'),
                  _group('Visitor actions', report['actions'], 'event_name'),
                  _group(
                      'Platforms / devices', report['platforms'], 'platform'),
                  const SizedBox(height: 12),
                  const Text(
                      'Privacy: No exact address, GPS coordinates, '
                      'or IP address is stored by this feature. '
                      'Only authenticated, opted-in activity is included.',
                      style: TextStyle(fontSize: 12, color: Colors.black54)),
                ]);
              },
            )),
          ],
        ),
      ),
    );
  }
}
