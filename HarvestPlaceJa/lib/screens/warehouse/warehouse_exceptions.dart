part of harvest_place_app;

// ================================================================
// THE HARVEST PLACE JA
// PHASE 3AE — WAREHOUSE EXCEPTION CENTER
//
// Exceptions are computed from live operational state. There is no duplicate
// exception status table to keep in sync.
// ================================================================

class WarehouseExceptionItem {
  final String key;
  final String severity;
  final String type;
  final String title;
  final String detail;
  final String? fulfillmentId;
  final String? requestId;
  final String? reservationId;
  final String? lotId;
  final String sourceStatus;
  final DateTime? occurredAt;

  const WarehouseExceptionItem({
    required this.key,
    required this.severity,
    required this.type,
    required this.title,
    required this.detail,
    required this.fulfillmentId,
    required this.requestId,
    required this.reservationId,
    required this.lotId,
    required this.sourceStatus,
    required this.occurredAt,
  });

  factory WarehouseExceptionItem.fromSupabase(Map<String, dynamic> data) {
    String? nullable(dynamic value) {
      final clean = value?.toString().trim() ?? '';
      return clean.isEmpty ? null : clean;
    }

    return WarehouseExceptionItem(
      key: (data['exception_key'] ?? '').toString().trim(),
      severity: (data['severity'] ?? 'warning').toString().trim().toLowerCase(),
      type: (data['exception_type'] ?? '').toString().trim().toLowerCase(),
      title: (data['title'] ?? 'Warehouse issue').toString().trim(),
      detail: (data['detail'] ?? '').toString().trim(),
      fulfillmentId: nullable(data['fulfillment_id']),
      requestId: nullable(data['request_id']),
      reservationId: nullable(data['reservation_id']),
      lotId: nullable(data['lot_id']),
      sourceStatus: (data['source_status'] ?? '').toString().trim(),
      occurredAt: DateTime.tryParse((data['occurred_at'] ?? '').toString()),
    );
  }

  bool get isCritical => severity == 'critical';
  bool get isWarning => severity == 'warning';

  String get severityLabel {
    if (isCritical) return 'Critical';
    if (isWarning) return 'Warning';
    return 'Info';
  }

  String get typeLabel {
    return type
        .split('_')
        .map(
          (word) => word.isEmpty
              ? ''
              : '${word.substring(0, 1).toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }
}

String _warehouseExceptionDateTime(DateTime? value) {
  if (value == null) return 'Time unavailable';
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

Future<List<WarehouseExceptionItem>> fetchWarehouseExceptions() async {
  await requireAdminAccess();
  final response = await supabase.rpc(
    'admin_list_warehouse_exceptions',
  );
  return (response as List)
      .map(
        (row) => WarehouseExceptionItem.fromSupabase(
          Map<String, dynamic>.from(row as Map),
        ),
      )
      .toList();
}

class WarehouseExceptionsScreen extends StatefulWidget {
  const WarehouseExceptionsScreen({super.key});

  @override
  State<WarehouseExceptionsScreen> createState() =>
      _WarehouseExceptionsScreenState();
}

class _WarehouseExceptionsScreenState extends State<WarehouseExceptionsScreen> {
  late Future<List<WarehouseExceptionItem>> _future;
  String _filter = 'open';

  @override
  void initState() {
    super.initState();
    _future = fetchWarehouseExceptions();
  }

  Future<void> _refresh() async {
    final next = fetchWarehouseExceptions();
    setState(() => _future = next);
    await next;
  }

  Color _severityColor(WarehouseExceptionItem item) {
    if (item.isCritical) return FarmColors.danger;
    if (item.isWarning) return FarmColors.warning;
    return FarmColors.primary;
  }

  IconData _iconFor(WarehouseExceptionItem item) {
    switch (item.type) {
      case 'lot_missing_location':
      case 'reserved_quarantined_lot':
        return Icons.inventory_2_outlined;
      case 'packing_before_pick_complete':
      case 'partial_pick':
        return Icons.playlist_add_check_circle_outlined;
      case 'ready_not_staged':
      case 'staged_no_dispatch':
      case 'dispatch_departed_still_staged':
        return Icons.move_to_inbox_outlined;
      case 'open_cycle_variance':
        return Icons.fact_check_outlined;
      case 'packing_wave_stalled':
        return Icons.view_week_outlined;
      default:
        return Icons.warning_amber_rounded;
    }
  }

  String _actionLabel(WarehouseExceptionItem item) {
    switch (item.type) {
      case 'lot_missing_location':
      case 'reserved_quarantined_lot':
        return 'Open Inventory';
      case 'packing_before_pick_complete':
      case 'partial_pick':
        return 'Open Pick Queue';
      case 'ready_not_staged':
      case 'staged_no_dispatch':
      case 'dispatch_departed_still_staged':
        return 'Open Staging';
      case 'open_cycle_variance':
        return 'Open Cycle Counts';
      case 'packing_wave_stalled':
        return 'Open Packing Waves';
      default:
        return 'Open Operations';
    }
  }

  Widget _actionScreen(WarehouseExceptionItem item) {
    switch (item.type) {
      case 'lot_missing_location':
      case 'reserved_quarantined_lot':
        return const WarehouseInventoryScreen();
      case 'packing_before_pick_complete':
      case 'partial_pick':
        return const WarehousePickingScreen();
      case 'ready_not_staged':
      case 'staged_no_dispatch':
      case 'dispatch_departed_still_staged':
        return const WarehouseDispatchStagingScreen();
      case 'open_cycle_variance':
        return const WarehouseCycleCountsScreen();
      case 'packing_wave_stalled':
        return const WarehousePackingWavesScreen();
      default:
        return const ProcurementCommandCenterScreen();
    }
  }

  Future<void> _openAction(WarehouseExceptionItem item) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => _actionScreen(item)),
    );
    if (mounted) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: const _WarehouseAppBar(title: 'Warehouse Exceptions'),
      body: FutureBuilder<List<WarehouseExceptionItem>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError && snapshot.data == null) {
            return Center(child: Text(friendlyAppError(snapshot.error!)));
          }

          final items = snapshot.data ?? const <WarehouseExceptionItem>[];
          final critical = items.where((item) => item.isCritical).length;
          final warnings = items.where((item) => item.isWarning).length;
          final other = items.length - critical - warnings;

          final filtered = items.where((item) {
            switch (_filter) {
              case 'critical':
                return item.isCritical;
              case 'warning':
                return item.isWarning;
              case 'info':
                return !item.isCritical && !item.isWarning;
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
                        Icons.warning_amber_rounded,
                        color: FarmColors.warning,
                        size: 30,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Warehouse Exception Center',
                              style: TextStyle(
                                color: FarmColors.ink,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Live operational problems across put-away, picking, packing, staging, dispatch and cycle counts. Fix the underlying workflow and the exception disappears automatically.',
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
                      child: _WarehouseExceptionMetric(
                        label: 'Critical',
                        value: '$critical',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _WarehouseExceptionMetric(
                        label: 'Warnings',
                        value: '$warnings',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _WarehouseExceptionMetric(
                        label: 'Other',
                        value: '$other',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final entry in const <MapEntry<String, String>>[
                        MapEntry('open', 'All Open'),
                        MapEntry('critical', 'Critical'),
                        MapEntry('warning', 'Warnings'),
                        MapEntry('info', 'Info'),
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
                  const FarmEmptyState(
                    icon: Icons.check_circle_outline,
                    title: 'No warehouse exceptions',
                    message:
                        'There are no live operational issues in this view right now.',
                  )
                else
                  ...filtered.map((item) {
                    final color = _severityColor(item);
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
                                  backgroundColor: color.withOpacity(0.10),
                                  child: Icon(_iconFor(item), color: color),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        style: const TextStyle(
                                          color: FarmColors.ink,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        item.detail,
                                        style: const TextStyle(
                                          color: FarmColors.mutedText,
                                          fontSize: 10.5,
                                          height: 1.35,
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
                                    item.severityLabel.toUpperCase(),
                                    style: TextStyle(
                                      color: color,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 9),
                            Text(
                              '${item.typeLabel} • ${_warehouseExceptionDateTime(item.occurredAt)}',
                              style: const TextStyle(
                                color: FarmColors.mutedText,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 9),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => _openAction(item),
                                icon: const Icon(Icons.arrow_forward_outlined),
                                label: Text(_actionLabel(item)),
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

class _WarehouseExceptionMetric extends StatelessWidget {
  final String label;
  final String value;

  const _WarehouseExceptionMetric({
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
