part of harvest_place_app;

// ================================================================
// THE HARVEST PLACE JA
// PHASE 3X — FARMER COLLECTION PLANNING
// ================================================================

class WarehouseCollectionCandidate {
  final String receivingBatchId;
  final String farmerId;
  final String farmName;
  final String farmerName;
  final String phone;
  final String parish;
  final String address;
  final String productName;
  final double quantity;
  final String unit;
  final DateTime collectionDate;

  const WarehouseCollectionCandidate({
    required this.receivingBatchId,
    required this.farmerId,
    required this.farmName,
    required this.farmerName,
    required this.phone,
    required this.parish,
    required this.address,
    required this.productName,
    required this.quantity,
    required this.unit,
    required this.collectionDate,
  });

  factory WarehouseCollectionCandidate.fromSupabase(Map<String, dynamic> data) {
    final rawDate = (data['collection_date'] ?? '').toString();
    return WarehouseCollectionCandidate(
      receivingBatchId: (data['receiving_batch_id'] ?? '').toString(),
      farmerId: (data['farmer_id'] ?? '').toString(),
      farmName: (data['farm_name'] ?? 'Farm').toString().trim(),
      farmerName: (data['farmer_name'] ?? 'Farmer').toString().trim(),
      phone: (data['phone'] ?? '').toString().trim(),
      parish: (data['parish'] ?? '').toString().trim(),
      address: (data['address'] ?? '').toString().trim(),
      productName: (data['product_name'] ?? 'Produce').toString().trim(),
      quantity: _warehouseCollectionDouble(data['scheduled_quantity']),
      unit: (data['unit'] ?? 'unit').toString().trim(),
      collectionDate: DateTime.tryParse(rawDate) ?? DateTime.now(),
    );
  }

  String get quantityLabel => _warehouseCollectionQuantity(quantity, unit);
}

class WarehouseCollectionStop {
  final String id;
  final String runId;
  final String receivingBatchId;
  final String farmerId;
  final String farmName;
  final String farmerName;
  final String phone;
  final String parish;
  final String address;
  final String productName;
  final double plannedQuantity;
  final double collectedQuantity;
  final String unit;
  final int sequenceNo;
  final String status;
  final String note;
  final DateTime? collectedAt;

  const WarehouseCollectionStop({
    required this.id,
    required this.runId,
    required this.receivingBatchId,
    required this.farmerId,
    required this.farmName,
    required this.farmerName,
    required this.phone,
    required this.parish,
    required this.address,
    required this.productName,
    required this.plannedQuantity,
    required this.collectedQuantity,
    required this.unit,
    required this.sequenceNo,
    required this.status,
    required this.note,
    this.collectedAt,
  });

  factory WarehouseCollectionStop.fromSupabase(Map<String, dynamic> data) {
    return WarehouseCollectionStop(
      id: (data['id'] ?? '').toString(),
      runId: (data['run_id'] ?? '').toString(),
      receivingBatchId: (data['receiving_batch_id'] ?? '').toString(),
      farmerId: (data['farmer_id'] ?? '').toString(),
      farmName: (data['farm_name'] ?? 'Farm').toString().trim(),
      farmerName: (data['farmer_name'] ?? 'Farmer').toString().trim(),
      phone: (data['phone'] ?? '').toString().trim(),
      parish: (data['parish'] ?? '').toString().trim(),
      address: (data['address'] ?? '').toString().trim(),
      productName: (data['product_name'] ?? 'Produce').toString().trim(),
      plannedQuantity: _warehouseCollectionDouble(data['planned_quantity']),
      collectedQuantity: _warehouseCollectionDouble(data['collected_quantity']),
      unit: (data['unit'] ?? 'unit').toString().trim(),
      sequenceNo: _warehouseCollectionInt(data['sequence_no']),
      status: (data['status'] ?? 'planned').toString().trim().toLowerCase(),
      note: (data['note'] ?? '').toString().trim(),
      collectedAt: DateTime.tryParse((data['collected_at'] ?? '').toString()),
    );
  }

  bool get isPlanned => status == 'planned';
  bool get isCollected => status == 'collected';
  bool get isSkipped => status == 'skipped';
  bool get isTerminal => isCollected || isSkipped || status == 'cancelled';
  String get plannedLabel =>
      _warehouseCollectionQuantity(plannedQuantity, unit);
  String get collectedLabel =>
      _warehouseCollectionQuantity(collectedQuantity, unit);
}

class WarehouseCollectionRun {
  final String id;
  final DateTime collectionDate;
  final String status;
  final String? driverId;
  final String driverName;
  final String vehicleLabel;
  final String notes;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final List<WarehouseCollectionStop> stops;

  const WarehouseCollectionRun({
    required this.id,
    required this.collectionDate,
    required this.status,
    required this.driverId,
    required this.driverName,
    required this.vehicleLabel,
    required this.notes,
    this.startedAt,
    this.completedAt,
    required this.stops,
  });

  factory WarehouseCollectionRun.fromSupabase(Map<String, dynamic> data) {
    final rawStops = data['warehouse_collection_stops'];
    final stops = rawStops is List
        ? rawStops
            .whereType<Map>()
            .map(
              (row) => WarehouseCollectionStop.fromSupabase(
                Map<String, dynamic>.from(row),
              ),
            )
            .toList()
        : <WarehouseCollectionStop>[];
    stops.sort((a, b) => a.sequenceNo.compareTo(b.sequenceNo));

    return WarehouseCollectionRun(
      id: (data['id'] ?? '').toString(),
      collectionDate:
          DateTime.tryParse((data['collection_date'] ?? '').toString()) ??
              DateTime.now(),
      status: (data['status'] ?? 'planned').toString().trim().toLowerCase(),
      driverId: _warehouseCollectionNullable(data['driver_id']),
      driverName: (data['driver_name'] ?? '').toString().trim(),
      vehicleLabel: (data['vehicle_label'] ?? '').toString().trim(),
      notes: (data['notes'] ?? '').toString().trim(),
      startedAt: DateTime.tryParse((data['started_at'] ?? '').toString()),
      completedAt: DateTime.tryParse((data['completed_at'] ?? '').toString()),
      stops: stops,
    );
  }

  bool get isPlanned => status == 'planned';
  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';

  String get statusLabel {
    switch (status) {
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Planned';
    }
  }
}

const String _warehouseCollectionRunSelect =
    'id, collection_date, status, driver_id, driver_name, vehicle_label, notes, '
    'started_at, completed_at, created_at, updated_at, '
    'warehouse_collection_stops(id, run_id, receiving_batch_id, farmer_id, '
    'farm_name, farmer_name, phone, parish, address, product_name, '
    'planned_quantity, collected_quantity, unit, sequence_no, status, note, collected_at)';

double _warehouseCollectionDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

int _warehouseCollectionInt(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String? _warehouseCollectionNullable(dynamic value) {
  final clean = value?.toString().trim() ?? '';
  return clean.isEmpty ? null : clean;
}

String _warehouseCollectionQuantity(double value, String unit) {
  final amount = value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);
  return '$amount $unit';
}

String _warehouseCollectionDateLabel(DateTime date) {
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final local = date.toLocal();
  return '${local.day} ${months[local.month - 1]} ${local.year}';
}

String _warehouseCollectionIsoDate(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

Future<List<WarehouseCollectionCandidate>>
    fetchWarehouseCollectionCandidates() async {
  await requireAdminAccess();
  final response = await supabase.rpc(
    'admin_list_warehouse_collection_candidates',
  );
  return (response as List)
      .map(
        (row) => WarehouseCollectionCandidate.fromSupabase(
          Map<String, dynamic>.from(row),
        ),
      )
      .toList();
}

Future<List<WarehouseCollectionRun>> fetchWarehouseCollectionRuns() async {
  await requireAdminAccess();
  final response = await supabase
      .from('warehouse_collection_runs')
      .select(_warehouseCollectionRunSelect)
      .order('collection_date', ascending: false)
      .limit(100);
  return (response as List)
      .map(
        (row) => WarehouseCollectionRun.fromSupabase(
          Map<String, dynamic>.from(row),
        ),
      )
      .toList();
}

Future<void> createWarehouseCollectionRun({
  required DateTime collectionDate,
  String? driverId,
  String driverName = '',
  String vehicleLabel = '',
  String notes = '',
}) async {
  await requireAdminAccess();
  await supabase.rpc(
    'admin_create_warehouse_collection_run',
    params: {
      'p_collection_date': _warehouseCollectionIsoDate(collectionDate),
      'p_driver_id': driverId,
      'p_driver_name': driverName.trim(),
      'p_vehicle_label': vehicleLabel.trim(),
      'p_notes': notes.trim(),
    },
  );
}

Future<void> updateWarehouseCollectionRunStatus(
  WarehouseCollectionRun run,
  String status,
) async {
  await requireAdminAccess();
  await supabase.rpc(
    'admin_update_warehouse_collection_run_status',
    params: {
      'p_run_id': run.id,
      'p_status': status.trim().toLowerCase(),
    },
  );
}

Future<void> completeWarehouseCollectionStop({
  required WarehouseCollectionStop stop,
  required double collectedQuantity,
  String note = '',
}) async {
  await requireAdminAccess();
  await supabase.rpc(
    'admin_complete_warehouse_collection_stop',
    params: {
      'p_stop_id': stop.id,
      'p_collected_quantity': collectedQuantity,
      'p_note': note.trim(),
    },
  );
}

Future<void> skipWarehouseCollectionStop({
  required WarehouseCollectionStop stop,
  required String note,
}) async {
  await requireAdminAccess();
  await supabase.rpc(
    'admin_skip_warehouse_collection_stop',
    params: {
      'p_stop_id': stop.id,
      'p_note': note.trim(),
    },
  );
}

class CollectionPlanningScreen extends StatefulWidget {
  const CollectionPlanningScreen({super.key});

  @override
  State<CollectionPlanningScreen> createState() =>
      _CollectionPlanningScreenState();
}

class _CollectionPlanningScreenState extends State<CollectionPlanningScreen> {
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<dynamic>> _load() async {
    final values = await Future.wait<dynamic>([
      fetchWarehouseCollectionCandidates(),
      fetchWarehouseCollectionRuns(),
    ]);
    return values;
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() => _future = next);
    await next;
  }

  Future<void> _createRun(DateTime date) async {
    final vehicle = TextEditingController();
    final note = TextEditingController();
    final staff = await fetchWholesaleDeliveryStaff();
    if (!mounted) return;

    String? selectedDriverId;
    String selectedDriverName = '';

    final approved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  18,
                  18,
                  18,
                  MediaQuery.of(sheetContext).viewInsets.bottom + 18,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create collection run • ${_warehouseCollectionDateLabel(date)}',
                      style: const TextStyle(
                        color: FarmColors.ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: selectedDriverId,
                      decoration: const InputDecoration(
                        labelText: 'Delivery staff / driver (optional)',
                      ),
                      items: staff
                          .map(
                            (person) => DropdownMenuItem<String>(
                              value: person.userId,
                              child: Text(person.displayName),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setSheetState(() {
                          selectedDriverId = value;
                          if (value == null) {
                            selectedDriverName = '';
                          } else {
                            final match = staff.firstWhere(
                              (person) => person.userId == value,
                            );
                            selectedDriverName = match.displayName;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: vehicle,
                      decoration: const InputDecoration(
                        labelText: 'Vehicle / route label (optional)',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: note,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Run notes (optional)',
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.of(sheetContext).pop(true),
                        icon: const Icon(Icons.route_outlined),
                        label: const Text('Create Run'),
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

    if (approved != true) {
      vehicle.dispose();
      note.dispose();
      return;
    }

    try {
      await createWarehouseCollectionRun(
        collectionDate: date,
        driverId: selectedDriverId,
        driverName: selectedDriverName,
        vehicleLabel: vehicle.text,
        notes: note.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Collection run created.')),
      );
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyAppError(error))),
      );
    } finally {
      vehicle.dispose();
      note.dispose();
    }
  }

  Future<void> _completeStop(WarehouseCollectionStop stop) async {
    final quantity = TextEditingController(
      text: stop.plannedQuantity.toStringAsFixed(
        stop.plannedQuantity == stop.plannedQuantity.roundToDouble() ? 0 : 1,
      ),
    );
    final note = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Collect ${stop.productName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: quantity,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Collected quantity (${stop.unit})',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: note,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Collection note'),
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
            child: const Text('Confirm Collection'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      quantity.dispose();
      note.dispose();
      return;
    }

    final amount =
        double.tryParse(quantity.text.trim().replaceAll(',', '')) ?? 0;
    try {
      await completeWarehouseCollectionStop(
        stop: stop,
        collectedQuantity: amount,
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

  Future<void> _skipStop(WarehouseCollectionStop stop) async {
    final note = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Skip collection stop?'),
        content: TextField(
          controller: note,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Reason *',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Skip Stop'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      note.dispose();
      return;
    }
    try {
      await skipWarehouseCollectionStop(stop: stop, note: note.text);
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
      appBar: const _WarehouseAppBar(title: 'Farmer Collection Planning'),
      body: FutureBuilder<List<dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError && snapshot.data == null) {
            return Center(child: Text(friendlyAppError(snapshot.error!)));
          }

          final data = snapshot.data ?? const <dynamic>[];
          final candidates = data.isEmpty
              ? const <WarehouseCollectionCandidate>[]
              : data[0] as List<WarehouseCollectionCandidate>;
          final runs = data.length < 2
              ? const <WarehouseCollectionRun>[]
              : data[1] as List<WarehouseCollectionRun>;

          final grouped = <String, List<WarehouseCollectionCandidate>>{};
          for (final candidate in candidates) {
            final key = _warehouseCollectionIsoDate(candidate.collectionDate);
            grouped.putIfAbsent(key, () => <WarehouseCollectionCandidate>[])
              ..add(candidate);
          }
          final keys = grouped.keys.toList()..sort();

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
              children: [
                const FarmCard(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.route_outlined,
                          color: FarmColors.primary, size: 30),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Collection Planning',
                              style: TextStyle(
                                color: FarmColors.ink,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Turn scheduled HPJ farmer pickups from Receiving into organised collection runs.',
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
                const SizedBox(height: 16),
                const Text(
                  'Ready to Plan',
                  style: TextStyle(
                    color: FarmColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                if (keys.isEmpty)
                  const FarmCard(
                    child: Text(
                        'No unplanned HPJ collection batches are waiting.'),
                  )
                else
                  ...keys.map((key) {
                    final items = grouped[key]!;
                    final date = items.first.collectionDate;
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
                                    _warehouseCollectionDateLabel(date),
                                    style: const TextStyle(
                                      color: FarmColors.ink,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () => _createRun(date),
                                  icon: const Icon(Icons.add_road_rounded,
                                      size: 17),
                                  label: const Text('Create Run'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ...items.take(6).map(
                                  (item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 5),
                                    child: Text(
                                      '${item.farmName} • ${item.productName} • ${item.quantityLabel} • ${item.parish}',
                                      style: const TextStyle(
                                        color: FarmColors.mutedText,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                            if (items.length > 6)
                              Text(
                                '+ ${items.length - 6} more stop(s)',
                                style: const TextStyle(
                                  color: FarmColors.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: 18),
                const Text(
                  'Collection Runs',
                  style: TextStyle(
                    color: FarmColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                if (runs.isEmpty)
                  const FarmCard(child: Text('No collection runs yet.'))
                else
                  ...runs.map((run) {
                    final statusColor = run.isCompleted
                        ? FarmColors.success
                        : run.isCancelled
                            ? FarmColors.danger
                            : run.isInProgress
                                ? FarmColors.primary
                                : FarmColors.warning;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: FarmCard(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _warehouseCollectionDateLabel(
                                        run.collectionDate),
                                    style: const TextStyle(
                                      color: FarmColors.ink,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                Text(
                                  run.statusLabel,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${run.stops.length} stop(s)${run.driverName.isEmpty ? '' : ' • ${run.driverName}'}${run.vehicleLabel.isEmpty ? '' : ' • ${run.vehicleLabel}'}',
                              style: const TextStyle(
                                color: FarmColors.mutedText,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (run.isPlanned) ...[
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  await updateWarehouseCollectionRunStatus(
                                    run,
                                    'in_progress',
                                  );
                                  await _refresh();
                                },
                                icon: const Icon(Icons.play_arrow_rounded,
                                    size: 17),
                                label: const Text('Start Run'),
                              ),
                            ],
                            const SizedBox(height: 10),
                            ...run.stops.map((stop) {
                              return Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 8),
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
                                      '${stop.sequenceNo}. ${stop.farmName} — ${stop.productName}',
                                      style: const TextStyle(
                                        color: FarmColors.ink,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${stop.plannedLabel} • ${stop.parish}${stop.address.isEmpty ? '' : ' • ${stop.address}'}',
                                      style: const TextStyle(
                                        color: FarmColors.mutedText,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (stop.isCollected)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 5),
                                        child: Text(
                                          'Collected ${stop.collectedLabel}',
                                          style: const TextStyle(
                                            color: FarmColors.success,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      )
                                    else if (stop.isSkipped)
                                      const Padding(
                                        padding: EdgeInsets.only(top: 5),
                                        child: Text(
                                          'Skipped',
                                          style: TextStyle(
                                            color: FarmColors.warning,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      )
                                    else if (!run.isCompleted &&
                                        !run.isCancelled) ...[
                                      const SizedBox(height: 7),
                                      Wrap(
                                        spacing: 7,
                                        runSpacing: 7,
                                        children: [
                                          ElevatedButton(
                                            onPressed: () =>
                                                _completeStop(stop),
                                            child: const Text('Collected'),
                                          ),
                                          TextButton(
                                            onPressed: () => _skipStop(stop),
                                            child: const Text('Skip'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }),
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
