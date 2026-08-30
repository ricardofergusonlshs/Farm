part of harvest_place_app;

// ================================================================
// THE HARVEST PLACE JA
// PHASE 3AB — WAREHOUSE CYCLE COUNTS & RECONCILIATION
// ================================================================

class WarehouseCycleCountLine {
  final String id;
  final String cycleCountId;
  final String lotId;
  final String lotCode;
  final String productName;
  final String unit;
  final String? expectedStorageLocationId;
  final String storageLocationCode;
  final double expectedOnHand;
  final double expectedReserved;
  final double? countedOnHand;
  final double? variance;
  final double appliedDelta;
  final String countNote;
  final DateTime? countedAt;

  const WarehouseCycleCountLine({
    required this.id,
    required this.cycleCountId,
    required this.lotId,
    required this.lotCode,
    required this.productName,
    required this.unit,
    required this.expectedStorageLocationId,
    required this.storageLocationCode,
    required this.expectedOnHand,
    required this.expectedReserved,
    required this.countedOnHand,
    required this.variance,
    required this.appliedDelta,
    required this.countNote,
    this.countedAt,
  });

  factory WarehouseCycleCountLine.fromSupabase(Map<String, dynamic> data) {
    double amount(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0.0;
    }

    double? nullableAmount(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    String? nullable(dynamic value) {
      final clean = value?.toString().trim() ?? '';
      return clean.isEmpty ? null : clean;
    }

    return WarehouseCycleCountLine(
      id: (data['id'] ?? '').toString(),
      cycleCountId: (data['cycle_count_id'] ?? '').toString(),
      lotId: (data['lot_id'] ?? '').toString(),
      lotCode: (data['lot_code'] ?? '').toString().trim(),
      productName: (data['product_name'] ?? 'Produce').toString().trim(),
      unit: (data['unit'] ?? 'unit').toString().trim(),
      expectedStorageLocationId: nullable(data['expected_storage_location_id']),
      storageLocationCode:
          (data['storage_location_code'] ?? '').toString().trim(),
      expectedOnHand: amount(data['expected_on_hand']),
      expectedReserved: amount(data['expected_reserved']),
      countedOnHand: nullableAmount(data['counted_on_hand']),
      variance: nullableAmount(data['variance']),
      appliedDelta: amount(data['applied_delta']),
      countNote: (data['count_note'] ?? '').toString().trim(),
      countedAt: DateTime.tryParse((data['counted_at'] ?? '').toString()),
    );
  }

  bool get isCounted => countedOnHand != null;
  bool get hasVariance => isCounted && (variance ?? 0).abs() > 0.001;
  bool get isUnassigned => expectedStorageLocationId == null;

  String quantity(double value) {
    final text = value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
    return '$text $unit';
  }

  String get locationLabel =>
      storageLocationCode.isEmpty ? 'UNASSIGNED' : storageLocationCode;
}

class WarehouseCycleCount {
  final String id;
  final String title;
  final String? storageLocationId;
  final String storageLocationCode;
  final String status;
  final String notes;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final List<WarehouseCycleCountLine> lines;

  const WarehouseCycleCount({
    required this.id,
    required this.title,
    required this.storageLocationId,
    required this.storageLocationCode,
    required this.status,
    required this.notes,
    this.startedAt,
    this.completedAt,
    this.cancelledAt,
    required this.lines,
  });

  factory WarehouseCycleCount.fromSupabase(Map<String, dynamic> data) {
    String? nullable(dynamic value) {
      final clean = value?.toString().trim() ?? '';
      return clean.isEmpty ? null : clean;
    }

    final rawLines = data['warehouse_cycle_count_lines'];
    final lines = rawLines is List
        ? rawLines
            .map(
              (row) => WarehouseCycleCountLine.fromSupabase(
                Map<String, dynamic>.from(row),
              ),
            )
            .toList()
        : <WarehouseCycleCountLine>[];

    lines.sort((a, b) {
      final location = a.locationLabel.compareTo(b.locationLabel);
      if (location != 0) return location;
      final product =
          a.productName.toLowerCase().compareTo(b.productName.toLowerCase());
      if (product != 0) return product;
      return a.lotCode.compareTo(b.lotCode);
    });

    return WarehouseCycleCount(
      id: (data['id'] ?? '').toString(),
      title: (data['title'] ?? 'Warehouse Cycle Count').toString().trim(),
      storageLocationId: nullable(data['storage_location_id']),
      storageLocationCode:
          (data['storage_location_code'] ?? '').toString().trim(),
      status: (data['status'] ?? 'in_progress').toString().trim().toLowerCase(),
      notes: (data['notes'] ?? '').toString().trim(),
      startedAt: DateTime.tryParse((data['started_at'] ?? '').toString()),
      completedAt: DateTime.tryParse((data['completed_at'] ?? '').toString()),
      cancelledAt: DateTime.tryParse((data['cancelled_at'] ?? '').toString()),
      lines: lines,
    );
  }

  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  int get countedLines => lines.where((line) => line.isCounted).length;
  int get varianceLines => lines.where((line) => line.hasVariance).length;
  bool get allCounted => lines.isNotEmpty && countedLines == lines.length;

  String get statusLabel {
    switch (status) {
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'In Progress';
    }
  }

  String get scopeLabel => storageLocationCode.isEmpty
      ? 'All warehouse locations'
      : storageLocationCode;
}

const String _warehouseCycleCountSelectFields =
    'id, title, storage_location_id, storage_location_code, status, notes, '
    'started_at, completed_at, cancelled_at, created_at, updated_at, '
    'warehouse_cycle_count_lines('
    'id, cycle_count_id, lot_id, lot_code, product_name, unit, '
    'expected_storage_location_id, storage_location_code, expected_on_hand, '
    'expected_reserved, counted_on_hand, variance, applied_delta, count_note, '
    'counted_at, created_at, updated_at'
    ')';

Future<List<WarehouseCycleCount>> fetchWarehouseCycleCounts() async {
  await requireAdminAccess();
  final response = await supabase
      .from('warehouse_cycle_counts')
      .select(_warehouseCycleCountSelectFields)
      .order('started_at', ascending: false)
      .limit(100);

  return (response as List)
      .map(
        (row) => WarehouseCycleCount.fromSupabase(
          Map<String, dynamic>.from(row),
        ),
      )
      .toList();
}

Future<WarehouseCycleCount?> fetchWarehouseCycleCount(String countId) async {
  await requireAdminAccess();
  final response = await supabase
      .from('warehouse_cycle_counts')
      .select(_warehouseCycleCountSelectFields)
      .eq('id', countId)
      .maybeSingle();
  if (response == null) return null;
  return WarehouseCycleCount.fromSupabase(
    Map<String, dynamic>.from(response),
  );
}

Future<String> createWarehouseCycleCount({
  String title = '',
  String? locationId,
  String notes = '',
}) async {
  await requireAdminAccess();
  final response = await supabase.rpc(
    'admin_create_warehouse_cycle_count',
    params: {
      'p_title': title.trim(),
      'p_location_id': locationId,
      'p_notes': notes.trim(),
    },
  );
  final id = response?.toString().trim() ?? '';
  if (id.isEmpty) {
    throw StateError('Cycle count was created but no id was returned.');
  }
  return id;
}

Future<void> recordWarehouseCycleCountLine({
  required WarehouseCycleCountLine line,
  required double countedOnHand,
  String note = '',
}) async {
  await requireAdminAccess();
  await supabase.rpc(
    'admin_record_warehouse_cycle_count_line',
    params: {
      'p_line_id': line.id,
      'p_counted_on_hand': countedOnHand,
      'p_note': note.trim(),
    },
  );
}

Future<void> completeWarehouseCycleCount(WarehouseCycleCount count) async {
  await requireAdminAccess();
  await supabase.rpc(
    'admin_complete_warehouse_cycle_count',
    params: {'p_count_id': count.id},
  );
}

Future<void> cancelWarehouseCycleCount(WarehouseCycleCount count) async {
  await requireAdminAccess();
  await supabase.rpc(
    'admin_cancel_warehouse_cycle_count',
    params: {'p_count_id': count.id},
  );
}

class WarehouseCycleCountsScreen extends StatefulWidget {
  const WarehouseCycleCountsScreen({super.key});

  @override
  State<WarehouseCycleCountsScreen> createState() =>
      _WarehouseCycleCountsScreenState();
}

class _WarehouseCycleCountsScreenState
    extends State<WarehouseCycleCountsScreen> {
  late Future<List<WarehouseCycleCount>> _future;

  @override
  void initState() {
    super.initState();
    _future = fetchWarehouseCycleCounts();
  }

  Future<void> _refresh() async {
    final next = fetchWarehouseCycleCounts();
    setState(() => _future = next);
    await next;
  }

  Future<void> _createCount() async {
    final title = TextEditingController();
    final notes = TextEditingController();

    try {
      final locations = (await fetchWarehouseStorageLocations())
          .where((location) => location.isActive)
          .toList();
      if (!mounted) return;

      String selectedLocationId = '__all__';
      final confirmed = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) {
          return StatefulBuilder(
            builder: (context, setSheetState) => SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  18,
                  18,
                  18,
                  MediaQuery.of(sheetContext).viewInsets.bottom + 18,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Start Cycle Count',
                        style: TextStyle(
                          color: FarmColors.ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'The app snapshots on-hand and reserved quantities. Reconciliation is blocked if a lot changes while the count is open, protecting live reservations and packing.',
                        style: TextStyle(
                          color: FarmColors.mutedText,
                          fontSize: 10.5,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: selectedLocationId,
                        decoration: const InputDecoration(
                          labelText: 'Count scope',
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: '__all__',
                            child: Text('All warehouse locations'),
                          ),
                          ...locations.map(
                            (location) => DropdownMenuItem<String>(
                              value: location.id,
                              child: Text(location.label),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setSheetState(() => selectedLocationId = value);
                        },
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: title,
                        decoration: const InputDecoration(
                          labelText: 'Count title (optional)',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: notes,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Notes (optional)',
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.of(sheetContext).pop(true),
                          icon: const Icon(Icons.fact_check_outlined),
                          label: const Text('Start Count'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );

      if (confirmed != true) return;

      final countId = await createWarehouseCycleCount(
        title: title.text,
        locationId: selectedLocationId == '__all__' ? null : selectedLocationId,
        notes: notes.text,
      );
      await _refresh();
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => WarehouseCycleCountDetailScreen(countId: countId),
        ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: const _WarehouseAppBar(title: 'Warehouse Cycle Counts'),
      body: FutureBuilder<List<WarehouseCycleCount>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError && snapshot.data == null) {
            return Center(child: Text(friendlyAppError(snapshot.error!)));
          }

          final counts = snapshot.data ?? const <WarehouseCycleCount>[];
          final active = counts.where((count) => count.isInProgress).length;
          final completed = counts.where((count) => count.isCompleted).length;
          final cancelled = counts.where((count) => count.isCancelled).length;

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
              children: [
                FarmCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.fact_check_outlined,
                            color: FarmColors.primary,
                            size: 30,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Cycle Count & Reconciliation',
                                  style: TextStyle(
                                    color: FarmColors.ink,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Count physical stock by location or across the warehouse. Variances are applied to the existing lot ledger only when the snapshot is still safe to reconcile.',
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
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _createCount,
                          icon: const Icon(Icons.add_task_outlined),
                          label: const Text('Start Cycle Count'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _CycleCountMetric(label: 'Open', value: '$active'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _CycleCountMetric(
                        label: 'Completed',
                        value: '$completed',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _CycleCountMetric(
                        label: 'Cancelled',
                        value: '$cancelled',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (counts.isEmpty)
                  const FarmEmptyState(
                    icon: Icons.fact_check_outlined,
                    title: 'No cycle counts yet',
                    message:
                        'Start a cycle count when you are ready to compare physical stock with the warehouse lot ledger.',
                  )
                else
                  ...counts.map((count) {
                    final color = count.isCompleted
                        ? FarmColors.success
                        : count.isCancelled
                            ? FarmColors.mutedText
                            : FarmColors.warning;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: FarmCard(
                        padding: const EdgeInsets.all(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => WarehouseCycleCountDetailScreen(
                                  countId: count.id,
                                ),
                              ),
                            );
                            await _refresh();
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        count.title,
                                        style: const TextStyle(
                                          color: FarmColors.ink,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      count.statusLabel,
                                      style: TextStyle(
                                        color: color,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${count.scopeLabel} • ${_warehouseInventoryDate(count.startedAt)}',
                                  style: const TextStyle(
                                    color: FarmColors.mutedText,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: count.lines.isEmpty
                                      ? 0
                                      : count.countedLines / count.lines.length,
                                  minHeight: 6,
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  '${count.countedLines}/${count.lines.length} lots counted • ${count.varianceLines} variance line(s)',
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
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }
}

class WarehouseCycleCountDetailScreen extends StatefulWidget {
  final String countId;

  const WarehouseCycleCountDetailScreen({
    super.key,
    required this.countId,
  });

  @override
  State<WarehouseCycleCountDetailScreen> createState() =>
      _WarehouseCycleCountDetailScreenState();
}

class _WarehouseCycleCountDetailScreenState
    extends State<WarehouseCycleCountDetailScreen> {
  late Future<WarehouseCycleCount?> _future;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _future = fetchWarehouseCycleCount(widget.countId);
  }

  Future<void> _refresh() async {
    final next = fetchWarehouseCycleCount(widget.countId);
    setState(() => _future = next);
    await next;
  }

  Future<void> _recordLine(WarehouseCycleCountLine line) async {
    final existingCount = line.countedOnHand;
    final quantity = TextEditingController(
      text: existingCount == null
          ? ''
          : existingCount.toStringAsFixed(
              existingCount == existingCount.roundToDouble() ? 0 : 1,
            ),
    );
    final note = TextEditingController(text: line.countNote);

    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('Count ${line.productName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${line.locationLabel} • Lot ${line.lotCode}\nSystem on hand: ${line.quantity(line.expectedOnHand)} • Reserved: ${line.quantity(line.expectedReserved)}',
                style: const TextStyle(
                  color: FarmColors.mutedText,
                  fontSize: 11,
                  height: 1.4,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: quantity,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Physical on-hand count (${line.unit})',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: note,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Count note (optional)',
                ),
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
              child: const Text('Save Count'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      final double amount =
          double.tryParse(quantity.text.trim().replaceAll(',', '')) ?? -1.0;
      if (amount < 0) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a valid physical quantity.')),
        );
        return;
      }

      await recordWarehouseCycleCountLine(
        line: line,
        countedOnHand: amount,
        note: note.text,
      );
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyAppError(error))),
      );
    } finally {
      quantity.dispose();
      note.dispose();
    }
  }

  Future<void> _completeCount(WarehouseCycleCount count) async {
    if (!count.allCounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${count.lines.length - count.countedLines} lot(s) still need a physical count.',
          ),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Complete and reconcile count?'),
        content: Text(
          count.varianceLines == 0
              ? 'All lots have been counted and no quantity variance is recorded.'
              : '${count.varianceLines} lot(s) have a variance. Safe variances will be posted to the warehouse movement ledger.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Not Yet'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Complete & Reconcile'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await completeWarehouseCycleCount(count);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cycle count reconciled successfully.')),
      );
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyAppError(error))),
      );
    }
  }

  Future<void> _cancelCount(WarehouseCycleCount count) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel this cycle count?'),
        content: const Text(
          'No inventory quantity will be changed. The cancelled count remains available for audit history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep Count'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Cancel Count'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await cancelWarehouseCycleCount(count);
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
      appBar: const _WarehouseAppBar(title: 'Cycle Count Detail'),
      body: FutureBuilder<WarehouseCycleCount?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError && snapshot.data == null) {
            return Center(child: Text(friendlyAppError(snapshot.error!)));
          }

          final count = snapshot.data;
          if (count == null) {
            return const Center(child: Text('Cycle count not found.'));
          }

          final filtered = count.lines.where((line) {
            switch (_filter) {
              case 'uncounted':
                return !line.isCounted;
              case 'variance':
                return line.hasVariance;
              default:
                return true;
            }
          }).toList();

          final statusColor = count.isCompleted
              ? FarmColors.success
              : count.isCancelled
                  ? FarmColors.mutedText
                  : FarmColors.warning;

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 110),
              children: [
                FarmCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              count.title,
                              style: const TextStyle(
                                color: FarmColors.ink,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          Text(
                            count.statusLabel,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${count.scopeLabel} • Started ${_warehouseInventoryDate(count.startedAt)}',
                        style: const TextStyle(
                          color: FarmColors.mutedText,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (count.notes.isNotEmpty) ...[
                        const SizedBox(height: 7),
                        Text(
                          count.notes,
                          style: const TextStyle(
                            color: FarmColors.mutedText,
                            fontSize: 10.5,
                            height: 1.35,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: count.lines.isEmpty
                            ? 0
                            : count.countedLines / count.lines.length,
                        minHeight: 7,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${count.countedLines}/${count.lines.length} lots counted • ${count.varianceLines} variance line(s)',
                        style: const TextStyle(
                          color: FarmColors.mutedText,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (count.isInProgress) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _completeCount(count),
                                icon: const Icon(Icons.done_all_rounded),
                                label: const Text('Complete & Reconcile'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: () => _cancelCount(count),
                              child: const Text('Cancel'),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final option in const <MapEntry<String, String>>[
                        MapEntry('all', 'All Lots'),
                        MapEntry('uncounted', 'Uncounted'),
                        MapEntry('variance', 'Variance'),
                      ]) ...[
                        ChoiceChip(
                          label: Text(option.value),
                          selected: _filter == option.key,
                          onSelected: (_) =>
                              setState(() => _filter = option.key),
                        ),
                        const SizedBox(width: 7),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                if (filtered.isEmpty)
                  const FarmEmptyState(
                    icon: Icons.fact_check_outlined,
                    title: 'No count lines in this view',
                    message:
                        'Change the filter or continue counting the open lots.',
                  )
                else
                  ...filtered.map((line) {
                    final variance = line.variance ?? 0.0;
                    final varianceColor = !line.isCounted
                        ? FarmColors.mutedText
                        : variance.abs() <= 0.001
                            ? FarmColors.success
                            : FarmColors.warning;
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
                                  child: Text(
                                    line.productName,
                                    style: const TextStyle(
                                      color: FarmColors.ink,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                Text(
                                  line.isCounted
                                      ? variance.abs() <= 0.001
                                          ? 'MATCH'
                                          : variance > 0
                                              ? '+${line.quantity(variance)}'
                                              : line.quantity(variance)
                                      : 'NOT COUNTED',
                                  style: TextStyle(
                                    color: varianceColor,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${line.locationLabel} • Lot ${line.lotCode}',
                              style: TextStyle(
                                color: line.isUnassigned
                                    ? FarmColors.warning
                                    : FarmColors.primary,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 9),
                            Wrap(
                              spacing: 7,
                              runSpacing: 7,
                              children: [
                                _CycleCountValue(
                                  label: 'System on hand',
                                  value: line.quantity(line.expectedOnHand),
                                ),
                                _CycleCountValue(
                                  label: 'Reserved',
                                  value: line.quantity(line.expectedReserved),
                                ),
                                _CycleCountValue(
                                  label: 'Physical count',
                                  value: line.countedOnHand == null
                                      ? '—'
                                      : line.quantity(line.countedOnHand!),
                                ),
                              ],
                            ),
                            if (line.countNote.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                line.countNote,
                                style: const TextStyle(
                                  color: FarmColors.mutedText,
                                  fontSize: 10.5,
                                  height: 1.35,
                                ),
                              ),
                            ],
                            if (count.isInProgress) ...[
                              const SizedBox(height: 10),
                              OutlinedButton.icon(
                                onPressed: () => _recordLine(line),
                                icon: Icon(
                                  line.isCounted
                                      ? Icons.edit_outlined
                                      : Icons.numbers_outlined,
                                  size: 17,
                                ),
                                label: Text(
                                  line.isCounted ? 'Recount' : 'Enter Count',
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CycleCountMetric extends StatelessWidget {
  final String label;
  final String value;

  const _CycleCountMetric({required this.label, required this.value});

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
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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

class _CycleCountValue extends StatelessWidget {
  final String label;
  final String value;

  const _CycleCountValue({required this.label, required this.value});

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
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
