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
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
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
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: FarmColors.primarySoft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: FarmColors.deepGreen, size: 21),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: FarmColors.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: FarmColors.mutedText,
                  fontSize: 12.2,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
  }) {
    return Container(
      width: 176,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: FarmColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: FarmColors.green, size: 20),
          const SizedBox(height: 9),
          Text(
            value,
            style: const TextStyle(
              color: FarmColors.ink,
              fontSize: 22,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(
              color: FarmColors.deepGreen,
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            detail,
            style: const TextStyle(
              color: FarmColors.mutedText,
              fontSize: 10.4,
              height: 1.25,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _attentionRow({
    required IconData icon,
    required String label,
    required int count,
    required String detail,
    bool urgent = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: count > 0
            ? urgent
                ? FarmColors.dangerSoft
                : FarmColors.warningSoft
            : FarmColors.cardSoft,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 19,
            color: count > 0
                ? urgent
                    ? FarmColors.danger
                    : FarmColors.warning
                : FarmColors.mutedText,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: FarmColors.ink,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: const TextStyle(
                    color: FarmColors.mutedText,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 32),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: count > 0 ? FarmColors.deepGreen : FarmColors.mutedText,
                fontWeight: FontWeight.w900,
              ),
            ),
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
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: FarmColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            'App Update Control',
            'Control the minimum supported Android build without publishing another emergency code change.',
            icon: Icons.system_update_alt_rounded,
            trailing: FilledButton.tonalIcon(
              onPressed: () => _manageReleaseControl(control),
              icon: const Icon(Icons.tune_rounded, size: 18),
              label: const Text('Manage'),
            ),
          ),
          const SizedBox(height: 13),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _metric(
                label: 'Minimum build',
                value: '${control.minAndroidBuild}',
                detail: 'Older builds must update',
                icon: Icons.security_update_warning_outlined,
              ),
              _metric(
                label: 'Latest build',
                value: '${control.latestAndroidBuild}',
                detail: 'Current Play release',
                icon: Icons.new_releases_outlined,
              ),
              _metric(
                label: 'Force latest',
                value: control.forceLatestUpdate ? 'ON' : 'OFF',
                detail: control.forceLatestUpdate
                    ? 'Critical update mode'
                    : 'Normal optional updates',
                icon: Icons.shield_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _substitutionSection(List<HpjOrderSubstitution> substitutions) {
    final pending = substitutions.where((s) => s.awaitingCustomer).toList();
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: FarmColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            'Fresh Produce Substitutions',
            'Offer a live replacement when fresh supply changes. The customer must approve before HPJ changes the order.',
            icon: Icons.swap_horiz_rounded,
            trailing: FilledButton.icon(
              onPressed: _proposeSubstitution,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Propose'),
            ),
          ),
          const SizedBox(height: 13),
          if (substitutions.isEmpty)
            const Text(
              'No substitution records yet.',
              style: TextStyle(
                  color: FarmColors.mutedText, fontWeight: FontWeight.w700),
            )
          else ...[
            Text(
              '${pending.length} awaiting customer approval',
              style: const TextStyle(
                color: FarmColors.deepGreen,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 9),
            for (final item in substitutions.take(8)) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 7),
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: item.awaitingCustomer
                      ? FarmColors.warningSoft
                      : FarmColors.cardSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '#${shortIdLabel(item.orderId)} • ${item.originalProductName} → ${item.replacementProductName}',
                            style: const TextStyle(
                              color: FarmColors.ink,
                              fontSize: 11.8,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${item.quantity} item(s) • ${formatJmd(item.replacementLineTotal)} replacement line',
                            style: const TextStyle(
                              color: FarmColors.mutedText,
                              fontSize: 10.4,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      friendlyLabel(item.status),
                      style: TextStyle(
                        color: item.awaitingCustomer
                            ? FarmColors.warning
                            : FarmColors.green,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _healthSection(HpjPlatformHealthSnapshot health) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: FarmColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            'Platform Health',
            'Crashlytics provides detailed Android crash diagnostics; HPJ keeps this compact operational view for recent caught failures.',
            icon: Icons.monitor_heart_outlined,
          ),
          const SizedBox(height: 13),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _metric(
                label: 'Errors • 24h',
                value: '${health.errors24h}',
                detail: 'Caught operational failures',
                icon: Icons.error_outline_rounded,
              ),
              _metric(
                label: 'Fatal • 24h',
                value: '${health.fatals24h}',
                detail: 'Requires immediate review',
                icon: Icons.crisis_alert_outlined,
              ),
              _metric(
                label: 'Health events',
                value: '${health.eventsPeriod}',
                detail: 'Last ${health.days} days',
                icon: Icons.timeline_outlined,
              ),
            ],
          ),
          if (health.recent.isNotEmpty) ...[
            const SizedBox(height: 13),
            const Text(
              'Recent',
              style:
                  TextStyle(color: FarmColors.ink, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 7),
            for (final row in health.recent.take(6)) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      (row['severity'] ?? '').toString() == 'fatal'
                          ? Icons.crisis_alert_outlined
                          : Icons.warning_amber_rounded,
                      size: 17,
                      color: (row['severity'] ?? '').toString() == 'fatal'
                          ? FarmColors.danger
                          : FarmColors.warning,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${row['area'] ?? 'app'} • ${row['event_key'] ?? 'event'}\n${row['message'] ?? ''}',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: FarmColors.mutedText,
                          fontSize: 10.5,
                          height: 1.3,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _audienceSection(HpjAudienceSnapshot audience) {
    return Container(
      padding: const EdgeInsets.all(15),
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
            'Unique visitor/session estimates across the HPJ website and Android app. Anonymous visitors are aggregate estimates, not identity tracking.',
            icon: Icons.groups_2_outlined,
            trailing: PopupMenuButton<int>(
              initialValue: _days,
              onSelected: (value) {
                setState(() {
                  _days = value;
                  _future = _load();
                });
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 7, child: Text('Last 7 days')),
                PopupMenuItem(value: 30, child: Text('Last 30 days')),
                PopupMenuItem(value: 90, child: Text('Last 90 days')),
              ],
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: FarmColors.cardSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${audience.days} days',
                  style: const TextStyle(
                    color: FarmColors.deepGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 13),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _metric(
                label: 'Visitors today',
                value: '${audience.visitorsToday}',
                detail: 'Unique visitor estimate',
                icon: Icons.today_outlined,
              ),
              _metric(
                label: 'Active now',
                value: '${audience.activeNow}',
                detail: 'Active in about 5 minutes',
                icon: Icons.online_prediction_outlined,
              ),
              _metric(
                label: 'Website',
                value: '${audience.webVisitors}',
                detail: 'Unique web visitors',
                icon: Icons.language_rounded,
              ),
              _metric(
                label: 'Android',
                value: '${audience.androidVisitors}',
                detail: 'Unique app visitors',
                icon: Icons.android_rounded,
              ),
              _metric(
                label: 'Checkout starts',
                value: '${audience.checkoutStarts}',
                detail: 'Purchase intent',
                icon: Icons.shopping_cart_checkout_outlined,
              ),
              _metric(
                label: 'Orders',
                value: '${audience.ordersCompleted}',
                detail: 'Completed checkout events',
                icon: Icons.receipt_long_outlined,
              ),
              _metric(
                label: 'Conversion',
                value: '${audience.conversionPct.toStringAsFixed(1)}%',
                detail: 'Visitors → orders',
                icon: Icons.trending_up_rounded,
              ),
              _metric(
                label: 'Returning',
                value: '${audience.returningVisitors}',
                detail: '${audience.newVisitors} new visitors',
                icon: Icons.replay_rounded,
              ),
            ],
          ),
          if (audience.appVersions.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),
            const Text(
              'Android version adoption',
              style: TextStyle(
                color: FarmColors.ink,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: audience.appVersions.map((row) {
                return Chip(
                  avatar: const Icon(Icons.android_rounded, size: 16),
                  label: Text(
                    '${row['version'] ?? 'Unknown'} (${row['build'] ?? 0}) • ${row['visitors'] ?? 0}',
                  ),
                );
              }).toList(growable: false),
            ),
          ],
        ],
      ),
    );
  }

  Widget _attentionSection(HpjNeedsAttentionSnapshot attention) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: attention.total > 0
              ? FarmColors.warning.withOpacity(.32)
              : FarmColors.line,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            'Needs Attention',
            attention.total == 0
                ? 'No current operational exception was detected by this MVP snapshot.'
                : '${attention.total} operational signal(s) need review.',
            icon: Icons.notification_important_outlined,
          ),
          const SizedBox(height: 13),
          _attentionRow(
            icon: Icons.payments_outlined,
            label: 'Bank transfer reviews',
            count: attention.paymentReviews,
            detail: 'Payment verification waiting',
          ),
          const SizedBox(height: 7),
          _attentionRow(
            icon: Icons.timer_outlined,
            label: 'Orders preparing too long',
            count: attention.ordersPreparingTooLong,
            detail: 'Preparing for more than 4 hours',
            urgent: true,
          ),
          const SizedBox(height: 7),
          _attentionRow(
            icon: Icons.event_busy_outlined,
            label: 'Overdue orders',
            count: attention.overdueOrders,
            detail: 'Scheduled date passed without completion',
            urgent: true,
          ),
          const SizedBox(height: 7),
          _attentionRow(
            icon: Icons.inventory_2_outlined,
            label: 'Low-stock live products',
            count: attention.lowStockProducts,
            detail: '5 or fewer units; samples excluded',
          ),
          const SizedBox(height: 7),
          _attentionRow(
            icon: Icons.mark_chat_unread_outlined,
            label: 'Customer messages',
            count: attention.unansweredMessages,
            detail: 'Customer Care waiting for staff',
          ),
          const SizedBox(height: 7),
          _attentionRow(
            icon: Icons.swap_horiz_rounded,
            label: 'Replacement approvals',
            count: attention.pendingSubstitutions,
            detail: 'Customers deciding on fresh-item substitutions',
          ),
          const SizedBox(height: 7),
          _attentionRow(
            icon: Icons.monitor_heart_outlined,
            label: 'Platform errors',
            count: attention.platformErrors24h,
            detail: 'Caught error/fatal health signals in 24 hours',
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
                  const Icon(Icons.dashboard_customize_outlined,
                      size: 44, color: FarmColors.mutedText),
                  const SizedBox(height: 12),
                  const Text(
                    'Growth & Operations is not ready yet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: FarmColors.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Run RUN_ALL_HPJ_9_10_MVP_PRODUCTION_UPGRADE.sql in Supabase, then refresh.\n\n${friendlyAppError(snapshot.error!)}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: FarmColors.mutedText, height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: _reload,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Refresh'),
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: FarmColors.deepGreen,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HPJ 9/10 MVP CONTROL CENTER',
                      style: TextStyle(
                        color: Color(0xFFD6E8D2),
                        fontSize: 10.5,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Growth & Operations',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        height: 1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 7),
                    Text(
                      'Know who is visiting, what needs attention, which app versions are active, and where fresh-supply exceptions need a decision.',
                      style: TextStyle(
                        color: Color(0xFFE3EEE0),
                        fontSize: 12.5,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _audienceSection(audience),
              const SizedBox(height: 14),
              _attentionSection(attention),
              const SizedBox(height: 14),
              _substitutionSection(substitutions),
              const SizedBox(height: 14),
              _releaseCard(release),
              const SizedBox(height: 14),
              _healthSection(health),
            ],
          ),
        );
      },
    );
  }
}
