part of harvest_place_app;

// ================================================================
// THE HARVEST PLACE JA
// PHASE 3AF — DISPATCH COMMAND CENTER
// ================================================================

class WarehouseDispatchCandidate {
  final String fulfillmentId;
  final String requestId;
  final String businessName;
  final DateTime? requestedDate;
  final String requestedWindowLabel;
  final String deliveryAddress;
  final String deliveryParish;
  final String stagingId;
  final String stagingAreaCode;
  final String stagingAreaName;
  final String? dispatchId;
  final String dispatchStatus;
  final String? assignedDriverId;
  final DateTime? scheduledFor;
  final String? activeRunId;
  final String activeRunNumber;

  const WarehouseDispatchCandidate({
    required this.fulfillmentId,
    required this.requestId,
    required this.businessName,
    required this.requestedDate,
    required this.requestedWindowLabel,
    required this.deliveryAddress,
    required this.deliveryParish,
    required this.stagingId,
    required this.stagingAreaCode,
    required this.stagingAreaName,
    required this.dispatchId,
    required this.dispatchStatus,
    required this.assignedDriverId,
    required this.scheduledFor,
    required this.activeRunId,
    required this.activeRunNumber,
  });

  factory WarehouseDispatchCandidate.fromSupabase(Map<String, dynamic> data) {
    String? nullable(dynamic value) {
      final clean = value?.toString().trim() ?? '';
      return clean.isEmpty ? null : clean;
    }

    return WarehouseDispatchCandidate(
      fulfillmentId: (data['fulfillment_id'] ?? '').toString(),
      requestId: (data['request_id'] ?? '').toString(),
      businessName:
          (data['business_name'] ?? 'Wholesale business').toString().trim(),
      requestedDate:
          DateTime.tryParse((data['requested_date'] ?? '').toString()),
      requestedWindowLabel:
          (data['requested_window_label'] ?? '').toString().trim(),
      deliveryAddress: (data['delivery_address'] ?? '').toString().trim(),
      deliveryParish: (data['delivery_parish'] ?? '').toString().trim(),
      stagingId: (data['staging_id'] ?? '').toString(),
      stagingAreaCode: (data['staging_area_code'] ?? '').toString().trim(),
      stagingAreaName: (data['staging_area_name'] ?? '').toString().trim(),
      dispatchId: nullable(data['dispatch_id']),
      dispatchStatus:
          (data['dispatch_status'] ?? '').toString().trim().toLowerCase(),
      assignedDriverId: nullable(data['assigned_driver_id']),
      scheduledFor:
          DateTime.tryParse((data['scheduled_for'] ?? '').toString()),
      activeRunId: nullable(data['active_run_id']),
      activeRunNumber: (data['active_run_number'] ?? '').toString().trim(),
    );
  }

  bool get hasDispatch => dispatchId != null;
  bool get hasActiveRun => activeRunId != null;
  bool get canSelect => hasDispatch && !hasActiveRun;

  String get stagingLabel {
    if (stagingAreaCode.isNotEmpty && stagingAreaName.isNotEmpty) {
      return '$stagingAreaCode • $stagingAreaName';
    }
    if (stagingAreaCode.isNotEmpty) return stagingAreaCode;
    return stagingAreaName.isEmpty ? 'Staged' : stagingAreaName;
  }
}

Future<List<WarehouseDispatchCandidate>>
    fetchWarehouseDispatchCandidates() async {
  await requireAdminAccess();
  final response =
      await supabase.rpc('admin_list_warehouse_dispatch_candidates');
  return (response as List)
      .map(
        (row) => WarehouseDispatchCandidate.fromSupabase(
          Map<String, dynamic>.from(row as Map),
        ),
      )
      .toList();
}

Future<String> createWarehouseDispatchPlanForCandidate({
  required WarehouseDispatchCandidate candidate,
  DateTime? scheduledFor,
}) async {
  await requireAdminAccess();
  final response = await supabase.rpc(
    'admin_create_wholesale_dispatch',
    params: {
      'p_fulfillment_id': candidate.fulfillmentId,
      'p_dispatch_method': 'hpj_delivery',
      'p_scheduled_for': scheduledFor?.toUtc().toIso8601String(),
    },
  );
  final id = response?.toString().trim() ?? '';
  if (id.isEmpty) throw Exception('Dispatch plan could not be created.');
  return id;
}

class WarehouseDispatchCommandCenterScreen extends StatefulWidget {
  const WarehouseDispatchCommandCenterScreen({super.key});

  @override
  State<WarehouseDispatchCommandCenterScreen> createState() =>
      _WarehouseDispatchCommandCenterScreenState();
}

class _WarehouseDispatchCommandCenterScreenState
    extends State<WarehouseDispatchCommandCenterScreen> {
  late Future<List<Object>> _future;
  final Set<String> _selectedDispatchIds = <String>{};

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Object>> _load() {
    return Future.wait<Object>([
      fetchWarehouseDispatchCandidates(),
      fetchWarehouseDispatchRuns(),
      fetchWarehouseDispatchRunExceptions(),
      fetchWholesaleDeliveryStaff(),
    ]);
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() {
      _selectedDispatchIds.clear();
      _future = next;
    });
    await next;
  }

  Future<void> _createDispatchPlan(WarehouseDispatchCandidate candidate) async {
    try {
      await createWarehouseDispatchPlanForCandidate(candidate: candidate);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wholesale dispatch plan created.')),
      );
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyAppError(error))),
      );
    }
  }

  Future<void> _createRun(
    List<WarehouseDispatchCandidate> candidates,
    List<WholesaleDeliveryStaff> drivers,
  ) async {
    final selected = candidates
        .where(
          (candidate) => candidate.dispatchId != null &&
              _selectedDispatchIds.contains(candidate.dispatchId),
        )
        .toList();
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one staged delivery.')),
      );
      return;
    }
    if (drivers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add or link an active Delivery staff member first.'),
        ),
      );
      return;
    }

    DateTime runDate = DateTime.now();
    DateTime? scheduledFor;
    String? selectedDriverId;
    final vehicle = TextEditingController();
    final notes = TextEditingController();

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          WholesaleDeliveryStaff? selectedDriver;
          if (selectedDriverId != null) {
            for (final driver in drivers) {
              if (driver.userId == selectedDriverId) {
                selectedDriver = driver;
                break;
              }
            }
          }

          return SafeArea(
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
                      'Create Dispatch Run',
                      style: TextStyle(
                        color: FarmColors.ink,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${selected.length} staged delivery${selected.length == 1 ? '' : 'ies'} selected',
                      style: const TextStyle(
                        color: FarmColors.mutedText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: selectedDriverId,
                      decoration: const InputDecoration(labelText: 'Driver *'),
                      items: drivers
                          .map(
                            (driver) => DropdownMenuItem<String>(
                              value: driver.userId,
                              child: Text(driver.displayName),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setSheetState(() => selectedDriverId = value),
                    ),
                    const SizedBox(height: 10),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.calendar_month_outlined,
                        color: FarmColors.primary,
                      ),
                      title: const Text('Run date'),
                      subtitle: Text(_warehouseDispatchDateLabel(runDate)),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: runDate,
                          firstDate:
                              DateTime.now().subtract(const Duration(days: 1)),
                          lastDate:
                              DateTime.now().add(const Duration(days: 90)),
                        );
                        if (picked != null) {
                          setSheetState(() => runDate = picked);
                        }
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.schedule_outlined,
                        color: FarmColors.primary,
                      ),
                      title: const Text('Departure time (optional)'),
                      subtitle: Text(
                        scheduledFor == null
                            ? 'Not set'
                            : _warehouseDispatchDateTimeLabel(scheduledFor),
                      ),
                      trailing: scheduledFor == null
                          ? null
                          : IconButton(
                              onPressed: () =>
                                  setSheetState(() => scheduledFor = null),
                              icon: const Icon(Icons.clear_rounded),
                            ),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: const TimeOfDay(hour: 8, minute: 0),
                        );
                        if (time != null) {
                          setSheetState(() {
                            scheduledFor = DateTime(
                              runDate.year,
                              runDate.month,
                              runDate.day,
                              time.hour,
                              time.minute,
                            );
                          });
                        }
                      },
                    ),
                    TextField(
                      controller: vehicle,
                      decoration: const InputDecoration(
                        labelText: 'Vehicle / truck label (optional)',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: notes,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Run notes (optional)',
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: selectedDriver == null
                            ? null
                            : () => Navigator.of(sheetContext).pop(true),
                        icon: const Icon(Icons.route_outlined),
                        label: const Text('Create Run'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );

    if (confirmed != true) {
      vehicle.dispose();
      notes.dispose();
      return;
    }

    final driver = drivers.firstWhere(
      (item) => item.userId == selectedDriverId,
    );

    try {
      await createWarehouseDispatchRun(
        runDate: runDate,
        scheduledFor: scheduledFor,
        driver: driver,
        dispatchIds: selected.map((item) => item.dispatchId!).toList(),
        vehicleLabel: vehicle.text,
        notes: notes.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dispatch run created.')),
      );
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyAppError(error))),
      );
    } finally {
      vehicle.dispose();
      notes.dispose();
    }
  }

  Color _exceptionColor(WarehouseDispatchRunException item) {
    return item.isCritical ? FarmColors.danger : FarmColors.warning;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: const _WarehouseAppBar(title: 'Dispatch Command Center'),
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
          final candidates = data.isEmpty
              ? const <WarehouseDispatchCandidate>[]
              : data[0] as List<WarehouseDispatchCandidate>;
          final runs = data.length < 2
              ? const <WarehouseDispatchRun>[]
              : data[1] as List<WarehouseDispatchRun>;
          final exceptions = data.length < 3
              ? const <WarehouseDispatchRunException>[]
              : data[2] as List<WarehouseDispatchRunException>;
          final drivers = data.length < 4
              ? const <WholesaleDeliveryStaff>[]
              : data[3] as List<WholesaleDeliveryStaff>;

          final unplanned = candidates
              .where((candidate) => !candidate.hasActiveRun)
              .length;
          final loading = runs
              .where((run) => run.isLoading || run.isReadyToDepart)
              .length;
          final onRoute = runs.where((run) => run.isOutForDelivery).length;

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              children: [
                FarmCard(
                  padding: const EdgeInsets.all(16),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.local_shipping_outlined,
                        color: FarmColors.primary,
                        size: 30,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dispatch Command Center',
                              style: TextStyle(
                                color: FarmColors.ink,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Turn staged wholesale deliveries into controlled driver runs. Loading and handover are verified before any order leaves the warehouse.',
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
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _DispatchCommandMetric(
                        label: 'Ready to Plan',
                        value: '$unplanned',
                        icon: Icons.move_to_inbox_outlined,
                      ),
                      const SizedBox(width: 8),
                      _DispatchCommandMetric(
                        label: 'Loading',
                        value: '$loading',
                        icon: Icons.inventory_2_outlined,
                      ),
                      const SizedBox(width: 8),
                      _DispatchCommandMetric(
                        label: 'On Route',
                        value: '$onRoute',
                        icon: Icons.route_outlined,
                      ),
                      const SizedBox(width: 8),
                      _DispatchCommandMetric(
                        label: 'Exceptions',
                        value: '${exceptions.length}',
                        icon: Icons.warning_amber_rounded,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const WarehouseDeliveryRunsScreen(),
                          ),
                        ).then((_) => _refresh()),
                        icon: const Icon(Icons.route_outlined),
                        label: const Text('Delivery Runs'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                const WarehouseDispatchStagingScreen(),
                          ),
                        ).then((_) => _refresh()),
                        icon: const Icon(Icons.move_to_inbox_outlined),
                        label: const Text('Staging'),
                      ),
                    ),
                  ],
                ),
                if (exceptions.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Text(
                    'Dispatch Exceptions',
                    style: TextStyle(
                      color: FarmColors.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...exceptions.take(5).map((item) {
                    final color = _exceptionColor(item);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: color.withOpacity(0.25)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              item.isCritical
                                  ? Icons.error_outline
                                  : Icons.warning_amber_rounded,
                              color: color,
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    item.detail,
                                    style: const TextStyle(
                                      color: FarmColors.ink,
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
                    );
                  }),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Staged HPJ Deliveries',
                        style: TextStyle(
                          color: FarmColors.ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    if (_selectedDispatchIds.isNotEmpty)
                      TextButton.icon(
                        onPressed: () => _createRun(candidates, drivers),
                        icon: const Icon(Icons.add_road_outlined),
                        label: Text(
                          'Create Run (${_selectedDispatchIds.length})',
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (candidates.isEmpty)
                  const FarmEmptyState(
                    icon: Icons.move_to_inbox_outlined,
                    title: 'No staged HPJ deliveries',
                    message:
                        'Fully packed HPJ delivery orders will appear here after they are placed in dispatch staging.',
                  )
                else
                  ...candidates.map((candidate) {
                    final dispatchId = candidate.dispatchId;
                    final selected = dispatchId != null &&
                        _selectedDispatchIds.contains(dispatchId);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: FarmCard(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (candidate.canSelect)
                                  Checkbox(
                                    value: selected,
                                    onChanged: (value) {
                                      setState(() {
                                        if (value == true) {
                                          _selectedDispatchIds.add(dispatchId!);
                                        } else {
                                          _selectedDispatchIds.remove(dispatchId);
                                        }
                                      });
                                    },
                                  )
                                else
                                  const Padding(
                                    padding: EdgeInsets.all(10),
                                    child: Icon(
                                      Icons.local_shipping_outlined,
                                      color: FarmColors.primary,
                                    ),
                                  ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        candidate.businessName,
                                        style: const TextStyle(
                                          color: FarmColors.ink,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        candidate.deliveryAddress.isEmpty
                                            ? candidate.deliveryParish
                                            : '${candidate.deliveryAddress}${candidate.deliveryParish.isEmpty ? '' : ' • ${candidate.deliveryParish}'}',
                                        style: const TextStyle(
                                          color: FarmColors.mutedText,
                                          fontSize: 10.5,
                                          height: 1.3,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 9),
                            Wrap(
                              spacing: 7,
                              runSpacing: 7,
                              children: [
                                _DispatchCandidateChip(
                                  icon: Icons.move_to_inbox_outlined,
                                  text: candidate.stagingLabel,
                                ),
                                _DispatchCandidateChip(
                                  icon: Icons.schedule_outlined,
                                  text: _warehouseDispatchDateTimeLabel(
                                    candidate.scheduledFor,
                                  ),
                                ),
                                if (candidate.hasActiveRun)
                                  _DispatchCandidateChip(
                                    icon: Icons.route_outlined,
                                    text: candidate.activeRunNumber,
                                  ),
                              ],
                            ),
                            if (!candidate.hasDispatch) ...[
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () =>
                                      _createDispatchPlan(candidate),
                                  icon: const Icon(Icons.add_task_outlined),
                                  label: const Text('Create Dispatch Plan'),
                                ),
                              ),
                            ] else if (candidate.hasActiveRun) ...[
                              const SizedBox(height: 9),
                              Text(
                                'Already assigned to ${candidate.activeRunNumber}.',
                                style: const TextStyle(
                                  color: FarmColors.mutedText,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
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
      floatingActionButton: _selectedDispatchIds.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () async {
                final data = await _future;
                if (!mounted) return;
                await _createRun(
                  data[0] as List<WarehouseDispatchCandidate>,
                  data[3] as List<WholesaleDeliveryStaff>,
                );
              },
              icon: const Icon(Icons.add_road_outlined),
              label: Text('Run ${_selectedDispatchIds.length}'),
            ),
    );
  }
}

class _DispatchCommandMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _DispatchCommandMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FarmColors.cardSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FarmColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: FarmColors.primary),
          const SizedBox(height: 8),
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
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DispatchCandidateChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _DispatchCandidateChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: FarmColors.cardSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: FarmColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: FarmColors.primary),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: FarmColors.ink,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
