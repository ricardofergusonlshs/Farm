part of harvest_place_app;

// ================================================================
// THE HARVEST PLACE JA
// PHASE 3AA — FEFO WAREHOUSE PICK QUEUE
// ================================================================

class WarehousePickQueueRow {
  final String reservationId;
  final String fulfillmentId;
  final String fulfillmentItemId;
  final String requestId;
  final String fulfillmentStatus;
  final String itemStatus;
  final String lotId;
  final String lotCode;
  final String? storageLocationId;
  final String storageLocationCode;
  final String storageLocationName;
  final String productName;
  final String unit;
  final double reservedQuantity;
  final double issuedQuantity;
  final double releasedQuantity;
  final double remainingQuantity;
  final double pickedQuantity;
  final String pickStatus;
  final String pickNote;
  final DateTime? pickedAt;
  final DateTime? bestBeforeDate;
  final DateTime? receivedAt;

  const WarehousePickQueueRow({
    required this.reservationId,
    required this.fulfillmentId,
    required this.fulfillmentItemId,
    required this.requestId,
    required this.fulfillmentStatus,
    required this.itemStatus,
    required this.lotId,
    required this.lotCode,
    required this.storageLocationId,
    required this.storageLocationCode,
    required this.storageLocationName,
    required this.productName,
    required this.unit,
    required this.reservedQuantity,
    required this.issuedQuantity,
    required this.releasedQuantity,
    required this.remainingQuantity,
    required this.pickedQuantity,
    required this.pickStatus,
    required this.pickNote,
    this.pickedAt,
    this.bestBeforeDate,
    this.receivedAt,
  });

  factory WarehousePickQueueRow.fromSupabase(Map<String, dynamic> data) {
    double amount(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0.0;
    }

    String? nullable(dynamic value) {
      final clean = value?.toString().trim() ?? '';
      return clean.isEmpty ? null : clean;
    }

    return WarehousePickQueueRow(
      reservationId: (data['reservation_id'] ?? '').toString(),
      fulfillmentId: (data['fulfillment_id'] ?? '').toString(),
      fulfillmentItemId: (data['fulfillment_item_id'] ?? '').toString(),
      requestId: (data['request_id'] ?? '').toString(),
      fulfillmentStatus:
          (data['fulfillment_status'] ?? '').toString().trim().toLowerCase(),
      itemStatus: (data['item_status'] ?? '').toString().trim().toLowerCase(),
      lotId: (data['lot_id'] ?? '').toString(),
      lotCode: (data['lot_code'] ?? '').toString().trim(),
      storageLocationId: nullable(data['storage_location_id']),
      storageLocationCode:
          (data['storage_location_code'] ?? '').toString().trim(),
      storageLocationName:
          (data['storage_location_name'] ?? '').toString().trim(),
      productName: (data['product_name'] ?? 'Produce').toString().trim(),
      unit: (data['unit'] ?? 'unit').toString().trim(),
      reservedQuantity: amount(data['reserved_quantity']),
      issuedQuantity: amount(data['issued_quantity']),
      releasedQuantity: amount(data['released_quantity']),
      remainingQuantity: amount(data['remaining_quantity']),
      pickedQuantity: amount(data['picked_quantity']),
      pickStatus:
          (data['pick_status'] ?? 'pending').toString().trim().toLowerCase(),
      pickNote: (data['pick_note'] ?? '').toString().trim(),
      pickedAt: DateTime.tryParse((data['picked_at'] ?? '').toString()),
      bestBeforeDate:
          DateTime.tryParse((data['best_before_date'] ?? '').toString()),
      receivedAt: DateTime.tryParse((data['received_at'] ?? '').toString()),
    );
  }

  bool get isPending => pickStatus == 'pending';
  bool get isPartial => pickStatus == 'partial';
  bool get isPicked => pickStatus == 'picked';
  bool get isUnassigned => storageLocationId == null;

  String get locationLabel {
    if (storageLocationCode.isEmpty && storageLocationName.isEmpty) {
      return 'UNASSIGNED';
    }
    if (storageLocationCode.isEmpty) return storageLocationName;
    if (storageLocationName.isEmpty) return storageLocationCode;
    return '$storageLocationCode • $storageLocationName';
  }

  String get fulfillmentShortId {
    if (fulfillmentId.length <= 8) return fulfillmentId.toUpperCase();
    return fulfillmentId.substring(0, 8).toUpperCase();
  }

  String quantity(double value) {
    final text = value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
    return '$text $unit';
  }

  String get pickStatusLabel {
    switch (pickStatus) {
      case 'picked':
        return 'PICKED';
      case 'partial':
        return 'PARTIAL';
      default:
        return 'TO PICK';
    }
  }
}

Future<List<WarehousePickQueueRow>> fetchWarehousePickQueue({
  String? fulfillmentId,
}) async {
  await requireAdminAccess();
  final response = await supabase.rpc(
    'admin_list_warehouse_pick_queue',
    params: {
      'p_fulfillment_id': fulfillmentId,
    },
  );

  return (response as List)
      .map(
        (row) => WarehousePickQueueRow.fromSupabase(
          Map<String, dynamic>.from(row),
        ),
      )
      .toList();
}

Future<void> markWarehouseReservationPicked({
  required WarehousePickQueueRow row,
  required double pickedQuantity,
  String note = '',
}) async {
  await requireAdminAccess();
  await supabase.rpc(
    'admin_mark_warehouse_reservation_picked',
    params: {
      'p_reservation_id': row.reservationId,
      'p_picked_quantity': pickedQuantity,
      'p_note': note.trim(),
    },
  );
}

class WarehousePickingScreen extends StatefulWidget {
  const WarehousePickingScreen({super.key});

  @override
  State<WarehousePickingScreen> createState() => _WarehousePickingScreenState();
}

class _WarehousePickingScreenState extends State<WarehousePickingScreen> {
  late Future<List<WarehousePickQueueRow>> _future;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _future = fetchWarehousePickQueue();
  }

  Future<void> _refresh() async {
    final next = fetchWarehousePickQueue();
    setState(() => _future = next);
    await next;
  }

  Future<void> _savePick(
    WarehousePickQueueRow row,
    double quantity,
    String note,
  ) async {
    try {
      await markWarehouseReservationPicked(
        row: row,
        pickedQuantity: quantity,
        note: note,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            quantity <= 0
                ? 'Pick confirmation reset.'
                : quantity + 0.000001 >= row.remainingQuantity
                    ? 'Lot pick confirmed.'
                    : 'Partial pick recorded.',
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

  Future<void> _recordPartialPick(WarehousePickQueueRow row) async {
    final quantity = TextEditingController(
      text: row.pickedQuantity > 0
          ? row.pickedQuantity.toStringAsFixed(
              row.pickedQuantity == row.pickedQuantity.roundToDouble() ? 0 : 1,
            )
          : '',
    );
    final note = TextEditingController(text: row.pickNote);

    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('Pick ${row.productName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lot ${row.lotCode} • ${row.locationLabel}\nReservation: ${row.quantity(row.remainingQuantity)}',
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
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Picked quantity (${row.unit})',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: note,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Pick note (optional)',
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
              child: const Text('Save Pick'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      final double amount =
          double.tryParse(quantity.text.trim().replaceAll(',', '')) ?? -1.0;
      if (amount < 0 || amount > row.remainingQuantity + 0.000001) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Enter a quantity from 0 to ${row.quantity(row.remainingQuantity)}.',
            ),
          ),
        );
        return;
      }

      await _savePick(row, amount, note.text);
    } finally {
      quantity.dispose();
      note.dispose();
    }
  }

  Color _statusColor(WarehousePickQueueRow row) {
    if (row.isUnassigned) return FarmColors.danger;
    if (row.isPicked) return FarmColors.success;
    if (row.isPartial) return FarmColors.warning;
    return FarmColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: const _WarehouseAppBar(title: 'Warehouse Pick Queue'),
      body: FutureBuilder<List<WarehousePickQueueRow>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError && snapshot.data == null) {
            return Center(child: Text(friendlyAppError(snapshot.error!)));
          }

          final rows = snapshot.data ?? const <WarehousePickQueueRow>[];
          final pending = rows.where((row) => row.isPending).length;
          final partial = rows.where((row) => row.isPartial).length;
          final picked = rows.where((row) => row.isPicked).length;
          final unassigned = rows.where((row) => row.isUnassigned).length;
          final fulfillmentCount =
              rows.map((row) => row.fulfillmentId).toSet().length;

          final filtered = rows.where((row) {
            switch (_filter) {
              case 'pending':
                return row.isPending;
              case 'partial':
                return row.isPartial;
              case 'picked':
                return row.isPicked;
              case 'unassigned':
                return row.isUnassigned;
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
                        Icons.playlist_add_check_circle_outlined,
                        color: FarmColors.primary,
                        size: 30,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'FEFO Pick Queue',
                              style: TextStyle(
                                color: FarmColors.ink,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Existing wholesale lot reservations are ordered by physical location and FEFO. Confirming a pick does not issue stock; the existing Packing workflow remains the inventory issue point.',
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
                      _PickMetric(label: 'To Pick', value: '$pending'),
                      const SizedBox(width: 8),
                      _PickMetric(label: 'Partial', value: '$partial'),
                      const SizedBox(width: 8),
                      _PickMetric(label: 'Picked', value: '$picked'),
                      const SizedBox(width: 8),
                      _PickMetric(label: 'Unassigned', value: '$unassigned'),
                      const SizedBox(width: 8),
                      _PickMetric(
                        label: 'Fulfilments',
                        value: '$fulfillmentCount',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final option in const <MapEntry<String, String>>[
                        MapEntry('all', 'All'),
                        MapEntry('pending', 'To Pick'),
                        MapEntry('partial', 'Partial'),
                        MapEntry('picked', 'Picked'),
                        MapEntry('unassigned', 'Unassigned'),
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
                    icon: Icons.playlist_add_check_circle_outlined,
                    title: 'Nothing to pick in this view',
                    message:
                        'Use Stock Ready on a wholesale fulfilment to reserve warehouse lots. Those reservations will appear here.',
                  )
                else
                  ...filtered.map((row) {
                    final color = _statusColor(row);
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
                                    row.productName,
                                    style: const TextStyle(
                                      color: FarmColors.ink,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                    ),
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
                                    row.isUnassigned
                                        ? 'NO LOCATION'
                                        : row.pickStatusLabel,
                                    style: TextStyle(
                                      color: color,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '${row.locationLabel} • Lot ${row.lotCode}',
                              style: TextStyle(
                                color: row.isUnassigned
                                    ? FarmColors.danger
                                    : FarmColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Fulfilment #${row.fulfillmentShortId} • Best before ${_warehouseInventoryDate(row.bestBeforeDate)}',
                              style: const TextStyle(
                                color: FarmColors.mutedText,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 7,
                              runSpacing: 7,
                              children: [
                                _PickValue(
                                  label: 'Reserved now',
                                  value: row.quantity(row.remainingQuantity),
                                ),
                                _PickValue(
                                  label: 'Picked',
                                  value: row.quantity(row.pickedQuantity),
                                ),
                                _PickValue(
                                  label: 'Original reserve',
                                  value: row.quantity(row.reservedQuantity),
                                ),
                              ],
                            ),
                            if (row.pickNote.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                row.pickNote,
                                style: const TextStyle(
                                  color: FarmColors.mutedText,
                                  fontSize: 10.5,
                                  height: 1.35,
                                ),
                              ),
                            ],
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 7,
                              runSpacing: 7,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: row.isUnassigned
                                      ? null
                                      : () => _savePick(
                                            row,
                                            row.remainingQuantity,
                                            row.pickNote,
                                          ),
                                  icon:
                                      const Icon(Icons.check_rounded, size: 17),
                                  label: const Text('Mark Picked'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: row.isUnassigned
                                      ? null
                                      : () => _recordPartialPick(row),
                                  icon:
                                      const Icon(Icons.edit_outlined, size: 17),
                                  label: const Text('Partial / Edit'),
                                ),
                                if (!row.isPending)
                                  TextButton(
                                    onPressed: () => _savePick(row, 0.0, ''),
                                    child: const Text('Reset'),
                                  ),
                              ],
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

class _PickMetric extends StatelessWidget {
  final String label;
  final String value;

  const _PickMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
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

class _PickValue extends StatelessWidget {
  final String label;
  final String value;

  const _PickValue({required this.label, required this.value});

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
