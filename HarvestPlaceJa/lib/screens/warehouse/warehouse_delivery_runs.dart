part of harvest_place_app;

// ================================================================
// THE HARVEST PLACE JA
// PHASE 3AH — DELIVERY RUNS
// ================================================================

class WarehouseDispatchRun {
  final String id;
  final String runNumber;
  final DateTime runDate;
  final DateTime? scheduledFor;
  final String? driverId;
  final String driverName;
  final String vehicleLabel;
  final String status;
  final String notes;
  final String handoverNote;
  final DateTime? handedOverAt;
  final DateTime? departedAt;
  final DateTime? completedAt;
  final DateTime? createdAt;
  final int stopCount;
  final int loadedCount;
  final int departedCount;
  final int deliveredCount;
  final int terminalCount;
  final int cancelledStopCount;

  const WarehouseDispatchRun({
    required this.id,
    required this.runNumber,
    required this.runDate,
    required this.scheduledFor,
    required this.driverId,
    required this.driverName,
    required this.vehicleLabel,
    required this.status,
    required this.notes,
    required this.handoverNote,
    required this.handedOverAt,
    required this.departedAt,
    required this.completedAt,
    required this.createdAt,
    required this.stopCount,
    required this.loadedCount,
    required this.departedCount,
    required this.deliveredCount,
    required this.terminalCount,
    required this.cancelledStopCount,
  });

  factory WarehouseDispatchRun.fromSupabase(Map<String, dynamic> data) {
    int count(dynamic value) {
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    String? nullable(dynamic value) {
      final clean = value?.toString().trim() ?? '';
      return clean.isEmpty ? null : clean;
    }

    return WarehouseDispatchRun(
      id: (data['run_id'] ?? '').toString(),
      runNumber: (data['run_number'] ?? 'Dispatch Run').toString().trim(),
      runDate: DateTime.tryParse((data['run_date'] ?? '').toString()) ??
          DateTime.now(),
      scheduledFor:
          DateTime.tryParse((data['scheduled_for'] ?? '').toString()),
      driverId: nullable(data['driver_id']),
      driverName: (data['driver_name'] ?? '').toString().trim(),
      vehicleLabel: (data['vehicle_label'] ?? '').toString().trim(),
      status: (data['run_status'] ?? 'loading')
          .toString()
          .trim()
          .toLowerCase(),
      notes: (data['notes'] ?? '').toString().trim(),
      handoverNote: (data['handover_note'] ?? '').toString().trim(),
      handedOverAt:
          DateTime.tryParse((data['handed_over_at'] ?? '').toString()),
      departedAt: DateTime.tryParse((data['departed_at'] ?? '').toString()),
      completedAt:
          DateTime.tryParse((data['completed_at'] ?? '').toString()),
      createdAt: DateTime.tryParse((data['created_at'] ?? '').toString()),
      stopCount: count(data['stop_count']),
      loadedCount: count(data['loaded_count']),
      departedCount: count(data['departed_count']),
      deliveredCount: count(data['delivered_count']),
      terminalCount: count(data['terminal_count']),
      cancelledStopCount: count(data['cancelled_stop_count']),
    );
  }

  bool get isLoading => status == 'loading';
  bool get isReadyToDepart => status == 'ready_to_depart';
  bool get isOutForDelivery => status == 'out_for_delivery';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get isClosed => isCompleted || isCancelled;
  bool get handoverConfirmed => handedOverAt != null;
  bool get allLoaded => stopCount > 0 && loadedCount >= stopCount;
  bool get allDelivered => stopCount > 0 && deliveredCount >= stopCount;
  bool get allTerminal => stopCount > 0 && terminalCount >= stopCount;

  String get statusLabel {
    switch (status) {
      case 'ready_to_depart':
        return handoverConfirmed ? 'Handover Confirmed' : 'Ready to Depart';
      case 'out_for_delivery':
        return 'Out for Delivery';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Loading';
    }
  }
}

class WarehouseDispatchRunStop {
  final String id;
  final String runId;
  final String dispatchId;
  final String fulfillmentId;
  final int sequenceNo;
  final String status;
  final String loadNote;
  final DateTime? loadedAt;
  final String businessName;
  final String contactName;
  final String contactPhone;
  final String deliveryAddress;
  final String deliveryParish;
  final String dispatchStatus;
  final String? assignedDriverId;
  final DateTime? scheduledFor;
  final String? stagingId;
  final String stagingStatus;
  final String stagingAreaCode;
  final String stagingAreaName;

  const WarehouseDispatchRunStop({
    required this.id,
    required this.runId,
    required this.dispatchId,
    required this.fulfillmentId,
    required this.sequenceNo,
    required this.status,
    required this.loadNote,
    required this.loadedAt,
    required this.businessName,
    required this.contactName,
    required this.contactPhone,
    required this.deliveryAddress,
    required this.deliveryParish,
    required this.dispatchStatus,
    required this.assignedDriverId,
    required this.scheduledFor,
    required this.stagingId,
    required this.stagingStatus,
    required this.stagingAreaCode,
    required this.stagingAreaName,
  });

  factory WarehouseDispatchRunStop.fromSupabase(Map<String, dynamic> data) {
    String? nullable(dynamic value) {
      final clean = value?.toString().trim() ?? '';
      return clean.isEmpty ? null : clean;
    }

    int integer(dynamic value) {
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return WarehouseDispatchRunStop(
      id: (data['stop_id'] ?? '').toString(),
      runId: (data['run_id'] ?? '').toString(),
      dispatchId: (data['dispatch_id'] ?? '').toString(),
      fulfillmentId: (data['fulfillment_id'] ?? '').toString(),
      sequenceNo: integer(data['sequence_no']),
      status: (data['stop_status'] ?? 'planned')
          .toString()
          .trim()
          .toLowerCase(),
      loadNote: (data['load_note'] ?? '').toString().trim(),
      loadedAt: DateTime.tryParse((data['loaded_at'] ?? '').toString()),
      businessName:
          (data['business_name'] ?? 'Wholesale business').toString().trim(),
      contactName: (data['contact_name'] ?? '').toString().trim(),
      contactPhone: (data['contact_phone'] ?? '').toString().trim(),
      deliveryAddress: (data['delivery_address'] ?? '').toString().trim(),
      deliveryParish: (data['delivery_parish'] ?? '').toString().trim(),
      dispatchStatus:
          (data['dispatch_status'] ?? '').toString().trim().toLowerCase(),
      assignedDriverId: nullable(data['assigned_driver_id']),
      scheduledFor:
          DateTime.tryParse((data['scheduled_for'] ?? '').toString()),
      stagingId: nullable(data['staging_id']),
      stagingStatus:
          (data['staging_status'] ?? '').toString().trim().toLowerCase(),
      stagingAreaCode: (data['staging_area_code'] ?? '').toString().trim(),
      stagingAreaName: (data['staging_area_name'] ?? '').toString().trim(),
    );
  }

  bool get isLoaded => status == 'loaded';
  bool get isDeparted => status == 'departed';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get delivered => dispatchStatus == 'delivered';

  String get stagingLabel {
    if (stagingAreaCode.isNotEmpty && stagingAreaName.isNotEmpty) {
      return '$stagingAreaCode • $stagingAreaName';
    }
    if (stagingAreaCode.isNotEmpty) return stagingAreaCode;
    return stagingAreaName.isEmpty ? 'No staging area' : stagingAreaName;
  }
}

class WarehouseDispatchRunException {
  final String key;
  final String severity;
  final String title;
  final String detail;
  final String? runId;
  final String runNumber;
  final String? dispatchId;
  final DateTime? createdAt;

  const WarehouseDispatchRunException({
    required this.key,
    required this.severity,
    required this.title,
    required this.detail,
    required this.runId,
    required this.runNumber,
    required this.dispatchId,
    required this.createdAt,
  });

  factory WarehouseDispatchRunException.fromSupabase(
    Map<String, dynamic> data,
  ) {
    String? nullable(dynamic value) {
      final clean = value?.toString().trim() ?? '';
      return clean.isEmpty ? null : clean;
    }

    return WarehouseDispatchRunException(
      key: (data['exception_key'] ?? '').toString(),
      severity:
          (data['severity'] ?? 'warning').toString().trim().toLowerCase(),
      title: (data['title'] ?? 'Dispatch exception').toString().trim(),
      detail: (data['detail'] ?? '').toString().trim(),
      runId: nullable(data['run_id']),
      runNumber: (data['run_number'] ?? '').toString().trim(),
      dispatchId: nullable(data['dispatch_id']),
      createdAt: DateTime.tryParse((data['created_at'] ?? '').toString()),
    );
  }

  bool get isCritical => severity == 'critical';
}

String _warehouseDispatchIsoDate(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

String _warehouseDispatchDateLabel(DateTime? date) {
  if (date == null) return 'Not scheduled';
  const months = <String>[
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final local = date.toLocal();
  return '${local.day} ${months[local.month - 1]} ${local.year}';
}

String _warehouseDispatchDateTimeLabel(DateTime? value) {
  if (value == null) return 'Not scheduled';
  final local = value.toLocal();
  final hour = local.hour == 0
      ? 12
      : local.hour > 12
          ? local.hour - 12
          : local.hour;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour >= 12 ? 'PM' : 'AM';
  return '${_warehouseDispatchDateLabel(local)} • $hour:$minute $period';
}

Future<List<WarehouseDispatchRun>> fetchWarehouseDispatchRuns({
  bool includeClosed = false,
}) async {
  await requireAdminAccess();
  final response = await supabase.rpc(
    'admin_list_warehouse_dispatch_runs',
    params: {'p_include_closed': includeClosed},
  );
  return (response as List)
      .map(
        (row) => WarehouseDispatchRun.fromSupabase(
          Map<String, dynamic>.from(row as Map),
        ),
      )
      .toList();
}

Future<List<WarehouseDispatchRunStop>> fetchWarehouseDispatchRunStops(
  String runId,
) async {
  await requireAdminAccess();
  final response = await supabase.rpc(
    'admin_list_warehouse_dispatch_run_stops',
    params: {'p_run_id': runId},
  );
  return (response as List)
      .map(
        (row) => WarehouseDispatchRunStop.fromSupabase(
          Map<String, dynamic>.from(row as Map),
        ),
      )
      .toList();
}

Future<List<WarehouseDispatchRunException>>
    fetchWarehouseDispatchRunExceptions() async {
  await requireAdminAccess();
  final response =
      await supabase.rpc('admin_list_warehouse_dispatch_run_exceptions');
  return (response as List)
      .map(
        (row) => WarehouseDispatchRunException.fromSupabase(
          Map<String, dynamic>.from(row as Map),
        ),
      )
      .toList();
}

Future<String> createWarehouseDispatchRun({
  required DateTime runDate,
  DateTime? scheduledFor,
  required WholesaleDeliveryStaff driver,
  required List<String> dispatchIds,
  String vehicleLabel = '',
  String notes = '',
}) async {
  await requireAdminAccess();
  if (dispatchIds.isEmpty) {
    throw Exception('Select at least one staged delivery.');
  }
  final response = await supabase.rpc(
    'admin_create_warehouse_dispatch_run',
    params: {
      'p_run_date': _warehouseDispatchIsoDate(runDate),
      'p_scheduled_for': scheduledFor?.toUtc().toIso8601String(),
      'p_driver_id': driver.userId,
      'p_driver_name': driver.displayName,
      'p_vehicle_label': vehicleLabel.trim(),
      'p_dispatch_ids': dispatchIds,
      'p_notes': notes.trim(),
    },
  );
  final id = response?.toString().trim() ?? '';
  if (id.isEmpty) throw Exception('Dispatch run could not be created.');
  return id;
}

Future<void> setWarehouseDispatchStopLoaded({
  required WarehouseDispatchRunStop stop,
  required bool loaded,
  String note = '',
}) async {
  await requireAdminAccess();
  await supabase.rpc(
    'admin_set_warehouse_dispatch_stop_loaded',
    params: {
      'p_stop_id': stop.id,
      'p_loaded': loaded,
      'p_note': note.trim(),
    },
  );
}

Future<void> confirmWarehouseDriverHandover({
  required WarehouseDispatchRun run,
  String note = '',
}) async {
  await requireAdminAccess();
  await supabase.rpc(
    'admin_confirm_warehouse_driver_handover',
    params: {'p_run_id': run.id, 'p_note': note.trim()},
  );
}

Future<void> startWarehouseDeliveryRun({
  required WarehouseDispatchRun run,
  String note = '',
}) async {
  await requireAdminAccess();
  await supabase.rpc(
    'admin_start_warehouse_delivery_run',
    params: {'p_run_id': run.id, 'p_note': note.trim()},
  );
}

Future<void> completeWarehouseDeliveryRun({
  required WarehouseDispatchRun run,
  String note = '',
}) async {
  await requireAdminAccess();
  await supabase.rpc(
    'admin_complete_warehouse_delivery_run',
    params: {'p_run_id': run.id, 'p_note': note.trim()},
  );
}

Future<void> cancelWarehouseDispatchRun({
  required WarehouseDispatchRun run,
  String note = '',
}) async {
  await requireAdminAccess();
  await supabase.rpc(
    'admin_cancel_warehouse_dispatch_run',
    params: {'p_run_id': run.id, 'p_note': note.trim()},
  );
}

Future<void> removeWarehouseDispatchRunStop({
  required WarehouseDispatchRunStop stop,
  String note = '',
}) async {
  await requireAdminAccess();
  await supabase.rpc(
    'admin_remove_warehouse_dispatch_run_stop',
    params: {'p_stop_id': stop.id, 'p_note': note.trim()},
  );
}

class WarehouseDeliveryRunsScreen extends StatefulWidget {
  const WarehouseDeliveryRunsScreen({super.key});

  @override
  State<WarehouseDeliveryRunsScreen> createState() =>
      _WarehouseDeliveryRunsScreenState();
}

class _WarehouseDeliveryRunsScreenState
    extends State<WarehouseDeliveryRunsScreen> {
  late Future<List<WarehouseDispatchRun>> _future;
  bool _showHistory = false;

  @override
  void initState() {
    super.initState();
    _future = fetchWarehouseDispatchRuns();
  }

  Future<void> _refresh() async {
    final next = fetchWarehouseDispatchRuns(includeClosed: _showHistory);
    setState(() => _future = next);
    await next;
  }

  Color _statusColor(WarehouseDispatchRun run) {
    if (run.isOutForDelivery) return FarmColors.primary;
    if (run.isReadyToDepart) return FarmColors.warning;
    if (run.isCompleted) return FarmColors.success;
    if (run.isCancelled) return FarmColors.mutedText;
    return FarmColors.ink;
  }

  void _openRun(WarehouseDispatchRun run) {
    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (_) => WarehouseDriverHandoverScreen(run: run),
          ),
        )
        .then((_) => _refresh());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: const _WarehouseAppBar(title: 'Delivery Runs'),
      body: FutureBuilder<List<WarehouseDispatchRun>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError && snapshot.data == null) {
            return Center(child: Text(friendlyAppError(snapshot.error!)));
          }

          final runs = snapshot.data ?? const <WarehouseDispatchRun>[];
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
              children: [
                FarmCard(
                  padding: const EdgeInsets.all(16),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.local_shipping_outlined,
                          color: FarmColors.primary, size: 30),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Delivery Runs',
                              style: TextStyle(
                                color: FarmColors.ink,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Track loading, driver handover, departure and route completion while the existing wholesale dispatch remains the source of delivery status.',
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
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _showHistory,
                  title: const Text(
                    'Show completed / cancelled runs',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _showHistory = value;
                      _future = fetchWarehouseDispatchRuns(
                        includeClosed: value,
                      );
                    });
                  },
                ),
                const SizedBox(height: 8),
                if (runs.isEmpty)
                  const FarmEmptyState(
                    icon: Icons.route_outlined,
                    title: 'No delivery runs yet',
                    message:
                        'Create a run from the Dispatch Command Center after packed orders have been staged.',
                  )
                else
                  ...runs.map((run) {
                    final color = _statusColor(run);
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
                                    run.runNumber,
                                    style: const TextStyle(
                                      color: FarmColors.ink,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.10),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    run.statusLabel.toUpperCase(),
                                    style: TextStyle(
                                      color: color,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${run.driverName.isEmpty ? 'No driver' : run.driverName}'
                              '${run.vehicleLabel.isEmpty ? '' : ' • ${run.vehicleLabel}'}',
                              style: const TextStyle(
                                color: FarmColors.ink,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Scheduled: ${_warehouseDispatchDateTimeLabel(run.scheduledFor)}',
                              style: const TextStyle(
                                color: FarmColors.mutedText,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 7,
                              runSpacing: 7,
                              children: [
                                _DispatchRunMetric(
                                  label: 'Stops',
                                  value: '${run.stopCount}',
                                ),
                                _DispatchRunMetric(
                                  label: 'Loaded',
                                  value: '${run.loadedCount}/${run.stopCount}',
                                ),
                                _DispatchRunMetric(
                                  label: 'Delivered',
                                  value: '${run.deliveredCount}/${run.stopCount}',
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => _openRun(run),
                                icon: Icon(
                                  run.isOutForDelivery
                                      ? Icons.route_outlined
                                      : Icons.fact_check_outlined,
                                ),
                                label: Text(
                                  run.isOutForDelivery
                                      ? 'View Route'
                                      : run.isClosed
                                          ? 'View Run'
                                          : 'Open Handover',
                                ),
                              ),
                            ),
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

class _DispatchRunMetric extends StatelessWidget {
  final String label;
  final String value;

  const _DispatchRunMetric({required this.label, required this.value});

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
