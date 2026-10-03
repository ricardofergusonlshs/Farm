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

  Widget _attentionRow({
    required IconData icon,
    required String label,
    required int count,
    required String detail,
    bool urgent = false,
  }) {
    final active = count > 0;
    final tone = urgent ? FarmColors.danger : FarmColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: active
            ? urgent
                ? FarmColors.dangerSoft
                : FarmColors.warningSoft
            : FarmColors.cardSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color:
              active ? tone.withOpacity(.16) : FarmColors.line.withOpacity(.6),
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
    );
  }

  Widget _statusPill({
    required IconData icon,
    required String label,
    bool positive = false,
    bool warning = false,
  }) {
    final background = warning
        ? FarmColors.warningSoft
        : positive
            ? FarmColors.primarySoft
            : FarmColors.cardSoft;
    final foreground = warning ? FarmColors.warning : FarmColors.deepGreen;

    return Container(
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
              ),
              _statusPill(
                icon: Icons.android_rounded,
                label: 'Play build ${release.latestAndroidBuild}',
                positive: !release.forceLatestUpdate,
                warning: release.forceLatestUpdate,
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
                    value: '${control.minAndroidBuild}',
                    icon: Icons.security_update_warning_outlined,
                  ),
                  _releaseStat(
                    width: itemWidth,
                    label: 'Latest',
                    value: '${control.latestAndroidBuild}',
                    icon: Icons.new_releases_outlined,
                  ),
                  _releaseStat(
                    width: itemWidth,
                    label: 'Force update',
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
  }) {
    return Container(
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
          if (health.recent.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Recent signals',
              style: TextStyle(
                color: FarmColors.ink,
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            for (final row in health.recent.take(4))
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: FarmColors.cardSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${row['area'] ?? 'app'} • ${row['event_key'] ?? 'event'} — ${row['message'] ?? ''}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: FarmColors.mutedText,
                    fontSize: 9.8,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
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
