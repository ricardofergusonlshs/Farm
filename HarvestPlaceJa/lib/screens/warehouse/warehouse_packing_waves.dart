part of harvest_place_app;

// ================================================================
// THE HARVEST PLACE JA
// PHASE 3AC — PACKING WAVES
//
// A packing wave groups existing wholesale fulfilments for coordinated
// warehouse work. It does not duplicate fulfilment lines or inventory issue.
// ================================================================

class WarehousePackingWaveCandidate {
  final String fulfillmentId;
  final String requestId;
  final String businessName;
  final DateTime? requestedDate;
  final String requestedWindowLabel;
  final String dispatchMethod;
  final String fulfillmentStatus;
  final int totalItems;
  final int accountedItems;
  final double packingProgress;

  const WarehousePackingWaveCandidate({
    required this.fulfillmentId,
    required this.requestId,
    required this.businessName,
    required this.requestedDate,
    required this.requestedWindowLabel,
    required this.dispatchMethod,
    required this.fulfillmentStatus,
    required this.totalItems,
    required this.accountedItems,
    required this.packingProgress,
  });

  factory WarehousePackingWaveCandidate.fromSupabase(
    Map<String, dynamic> data,
  ) {
    return WarehousePackingWaveCandidate(
      fulfillmentId: (data['fulfillment_id'] ?? '').toString(),
      requestId: (data['request_id'] ?? '').toString(),
      businessName:
          (data['business_name'] ?? 'Wholesale business').toString().trim(),
      requestedDate:
          DateTime.tryParse((data['requested_date'] ?? '').toString()),
      requestedWindowLabel:
          (data['requested_window_label'] ?? '').toString().trim(),
      dispatchMethod:
          (data['dispatch_method'] ?? 'hpj_delivery').toString().trim(),
      fulfillmentStatus:
          (data['fulfillment_status'] ?? '').toString().trim().toLowerCase(),
      totalItems: _packingWaveInt(data['total_items']),
      accountedItems: _packingWaveInt(data['accounted_items']),
      packingProgress: _packingWaveDouble(data['packing_progress']),
    );
  }

  String get statusLabel => _packingWaveFulfillmentStatus(fulfillmentStatus);
  String get shortRequestId => _packingWaveShortId(requestId);
}

class WarehousePackingWave {
  final String id;
  final String waveCode;
  final String title;
  final DateTime? plannedFor;
  final String status;
  final String notes;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final int totalFulfillments;
  final int readyForDispatch;
  final int packingFulfillments;
  final int preparingFulfillments;
  final double overallProgress;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const WarehousePackingWave({
    required this.id,
    required this.waveCode,
    required this.title,
    required this.plannedFor,
    required this.status,
    required this.notes,
    required this.startedAt,
    required this.completedAt,
    required this.cancelledAt,
    required this.totalFulfillments,
    required this.readyForDispatch,
    required this.packingFulfillments,
    required this.preparingFulfillments,
    required this.overallProgress,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WarehousePackingWave.fromSupabase(Map<String, dynamic> data) {
    return WarehousePackingWave(
      id: (data['wave_id'] ?? '').toString(),
      waveCode: (data['wave_code'] ?? '').toString().trim(),
      title: (data['title'] ?? 'Packing Wave').toString().trim(),
      plannedFor: DateTime.tryParse((data['planned_for'] ?? '').toString()),
      status: (data['wave_status'] ?? 'draft').toString().trim().toLowerCase(),
      notes: (data['notes'] ?? '').toString().trim(),
      startedAt: DateTime.tryParse((data['started_at'] ?? '').toString()),
      completedAt: DateTime.tryParse((data['completed_at'] ?? '').toString()),
      cancelledAt: DateTime.tryParse((data['cancelled_at'] ?? '').toString()),
      totalFulfillments: _packingWaveInt(data['total_fulfillments']),
      readyForDispatch: _packingWaveInt(data['ready_for_dispatch']),
      packingFulfillments: _packingWaveInt(data['packing_fulfillments']),
      preparingFulfillments: _packingWaveInt(data['preparing_fulfillments']),
      overallProgress: _packingWaveDouble(data['overall_progress']),
      createdAt: DateTime.tryParse((data['created_at'] ?? '').toString()),
      updatedAt: DateTime.tryParse((data['updated_at'] ?? '').toString()),
    );
  }

  bool get isDraft => status == 'draft';
  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get isActive => isDraft || isInProgress;

  String get statusLabel {
    switch (status) {
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Draft';
    }
  }
}

class WarehousePackingWaveMember {
  final String id;
  final String fulfillmentId;
  final String requestId;
  final int sequenceNo;
  final String businessName;
  final DateTime? requestedDate;
  final String requestedWindowLabel;
  final String dispatchMethod;
  final String fulfillmentStatus;
  final int totalItems;
  final int accountedItems;
  final double packingProgress;

  const WarehousePackingWaveMember({
    required this.id,
    required this.fulfillmentId,
    required this.requestId,
    required this.sequenceNo,
    required this.businessName,
    required this.requestedDate,
    required this.requestedWindowLabel,
    required this.dispatchMethod,
    required this.fulfillmentStatus,
    required this.totalItems,
    required this.accountedItems,
    required this.packingProgress,
  });

  factory WarehousePackingWaveMember.fromSupabase(Map<String, dynamic> data) {
    return WarehousePackingWaveMember(
      id: (data['wave_member_id'] ?? '').toString(),
      fulfillmentId: (data['fulfillment_id'] ?? '').toString(),
      requestId: (data['request_id'] ?? '').toString(),
      sequenceNo: _packingWaveInt(data['sequence_no']),
      businessName:
          (data['business_name'] ?? 'Wholesale business').toString().trim(),
      requestedDate:
          DateTime.tryParse((data['requested_date'] ?? '').toString()),
      requestedWindowLabel:
          (data['requested_window_label'] ?? '').toString().trim(),
      dispatchMethod:
          (data['dispatch_method'] ?? 'hpj_delivery').toString().trim(),
      fulfillmentStatus:
          (data['fulfillment_status'] ?? '').toString().trim().toLowerCase(),
      totalItems: _packingWaveInt(data['total_items']),
      accountedItems: _packingWaveInt(data['accounted_items']),
      packingProgress: _packingWaveDouble(data['packing_progress']),
    );
  }

  String get statusLabel => _packingWaveFulfillmentStatus(fulfillmentStatus);
  String get shortRequestId => _packingWaveShortId(requestId);
  bool get isReadyToPrepare => fulfillmentStatus == 'ready_to_prepare';
  bool get isPreparing => fulfillmentStatus == 'preparing';
  bool get isPacking => fulfillmentStatus == 'packing';
  bool get isReadyForDispatch => fulfillmentStatus == 'ready_for_dispatch';
}

int _packingWaveInt(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _packingWaveDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

String _packingWaveShortId(String id) {
  final clean = id.replaceAll('-', '').toUpperCase();
  return clean.length <= 8 ? clean : clean.substring(0, 8);
}

String _packingWaveFulfillmentStatus(String status) {
  switch (status) {
    case 'ready_to_prepare':
      return 'Ready to Prepare';
    case 'preparing':
      return 'Preparing';
    case 'packing':
      return 'Packing';
    case 'ready_for_dispatch':
      return 'Ready for Dispatch';
    case 'cancelled':
      return 'Cancelled';
    default:
      return status.replaceAll('_', ' ');
  }
}

String _packingWaveDateTime(DateTime? value) {
  if (value == null) return 'Not scheduled';
  final local = value.toLocal();
  const months = <String>[
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final hour = local.hour == 0
      ? 12
      : local.hour > 12
          ? local.hour - 12
          : local.hour;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour >= 12 ? 'PM' : 'AM';
  return '${local.day} ${months[local.month - 1]} ${local.year} • '
      '$hour:$minute $period';
}

String _packingWaveDate(DateTime? value) {
  if (value == null) return 'No requested date';
  final local = value.toLocal();
  const months = <String>[
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${local.day} ${months[local.month - 1]} ${local.year}';
}

Future<List<WarehousePackingWaveCandidate>>
    fetchWarehousePackingWaveCandidates() async {
  await requireAdminAccess();
  final response = await supabase.rpc(
    'admin_list_warehouse_packing_wave_candidates',
  );
  return (response as List)
      .map(
        (row) => WarehousePackingWaveCandidate.fromSupabase(
          Map<String, dynamic>.from(row as Map),
        ),
      )
      .toList();
}

Future<List<WarehousePackingWave>> fetchWarehousePackingWaves({
  bool includeClosed = true,
}) async {
  await requireAdminAccess();
  final response = await supabase.rpc(
    'admin_list_warehouse_packing_waves',
    params: {'p_include_closed': includeClosed},
  );
  return (response as List)
      .map(
        (row) => WarehousePackingWave.fromSupabase(
          Map<String, dynamic>.from(row as Map),
        ),
      )
      .toList();
}

Future<List<WarehousePackingWaveMember>> fetchWarehousePackingWaveMembers(
  String waveId,
) async {
  await requireAdminAccess();
  final response = await supabase.rpc(
    'admin_list_warehouse_packing_wave_members',
    params: {'p_wave_id': waveId},
  );
  return (response as List)
      .map(
        (row) => WarehousePackingWaveMember.fromSupabase(
          Map<String, dynamic>.from(row as Map),
        ),
      )
      .toList();
}

Future<void> createWarehousePackingWave({
  required String title,
  required DateTime plannedFor,
  required List<String> fulfillmentIds,
  String notes = '',
}) async {
  await requireAdminAccess();
  await supabase.rpc(
    'admin_create_warehouse_packing_wave',
    params: {
      'p_title': title.trim(),
      'p_planned_for': plannedFor.toUtc().toIso8601String(),
      'p_fulfillment_ids': fulfillmentIds,
      'p_notes': notes.trim(),
    },
  );
}

Future<void> startWarehousePackingWave(WarehousePackingWave wave) async {
  await requireAdminAccess();
  await supabase.rpc(
    'admin_start_warehouse_packing_wave',
    params: {'p_wave_id': wave.id},
  );
}

Future<void> completeWarehousePackingWave(WarehousePackingWave wave) async {
  await requireAdminAccess();
  await supabase.rpc(
    'admin_complete_warehouse_packing_wave',
    params: {'p_wave_id': wave.id},
  );
}

Future<void> cancelWarehousePackingWave(
  WarehousePackingWave wave, {
  String note = '',
}) async {
  await requireAdminAccess();
  await supabase.rpc(
    'admin_cancel_warehouse_packing_wave',
    params: {
      'p_wave_id': wave.id,
      'p_note': note.trim(),
    },
  );
}

class WarehousePackingWavesScreen extends StatefulWidget {
  const WarehousePackingWavesScreen({super.key});

  @override
  State<WarehousePackingWavesScreen> createState() =>
      _WarehousePackingWavesScreenState();
}

class _WarehousePackingWavesScreenState
    extends State<WarehousePackingWavesScreen> {
  late Future<List<Object>> _future;
  String _filter = 'active';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Object>> _load() {
    return Future.wait<Object>([
      fetchWarehousePackingWaves(),
      fetchWarehousePackingWaveCandidates(),
    ]);
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() => _future = next);
    await next;
  }

  Future<void> _createWave(
    List<WarehousePackingWaveCandidate> candidates,
  ) async {
    if (candidates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('There are no stock-ready fulfilments to wave.'),
        ),
      );
      return;
    }

    final title = TextEditingController(text: 'Packing Wave');
    final notes = TextEditingController();
    DateTime plannedFor = DateTime.now().add(const Duration(minutes: 30));
    final selected = <String>{};

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> chooseWhen() async {
              final date = await showDatePicker(
                context: sheetContext,
                initialDate: plannedFor,
                firstDate: DateTime.now().subtract(const Duration(days: 1)),
                lastDate: DateTime.now().add(const Duration(days: 90)),
              );
              if (date == null || !sheetContext.mounted) return;
              final time = await showTimePicker(
                context: sheetContext,
                initialTime: TimeOfDay.fromDateTime(plannedFor),
              );
              if (time == null) return;
              setSheetState(() {
                plannedFor = DateTime(
                  date.year,
                  date.month,
                  date.day,
                  time.hour,
                  time.minute,
                );
              });
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                18,
                18,
                18,
                MediaQuery.of(sheetContext).viewInsets.bottom + 18,
              ),
              child: SizedBox(
                height: MediaQuery.of(sheetContext).size.height * 0.78,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Create Packing Wave',
                      style: TextStyle(
                        color: FarmColors.ink,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: title,
                      decoration: const InputDecoration(labelText: 'Wave title'),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Planned start'),
                      subtitle: Text(_packingWaveDateTime(plannedFor)),
                      trailing: const Icon(Icons.schedule_outlined),
                      onTap: chooseWhen,
                    ),
                    TextField(
                      controller: notes,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Wave notes (optional)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Select fulfilments',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setSheetState(() {
                              if (selected.length == candidates.length) {
                                selected.clear();
                              } else {
                                selected
                                  ..clear()
                                  ..addAll(
                                    candidates.map((item) => item.fulfillmentId),
                                  );
                              }
                            });
                          },
                          child: Text(
                            selected.length == candidates.length
                                ? 'Clear All'
                                : 'Select All',
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: candidates.length,
                        itemBuilder: (context, index) {
                          final item = candidates[index];
                          final checked = selected.contains(item.fulfillmentId);
                          return CheckboxListTile(
                            value: checked,
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            title: Text(
                              item.businessName,
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            subtitle: Text(
                              '#${item.shortRequestId} • ${item.statusLabel} • '
                              '${item.accountedItems}/${item.totalItems} items • '
                              '${_packingWaveDate(item.requestedDate)}',
                            ),
                            onChanged: (value) {
                              setSheetState(() {
                                if (value == true) {
                                  selected.add(item.fulfillmentId);
                                } else {
                                  selected.remove(item.fulfillmentId);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: selected.isEmpty
                            ? null
                            : () => Navigator.of(sheetContext).pop(true),
                        icon: const Icon(Icons.view_week_outlined),
                        label: Text('Create Wave (${selected.length})'),
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

    if (confirmed != true) {
      title.dispose();
      notes.dispose();
      return;
    }

    try {
      await createWarehousePackingWave(
        title: title.text,
        plannedFor: plannedFor,
        fulfillmentIds: selected.toList(),
        notes: notes.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Packing wave created.')),
      );
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyAppError(error))),
      );
    } finally {
      title.dispose();
      notes.dispose();
    }
  }

  Future<void> _waveAction(
    WarehousePackingWave wave,
    String action,
  ) async {
    try {
      if (action == 'start') {
        await startWarehousePackingWave(wave);
      } else if (action == 'complete') {
        await completeWarehousePackingWave(wave);
      } else if (action == 'cancel') {
        final note = TextEditingController();
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Cancel packing wave?'),
            content: TextField(
              controller: note,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Reason (optional)'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Back'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Cancel Wave'),
              ),
            ],
          ),
        );
        if (confirmed != true) {
          note.dispose();
          return;
        }
        await cancelWarehousePackingWave(wave, note: note.text);
        note.dispose();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            action == 'start'
                ? 'Packing wave started.'
                : action == 'complete'
                    ? 'Packing wave completed.'
                    : 'Packing wave cancelled.',
          ),
        ),
      );
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyAppError(error))),
      );
    }
  }

  Color _waveColor(WarehousePackingWave wave) {
    if (wave.isCompleted) return FarmColors.success;
    if (wave.isCancelled) return FarmColors.mutedText;
    if (wave.isInProgress) return FarmColors.primary;
    return FarmColors.warning;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: const _WarehouseAppBar(title: 'Packing Waves'),
      body: FutureBuilder<List<Object>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError && snapshot.data == null) {
            return Center(child: Text(friendlyAppError(snapshot.error!)));
          }

          final data = snapshot.data ?? const <Object>[];
          final waves = data.isNotEmpty
              ? data[0] as List<WarehousePackingWave>
              : const <WarehousePackingWave>[];
          final candidates = data.length > 1
              ? data[1] as List<WarehousePackingWaveCandidate>
              : const <WarehousePackingWaveCandidate>[];

          final active = waves.where((wave) => wave.isActive).length;
          final inProgress = waves.where((wave) => wave.isInProgress).length;
          final completed = waves.where((wave) => wave.isCompleted).length;

          final filtered = waves.where((wave) {
            switch (_filter) {
              case 'active':
                return wave.isActive;
              case 'completed':
                return wave.isCompleted;
              case 'cancelled':
                return wave.isCancelled;
              default:
                return true;
            }
          }).toList();

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 110),
              children: [
                FarmCard(
                  padding: const EdgeInsets.all(16),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.view_week_outlined,
                        color: FarmColors.primary,
                        size: 30,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Packing Waves',
                              style: TextStyle(
                                color: FarmColors.ink,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Group stock-ready wholesale fulfilments into coordinated warehouse work. Packing quantities still live in the existing Wholesale Fulfilment workflow.',
                              style: TextStyle(
                                color: FarmColors.mutedText,
                                fontSize: 10.5,
                                height: 1.35,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _PackingWaveMetric(label: 'Active', value: '$active'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _PackingWaveMetric(
                        label: 'Running',
                        value: '$inProgress',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _PackingWaveMetric(
                        label: 'Candidates',
                        value: '${candidates.length}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: candidates.isEmpty
                        ? null
                        : () => _createWave(candidates),
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Create Packing Wave'),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final entry in const <MapEntry<String, String>>[
                        MapEntry('active', 'Active'),
                        MapEntry('completed', 'Completed'),
                        MapEntry('cancelled', 'Cancelled'),
                        MapEntry('all', 'All'),
                      ]) ...[
                        ChoiceChip(
                          label: Text(entry.value),
                          selected: _filter == entry.key,
                          onSelected: (_) => setState(() => _filter = entry.key),
                        ),
                        const SizedBox(width: 7),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (filtered.isEmpty)
                  FarmEmptyState(
                    icon: Icons.view_week_outlined,
                    title: _filter == 'active'
                        ? 'No active packing waves'
                        : 'No packing waves in this view',
                    message: candidates.isEmpty
                        ? 'Use Stock Ready on wholesale fulfilments first. Eligible orders will then appear as packing-wave candidates.'
                        : 'Create a wave to coordinate the eligible wholesale fulfilments.',
                  )
                else
                  ...filtered.map((wave) {
                    final color = _waveColor(wave);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: FarmCard(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${wave.waveCode} • ${wave.title}',
                                        style: const TextStyle(
                                          color: FarmColors.ink,
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        _packingWaveDateTime(wave.plannedFor),
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
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.10),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    wave.statusLabel.toUpperCase(),
                                    style: TextStyle(
                                      color: color,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            LinearProgressIndicator(
                              value: wave.overallProgress.clamp(0.0, 1.0).toDouble(),
                              minHeight: 7,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              '${wave.totalFulfillments} fulfilment(s) • '
                              '${wave.readyForDispatch} ready • '
                              '${wave.packingFulfillments} packing • '
                              '${wave.preparingFulfillments} preparing',
                              style: const TextStyle(
                                color: FarmColors.mutedText,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (wave.notes.isNotEmpty) ...[
                              const SizedBox(height: 7),
                              Text(
                                wave.notes,
                                style: const TextStyle(
                                  color: FarmColors.mutedText,
                                  fontSize: 10.5,
                                ),
                              ),
                            ],
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 7,
                              runSpacing: 7,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    await Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) =>
                                            WarehousePackingWaveDetailScreen(
                                          wave: wave,
                                        ),
                                      ),
                                    );
                                    if (mounted) await _refresh();
                                  },
                                  icon: const Icon(Icons.list_alt_outlined),
                                  label: const Text('Open Wave'),
                                ),
                                if (wave.isDraft)
                                  ElevatedButton.icon(
                                    onPressed: () => _waveAction(wave, 'start'),
                                    icon: const Icon(Icons.play_arrow_outlined),
                                    label: const Text('Start'),
                                  ),
                                if (wave.isInProgress)
                                  ElevatedButton.icon(
                                    onPressed: () => _waveAction(wave, 'complete'),
                                    icon: const Icon(Icons.check_circle_outline),
                                    label: const Text('Complete'),
                                  ),
                                if (wave.isActive)
                                  TextButton(
                                    onPressed: () => _waveAction(wave, 'cancel'),
                                    child: const Text('Cancel'),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                if (completed > 0 && _filter == 'active') ...[
                  const SizedBox(height: 4),
                  Text(
                    '$completed completed wave(s) are available under Completed.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: FarmColors.mutedText,
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class WarehousePackingWaveDetailScreen extends StatefulWidget {
  final WarehousePackingWave wave;

  const WarehousePackingWaveDetailScreen({
    super.key,
    required this.wave,
  });

  @override
  State<WarehousePackingWaveDetailScreen> createState() =>
      _WarehousePackingWaveDetailScreenState();
}

class _WarehousePackingWaveDetailScreenState
    extends State<WarehousePackingWaveDetailScreen> {
  late Future<List<WarehousePackingWaveMember>> _future;

  @override
  void initState() {
    super.initState();
    _future = fetchWarehousePackingWaveMembers(widget.wave.id);
  }

  Future<void> _refresh() async {
    final next = fetchWarehousePackingWaveMembers(widget.wave.id);
    setState(() => _future = next);
    await next;
  }

  Future<void> _advance(WarehousePackingWaveMember member) async {
    try {
      final fulfillment = await fetchWholesaleFulfillmentForRequest(
        member.requestId,
      );
      if (fulfillment == null) {
        throw Exception('Wholesale fulfilment could not be loaded.');
      }

      if (fulfillment.isReadyToPrepare) {
        await startWholesalePreparation(fulfillment);
      } else if (fulfillment.isPreparing) {
        await startWholesalePacking(fulfillment);
      } else {
        throw Exception('This fulfilment cannot be advanced from this screen.');
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            fulfillment.isReadyToPrepare
                ? 'Preparation started.'
                : 'Packing started.',
          ),
        ),
      );
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyAppError(error))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: _WarehouseAppBar(title: widget.wave.waveCode),
      body: FutureBuilder<List<WarehousePackingWaveMember>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError && snapshot.data == null) {
            return Center(child: Text(friendlyAppError(snapshot.error!)));
          }

          final members = snapshot.data ?? const <WarehousePackingWaveMember>[];
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 100),
              children: [
                FarmCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.wave.title,
                        style: const TextStyle(
                          color: FarmColors.ink,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.wave.statusLabel} • ${_packingWaveDateTime(widget.wave.plannedFor)}',
                        style: const TextStyle(
                          color: FarmColors.mutedText,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Use this screen to coordinate order readiness. Actual line packing remains in Wholesale Fulfilment so stock is issued only once.',
                        style: TextStyle(
                          color: FarmColors.mutedText,
                          fontSize: 10.5,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (members.isEmpty)
                  const FarmEmptyState(
                    icon: Icons.view_week_outlined,
                    title: 'No fulfilments in this wave',
                    message: 'This packing wave has no member fulfilments.',
                  )
                else
                  ...members.map(
                    (member) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: FarmCard(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: FarmColors.primarySoft,
                                  child: Text(
                                    '${member.sequenceNo}',
                                    style: const TextStyle(
                                      color: FarmColors.primary,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        member.businessName,
                                        style: const TextStyle(
                                          color: FarmColors.ink,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      Text(
                                        '#${member.shortRequestId} • ${_packingWaveDate(member.requestedDate)}',
                                        style: const TextStyle(
                                          color: FarmColors.mutedText,
                                          fontSize: 10.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  member.statusLabel,
                                  style: const TextStyle(
                                    color: FarmColors.primary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            LinearProgressIndicator(
                              value: member.packingProgress.clamp(0.0, 1.0).toDouble(),
                              minHeight: 6,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${member.accountedItems}/${member.totalItems} lines accounted for'
                              '${member.requestedWindowLabel.isEmpty ? '' : ' • ${member.requestedWindowLabel}'}',
                              style: const TextStyle(
                                color: FarmColors.mutedText,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (member.isReadyToPrepare || member.isPreparing) ...[
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => _advance(member),
                                  icon: Icon(
                                    member.isReadyToPrepare
                                        ? Icons.play_arrow_outlined
                                        : Icons.inventory_2_outlined,
                                  ),
                                  label: Text(
                                    member.isReadyToPrepare
                                        ? 'Start Preparing'
                                        : 'Start Packing',
                                  ),
                                ),
                              ),
                            ] else if (member.isPacking) ...[
                              const SizedBox(height: 9),
                              const Text(
                                'Continue the item-level packing in Wholesale Fulfilment.',
                                style: TextStyle(
                                  color: FarmColors.mutedText,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PackingWaveMetric extends StatelessWidget {
  final String label;
  final String value;

  const _PackingWaveMetric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: FarmColors.cardSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: FarmColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: FarmColors.ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: FarmColors.mutedText,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
