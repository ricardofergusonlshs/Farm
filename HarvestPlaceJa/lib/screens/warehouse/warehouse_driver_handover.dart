part of harvest_place_app;

// ================================================================
// THE HARVEST PLACE JA
// PHASE 3AG — DRIVER HANDOVER + LOADING CHECKLIST
// ================================================================

class WarehouseDriverHandoverScreen extends StatefulWidget {
  final WarehouseDispatchRun run;

  const WarehouseDriverHandoverScreen({
    super.key,
    required this.run,
  });

  @override
  State<WarehouseDriverHandoverScreen> createState() =>
      _WarehouseDriverHandoverScreenState();
}

class _WarehouseDriverHandoverScreenState
    extends State<WarehouseDriverHandoverScreen> {
  late Future<List<Object>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Object>> _load() async {
    final values = await Future.wait<Object>([
      fetchWarehouseDispatchRuns(includeClosed: true),
      fetchWarehouseDispatchRunStops(widget.run.id),
    ]);
    return values;
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() => _future = next);
    await next;
  }

  WarehouseDispatchRun _currentRun(List<WarehouseDispatchRun> runs) {
    return runs.firstWhere(
      (run) => run.id == widget.run.id,
      orElse: () => widget.run,
    );
  }

  Future<String?> _askNote({
    required String title,
    String label = 'Note (optional)',
    bool requireText = false,
  }) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(labelText: label),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(null),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final clean = controller.text.trim();
              if (requireText && clean.isEmpty) return;
              Navigator.of(dialogContext).pop(clean);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<void> _setLoaded(
    WarehouseDispatchRunStop stop,
    bool loaded,
  ) async {
    try {
      await setWarehouseDispatchStopLoaded(
        stop: stop,
        loaded: loaded,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            loaded ? 'Stop marked loaded.' : 'Stop returned to loading.',
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

  Future<void> _removeStop(WarehouseDispatchRunStop stop) async {
    final note = await _askNote(
      title: 'Remove ${stop.businessName} from this run?',
      label: 'Reason (optional)',
    );
    if (note == null) return;
    try {
      await removeWarehouseDispatchRunStop(stop: stop, note: note);
      if (!mounted) return;
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyAppError(error))),
      );
    }
  }

  Future<void> _handover(WarehouseDispatchRun run) async {
    final note = await _askNote(
      title: 'Confirm driver handover?',
      label: 'Keys / documents / handover note (optional)',
    );
    if (note == null) return;
    try {
      await confirmWarehouseDriverHandover(run: run, note: note);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Driver handover confirmed.')),
      );
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyAppError(error))),
      );
    }
  }

  Future<void> _depart(WarehouseDispatchRun run) async {
    final note = await _askNote(
      title: 'Start delivery run?',
      label: 'Departure note (optional)',
    );
    if (note == null) return;
    try {
      await startWarehouseDeliveryRun(run: run, note: note);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Run departed. Loaded orders are now out for delivery.',
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

  Future<void> _complete(WarehouseDispatchRun run) async {
    final note = await _askNote(
      title: 'Close completed delivery run?',
      label: 'Closeout note (optional)',
    );
    if (note == null) return;
    try {
      await completeWarehouseDeliveryRun(run: run, note: note);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Delivery run completed.')),
      );
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyAppError(error))),
      );
    }
  }

  Future<void> _cancel(WarehouseDispatchRun run) async {
    final note = await _askNote(
      title: 'Cancel ${run.runNumber}?',
      label: 'Cancellation reason',
      requireText: true,
    );
    if (note == null) return;
    try {
      await cancelWarehouseDispatchRun(run: run, note: note);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dispatch run cancelled.')),
      );
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyAppError(error))),
      );
    }
  }

  Color _runColor(WarehouseDispatchRun run) {
    if (run.isOutForDelivery) return FarmColors.primary;
    if (run.isReadyToDepart) return FarmColors.warning;
    if (run.isCompleted) return FarmColors.success;
    if (run.isCancelled) return FarmColors.mutedText;
    return FarmColors.ink;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: _WarehouseAppBar(title: widget.run.runNumber),
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
          final runs = data.isEmpty
              ? const <WarehouseDispatchRun>[]
              : data[0] as List<WarehouseDispatchRun>;
          final stops = data.length < 2
              ? const <WarehouseDispatchRunStop>[]
              : data[1] as List<WarehouseDispatchRunStop>;
          final run = _currentRun(runs);
          final activeStops = stops.where((stop) => !stop.isCancelled).toList();
          final loaded = activeStops.where((stop) => stop.isLoaded).length;
          final delivered = activeStops.where((stop) => stop.delivered).length;
          final color = _runColor(run);

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
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
                              run.runNumber,
                              style: const TextStyle(
                                color: FarmColors.ink,
                                fontSize: 18,
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
                      const SizedBox(height: 10),
                      _handoverInfo(
                        Icons.person_outline,
                        'Driver',
                        run.driverName.isEmpty ? 'Not assigned' : run.driverName,
                      ),
                      _handoverInfo(
                        Icons.local_shipping_outlined,
                        'Vehicle',
                        run.vehicleLabel.isEmpty ? 'Not recorded' : run.vehicleLabel,
                      ),
                      _handoverInfo(
                        Icons.schedule_outlined,
                        'Schedule',
                        _warehouseDispatchDateTimeLabel(run.scheduledFor),
                      ),
                      if (run.handedOverAt != null)
                        _handoverInfo(
                          Icons.verified_user_outlined,
                          'Handover',
                          _warehouseDispatchDateTimeLabel(run.handedOverAt),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _DispatchRunMetric(
                        label: 'Stops',
                        value: '${activeStops.length}',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _DispatchRunMetric(
                        label: 'Loaded',
                        value: '$loaded/${activeStops.length}',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _DispatchRunMetric(
                        label: 'Delivered',
                        value: '$delivered/${activeStops.length}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (activeStops.isEmpty)
                  const FarmEmptyState(
                    icon: Icons.local_shipping_outlined,
                    title: 'No active stops',
                    message: 'This dispatch run has no active delivery stops.',
                  )
                else
                  ...activeStops.map((stop) {
                    final canEdit = (run.isLoading || run.isReadyToDepart) &&
                        !run.handoverConfirmed;
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
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: FarmColors.primarySoft,
                                  child: Text(
                                    '${stop.sequenceNo}',
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
                                        stop.businessName,
                                        style: const TextStyle(
                                          color: FarmColors.ink,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        stop.deliveryAddress.isEmpty
                                            ? stop.deliveryParish
                                            : '${stop.deliveryAddress}${stop.deliveryParish.isEmpty ? '' : ' • ${stop.deliveryParish}'}',
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
                                if (canEdit)
                                  Checkbox(
                                    value: stop.isLoaded,
                                    onChanged: (value) =>
                                        _setLoaded(stop, value == true),
                                  )
                                else
                                  Icon(
                                    stop.delivered
                                        ? Icons.check_circle_rounded
                                        : stop.isDeparted
                                            ? Icons.route_outlined
                                            : stop.isLoaded
                                                ? Icons.inventory_rounded
                                                : Icons.pending_outlined,
                                    color: stop.delivered
                                        ? FarmColors.success
                                        : FarmColors.primary,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 7,
                              runSpacing: 7,
                              children: [
                                _HandoverChip(
                                  icon: Icons.move_to_inbox_outlined,
                                  text: stop.stagingLabel,
                                ),
                                _HandoverChip(
                                  icon: Icons.local_shipping_outlined,
                                  text: stop.dispatchStatus
                                      .replaceAll('_', ' ')
                                      .toUpperCase(),
                                ),
                                if (stop.loadedAt != null)
                                  _HandoverChip(
                                    icon: Icons.inventory_rounded,
                                    text: 'Loaded ${_warehouseDispatchDateTimeLabel(stop.loadedAt)}',
                                  ),
                              ],
                            ),
                            if (canEdit) ...[
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: () => _removeStop(stop),
                                  icon: const Icon(Icons.remove_circle_outline),
                                  label: const Text('Remove Stop'),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: 4),
                if (run.isReadyToDepart && !run.handoverConfirmed)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _handover(run),
                      icon: const Icon(Icons.handshake_outlined),
                      label: const Text('Confirm Driver Handover'),
                    ),
                  ),
                if (run.isReadyToDepart && run.handoverConfirmed) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _depart(run),
                      icon: const Icon(Icons.route_outlined),
                      label: const Text('Start Delivery Run'),
                    ),
                  ),
                ],
                if (run.isOutForDelivery) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: run.allTerminal ? () => _complete(run) : null,
                      icon: const Icon(Icons.task_alt_outlined),
                      label: Text(
                        run.allTerminal
                            ? 'Complete Delivery Run'
                            : 'Waiting for ${run.stopCount - run.terminalCount} Delivery Stop(s)',
                      ),
                    ),
                  ),
                ],
                if (!run.isClosed && !run.isOutForDelivery) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _cancel(run),
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Cancel Run'),
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

  Widget _handoverInfo(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: FarmColors.primary),
          const SizedBox(width: 8),
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(
                color: FarmColors.mutedText,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: FarmColors.ink,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HandoverChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HandoverChip({required this.icon, required this.text});

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
