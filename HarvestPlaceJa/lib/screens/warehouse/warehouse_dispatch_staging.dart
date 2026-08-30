part of harvest_place_app;

// ================================================================
// THE HARVEST PLACE JA
// PHASE 3AD — DISPATCH STAGING
// ================================================================

class WarehouseDispatchStagingArea {
  final String id;
  final String code;
  final String name;
  final bool isActive;
  final String notes;

  const WarehouseDispatchStagingArea({
    required this.id,
    required this.code,
    required this.name,
    required this.isActive,
    required this.notes,
  });

  factory WarehouseDispatchStagingArea.fromSupabase(
    Map<String, dynamic> data,
  ) {
    return WarehouseDispatchStagingArea(
      id: (data['id'] ?? '').toString(),
      code: (data['code'] ?? '').toString().trim(),
      name: (data['name'] ?? '').toString().trim(),
      isActive: data['is_active'] == true,
      notes: (data['notes'] ?? '').toString().trim(),
    );
  }
}

class WarehouseDispatchStagingRow {
  final String fulfillmentId;
  final String requestId;
  final String businessName;
  final DateTime? requestedDate;
  final String requestedWindowLabel;
  final String dispatchMethod;
  final String fulfillmentStatus;
  final String? stagingId;
  final String stagingStatus;
  final String? stagingAreaId;
  final String stagingAreaCode;
  final String stagingAreaName;
  final String stagingNote;
  final DateTime? stagedAt;
  final DateTime? releasedAt;
  final String? dispatchId;
  final String dispatchStatus;
  final DateTime? scheduledFor;

  const WarehouseDispatchStagingRow({
    required this.fulfillmentId,
    required this.requestId,
    required this.businessName,
    required this.requestedDate,
    required this.requestedWindowLabel,
    required this.dispatchMethod,
    required this.fulfillmentStatus,
    required this.stagingId,
    required this.stagingStatus,
    required this.stagingAreaId,
    required this.stagingAreaCode,
    required this.stagingAreaName,
    required this.stagingNote,
    required this.stagedAt,
    required this.releasedAt,
    required this.dispatchId,
    required this.dispatchStatus,
    required this.scheduledFor,
  });

  factory WarehouseDispatchStagingRow.fromSupabase(
    Map<String, dynamic> data,
  ) {
    String? nullable(dynamic value) {
      final clean = value?.toString().trim() ?? '';
      return clean.isEmpty ? null : clean;
    }

    return WarehouseDispatchStagingRow(
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
      stagingId: nullable(data['staging_id']),
      stagingStatus:
          (data['staging_status'] ?? '').toString().trim().toLowerCase(),
      stagingAreaId: nullable(data['staging_area_id']),
      stagingAreaCode: (data['staging_area_code'] ?? '').toString().trim(),
      stagingAreaName: (data['staging_area_name'] ?? '').toString().trim(),
      stagingNote: (data['staging_note'] ?? '').toString().trim(),
      stagedAt: DateTime.tryParse((data['staged_at'] ?? '').toString()),
      releasedAt: DateTime.tryParse((data['released_at'] ?? '').toString()),
      dispatchId: nullable(data['dispatch_id']),
      dispatchStatus:
          (data['dispatch_status'] ?? '').toString().trim().toLowerCase(),
      scheduledFor:
          DateTime.tryParse((data['scheduled_for'] ?? '').toString()),
    );
  }

  bool get needsStaging => stagingId == null || stagingStatus == 'cancelled';
  bool get isStaged => stagingStatus == 'staged';
  bool get isReleased => stagingStatus == 'released';
  bool get hasDispatch => dispatchId != null;
  String get shortRequestId => _dispatchStagingShortId(requestId);

  String get dispatchMethodLabel =>
      dispatchMethod == 'business_collection' ? 'Business Collection' : 'HPJ Delivery';

  String get dispatchStatusLabel {
    if (dispatchStatus.isEmpty) return 'No Dispatch Yet';
    return dispatchStatus
        .split('_')
        .map(
          (word) => word.isEmpty
              ? ''
              : '${word.substring(0, 1).toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }
}

String _dispatchStagingShortId(String id) {
  final clean = id.replaceAll('-', '').toUpperCase();
  return clean.length <= 8 ? clean : clean.substring(0, 8);
}

String _dispatchStagingDate(DateTime? value) {
  if (value == null) return 'No date';
  final local = value.toLocal();
  const months = <String>[
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${local.day} ${months[local.month - 1]} ${local.year}';
}

String _dispatchStagingDateTime(DateTime? value) {
  if (value == null) return 'Not scheduled';
  final local = value.toLocal();
  final hour = local.hour == 0
      ? 12
      : local.hour > 12
          ? local.hour - 12
          : local.hour;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour >= 12 ? 'PM' : 'AM';
  return '${_dispatchStagingDate(local)} • $hour:$minute $period';
}

const String _dispatchStagingAreaSelect =
    'id, code, name, is_active, notes, created_at, updated_at';

Future<List<WarehouseDispatchStagingArea>>
    fetchWarehouseDispatchStagingAreas() async {
  await requireAdminAccess();
  final response = await supabase
      .from('warehouse_dispatch_staging_areas')
      .select(_dispatchStagingAreaSelect)
      .order('code');
  return (response as List)
      .map(
        (row) => WarehouseDispatchStagingArea.fromSupabase(
          Map<String, dynamic>.from(row as Map),
        ),
      )
      .toList();
}

Future<List<WarehouseDispatchStagingRow>>
    fetchWarehouseDispatchStagingRows() async {
  await requireAdminAccess();
  final response = await supabase.rpc(
    'admin_list_warehouse_dispatch_staging',
  );
  return (response as List)
      .map(
        (row) => WarehouseDispatchStagingRow.fromSupabase(
          Map<String, dynamic>.from(row as Map),
        ),
      )
      .toList();
}

Future<void> createWarehouseDispatchStagingArea({
  required String code,
  required String name,
  String notes = '',
}) async {
  await requireAdminAccess();
  await supabase.rpc(
    'admin_create_warehouse_dispatch_staging_area',
    params: {
      'p_code': code.trim(),
      'p_name': name.trim(),
      'p_notes': notes.trim(),
    },
  );
}

Future<void> updateWarehouseDispatchStagingArea({
  required WarehouseDispatchStagingArea area,
  required String name,
  required bool isActive,
  String notes = '',
}) async {
  await requireAdminAccess();
  await supabase.rpc(
    'admin_update_warehouse_dispatch_staging_area',
    params: {
      'p_area_id': area.id,
      'p_name': name.trim(),
      'p_is_active': isActive,
      'p_notes': notes.trim(),
    },
  );
}

Future<void> stageWholesaleFulfillment({
  required WarehouseDispatchStagingRow row,
  required WarehouseDispatchStagingArea area,
  String note = '',
}) async {
  await requireAdminAccess();
  await supabase.rpc(
    'admin_stage_wholesale_fulfillment',
    params: {
      'p_fulfillment_id': row.fulfillmentId,
      'p_staging_area_id': area.id,
      'p_note': note.trim(),
    },
  );
}

Future<void> releaseWholesaleFulfillmentFromStaging({
  required WarehouseDispatchStagingRow row,
  String note = '',
}) async {
  await requireAdminAccess();
  await supabase.rpc(
    'admin_release_wholesale_fulfillment_from_staging',
    params: {
      'p_fulfillment_id': row.fulfillmentId,
      'p_note': note.trim(),
    },
  );
}

class WarehouseDispatchStagingScreen extends StatefulWidget {
  const WarehouseDispatchStagingScreen({super.key});

  @override
  State<WarehouseDispatchStagingScreen> createState() =>
      _WarehouseDispatchStagingScreenState();
}

class _WarehouseDispatchStagingScreenState
    extends State<WarehouseDispatchStagingScreen> {
  late Future<List<Object>> _future;
  String _filter = 'needs_staging';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Object>> _load() {
    return Future.wait<Object>([
      fetchWarehouseDispatchStagingRows(),
      fetchWarehouseDispatchStagingAreas(),
    ]);
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() => _future = next);
    await next;
  }

  Future<void> _stage(
    WarehouseDispatchStagingRow row,
    List<WarehouseDispatchStagingArea> areas,
  ) async {
    final activeAreas = areas.where((area) => area.isActive).toList();
    if (activeAreas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Create an active dispatch staging area first.'),
        ),
      );
      return;
    }

    String? selectedId = row.stagingAreaId;
    if (selectedId == null ||
        !activeAreas.any((area) => area.id == selectedId)) {
      selectedId = activeAreas.first.id;
    }
    final note = TextEditingController(text: row.stagingNote);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(row.isStaged ? 'Move staged order' : 'Stage packed order'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedId,
                decoration: const InputDecoration(labelText: 'Staging area'),
                items: activeAreas
                    .map(
                      (area) => DropdownMenuItem<String>(
                        value: area.id,
                        child: Text('${area.code} • ${area.name}'),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setDialogState(() => selectedId = value),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: note,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Staging note'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedId == null
                  ? null
                  : () => Navigator.of(dialogContext).pop(true),
              child: Text(row.isStaged ? 'Move' : 'Stage Order'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || selectedId == null) {
      note.dispose();
      return;
    }

    final area = activeAreas.firstWhere((item) => item.id == selectedId);
    try {
      await stageWholesaleFulfillment(
        row: row,
        area: area,
        note: note.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order staged at ${area.code}.')),
      );
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyAppError(error))),
      );
    } finally {
      note.dispose();
    }
  }

  Future<void> _release(WarehouseDispatchStagingRow row) async {
    final note = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Release from staging?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Use this when the packed order is physically leaving its staging area for dispatch or collection.',
            ),
            const SizedBox(height: 10),
            TextField(
              controller: note,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Release note'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Back'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Release'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      note.dispose();
      return;
    }

    try {
      await releaseWholesaleFulfillmentFromStaging(
        row: row,
        note: note.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order released from staging.')),
      );
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyAppError(error))),
      );
    } finally {
      note.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: const _WarehouseAppBar(title: 'Dispatch Staging'),
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
          final rows = data.isNotEmpty
              ? data[0] as List<WarehouseDispatchStagingRow>
              : const <WarehouseDispatchStagingRow>[];
          final areas = data.length > 1
              ? data[1] as List<WarehouseDispatchStagingArea>
              : const <WarehouseDispatchStagingArea>[];

          final needs = rows.where((row) => row.needsStaging).length;
          final staged = rows.where((row) => row.isStaged).length;
          final released = rows.where((row) => row.isReleased).length;

          final filtered = rows.where((row) {
            switch (_filter) {
              case 'needs_staging':
                return row.needsStaging;
              case 'staged':
                return row.isStaged;
              case 'released':
                return row.isReleased;
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
                        Icons.move_to_inbox_outlined,
                        color: FarmColors.primary,
                        size: 30,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dispatch Staging',
                              style: TextStyle(
                                color: FarmColors.ink,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Give every packed wholesale order a physical handover location before it leaves the warehouse. Dispatch status continues to be managed by the existing Wholesale Dispatch workflow.',
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
                      child: _DispatchStagingMetric(label: 'Need Stage', value: '$needs'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _DispatchStagingMetric(label: 'Staged', value: '$staged'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _DispatchStagingMetric(label: 'Released', value: '$released'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const WarehouseDispatchStagingAreasScreen(),
                        ),
                      );
                      if (mounted) await _refresh();
                    },
                    icon: const Icon(Icons.location_on_outlined),
                    label: Text(
                      areas.isEmpty
                          ? 'Create Dispatch Staging Areas'
                          : 'Manage Staging Areas (${areas.length})',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final entry in const <MapEntry<String, String>>[
                        MapEntry('needs_staging', 'Need Staging'),
                        MapEntry('staged', 'Staged'),
                        MapEntry('released', 'Released'),
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
                    icon: Icons.move_to_inbox_outlined,
                    title: _filter == 'needs_staging'
                        ? 'No packed orders waiting for staging'
                        : 'No orders in this staging view',
                    message:
                        'Orders appear here after Wholesale Fulfilment reaches Ready for Dispatch.',
                  )
                else
                  ...filtered.map(
                    (row) => Padding(
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
                                        row.businessName,
                                        style: const TextStyle(
                                          color: FarmColors.ink,
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '#${row.shortRequestId} • ${row.dispatchMethodLabel} • ${_dispatchStagingDate(row.requestedDate)}',
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
                                    color: (row.isStaged
                                            ? FarmColors.success
                                            : row.isReleased
                                                ? FarmColors.primary
                                                : FarmColors.warning)
                                        .withOpacity(0.10),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    row.isStaged
                                        ? 'STAGED'
                                        : row.isReleased
                                            ? 'RELEASED'
                                            : 'NEEDS STAGING',
                                    style: TextStyle(
                                      color: row.isStaged
                                          ? FarmColors.success
                                          : row.isReleased
                                              ? FarmColors.primary
                                              : FarmColors.warning,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 7,
                              runSpacing: 7,
                              children: [
                                _DispatchStagingValue(
                                  label: 'Area',
                                  value: row.stagingAreaCode.isEmpty
                                      ? 'Not assigned'
                                      : '${row.stagingAreaCode} • ${row.stagingAreaName}',
                                ),
                                _DispatchStagingValue(
                                  label: 'Dispatch',
                                  value: row.dispatchStatusLabel,
                                ),
                                _DispatchStagingValue(
                                  label: 'Scheduled',
                                  value: _dispatchStagingDateTime(row.scheduledFor),
                                ),
                              ],
                            ),
                            if (row.stagingNote.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                row.stagingNote,
                                style: const TextStyle(
                                  color: FarmColors.mutedText,
                                  fontSize: 10.5,
                                ),
                              ),
                            ],
                            const SizedBox(height: 10),
                            if (row.needsStaging)
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => _stage(row, areas),
                                  icon: const Icon(Icons.move_to_inbox_outlined),
                                  label: const Text('Stage Order'),
                                ),
                              )
                            else if (row.isStaged)
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _stage(row, areas),
                                      icon: const Icon(Icons.swap_horiz_outlined),
                                      label: const Text('Move'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => _release(row),
                                      icon: const Icon(Icons.exit_to_app_outlined),
                                      label: const Text('Release'),
                                    ),
                                  ),
                                ],
                              )
                            else
                              Text(
                                'Released ${_dispatchStagingDateTime(row.releasedAt)}.',
                                style: const TextStyle(
                                  color: FarmColors.mutedText,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
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

class WarehouseDispatchStagingAreasScreen extends StatefulWidget {
  const WarehouseDispatchStagingAreasScreen({super.key});

  @override
  State<WarehouseDispatchStagingAreasScreen> createState() =>
      _WarehouseDispatchStagingAreasScreenState();
}

class _WarehouseDispatchStagingAreasScreenState
    extends State<WarehouseDispatchStagingAreasScreen> {
  late Future<List<WarehouseDispatchStagingArea>> _future;

  @override
  void initState() {
    super.initState();
    _future = fetchWarehouseDispatchStagingAreas();
  }

  Future<void> _refresh() async {
    final next = fetchWarehouseDispatchStagingAreas();
    setState(() => _future = next);
    await next;
  }

  Future<void> _create() async {
    final code = TextEditingController();
    final name = TextEditingController();
    final notes = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create staging area'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: code,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Code',
                hintText: 'STAGE-A1',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: notes,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Notes'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      code.dispose();
      name.dispose();
      notes.dispose();
      return;
    }

    try {
      await createWarehouseDispatchStagingArea(
        code: code.text,
        name: name.text,
        notes: notes.text,
      );
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyAppError(error))),
      );
    } finally {
      code.dispose();
      name.dispose();
      notes.dispose();
    }
  }

  Future<void> _edit(WarehouseDispatchStagingArea area) async {
    final name = TextEditingController(text: area.name);
    final notes = TextEditingController(text: area.notes);
    bool active = area.isActive;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Edit ${area.code}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: notes,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Notes'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active'),
                value: active,
                onChanged: (value) => setDialogState(() => active = value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) {
      name.dispose();
      notes.dispose();
      return;
    }

    try {
      await updateWarehouseDispatchStagingArea(
        area: area,
        name: name.text,
        isActive: active,
        notes: notes.text,
      );
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyAppError(error))),
      );
    } finally {
      name.dispose();
      notes.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: const _WarehouseAppBar(title: 'Staging Areas'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.add),
        label: const Text('Add Area'),
      ),
      body: FutureBuilder<List<WarehouseDispatchStagingArea>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError && snapshot.data == null) {
            return Center(child: Text(friendlyAppError(snapshot.error!)));
          }
          final areas = snapshot.data ?? const <WarehouseDispatchStagingArea>[];
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 100),
              children: [
                if (areas.isEmpty)
                  const FarmEmptyState(
                    icon: Icons.location_on_outlined,
                    title: 'No staging areas yet',
                    message:
                        'Create physical locations such as STAGE-A1, PICKUP-01 or ROUTE-BLACK-RIVER.',
                  )
                else
                  ...areas.map(
                    (area) => Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: FarmCard(
                        padding: const EdgeInsets.all(13),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: area.isActive
                                ? FarmColors.primarySoft
                                : FarmColors.cardSoft,
                            child: const Icon(
                              Icons.location_on_outlined,
                              color: FarmColors.primary,
                            ),
                          ),
                          title: Text(
                            '${area.code} • ${area.name}',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          subtitle: Text(
                            '${area.isActive ? 'Active' : 'Inactive'}${area.notes.isEmpty ? '' : ' • ${area.notes}'}',
                          ),
                          trailing: const Icon(Icons.edit_outlined),
                          onTap: () => _edit(area),
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

class _DispatchStagingMetric extends StatelessWidget {
  final String label;
  final String value;

  const _DispatchStagingMetric({
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

class _DispatchStagingValue extends StatelessWidget {
  final String label;
  final String value;

  const _DispatchStagingValue({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: FarmColors.cardSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: FarmColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: FarmColors.mutedText,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: FarmColors.ink,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
