part of harvest_place_app;

// ================================================================
// THE HARVEST PLACE JA
// PHASE 3AJ — DELIVERY RETURNS
// ================================================================

class WarehouseReturnCandidate {
  final String dispatchId;
  final String fulfillmentId;
  final String businessName;
  final String deliveryParish;
  final DateTime? deliveredAt;
  final String recipientName;
  final String? activeReturnId;

  const WarehouseReturnCandidate({
    required this.dispatchId,
    required this.fulfillmentId,
    required this.businessName,
    required this.deliveryParish,
    required this.deliveredAt,
    required this.recipientName,
    required this.activeReturnId,
  });

  factory WarehouseReturnCandidate.fromSupabase(Map<String, dynamic> data) {
    String? nullable(dynamic value) {
      final text = value?.toString().trim() ?? '';
      return text.isEmpty ? null : text;
    }

    return WarehouseReturnCandidate(
      dispatchId: (data['dispatch_id'] ?? '').toString(),
      fulfillmentId: (data['fulfillment_id'] ?? '').toString(),
      businessName:
          (data['business_name'] ?? 'Wholesale business').toString().trim(),
      deliveryParish: (data['delivery_parish'] ?? '').toString().trim(),
      deliveredAt: DateTime.tryParse((data['delivered_at'] ?? '').toString()),
      recipientName: (data['recipient_name'] ?? '').toString().trim(),
      activeReturnId: nullable(data['active_return_id']),
    );
  }
}

class WarehouseDeliveryReturnRecord {
  final String id;
  final String dispatchId;
  final String fulfillmentId;
  final String businessName;
  final String deliveryParish;
  final DateTime? deliveredAt;
  final String status;
  final String reason;
  final String note;
  final bool financialActionRequired;
  final DateTime? reportedAt;
  final DateTime? receivedAt;
  final DateTime? closedAt;
  final int itemCount;
  final int pendingItemCount;
  final double returnQuantity;

  const WarehouseDeliveryReturnRecord({
    required this.id,
    required this.dispatchId,
    required this.fulfillmentId,
    required this.businessName,
    required this.deliveryParish,
    required this.deliveredAt,
    required this.status,
    required this.reason,
    required this.note,
    required this.financialActionRequired,
    required this.reportedAt,
    required this.receivedAt,
    required this.closedAt,
    required this.itemCount,
    required this.pendingItemCount,
    required this.returnQuantity,
  });

  factory WarehouseDeliveryReturnRecord.fromSupabase(
    Map<String, dynamic> data,
  ) {
    int integer(dynamic value) {
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    double amount(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    return WarehouseDeliveryReturnRecord(
      id: (data['return_id'] ?? '').toString(),
      dispatchId: (data['dispatch_id'] ?? '').toString(),
      fulfillmentId: (data['fulfillment_id'] ?? '').toString(),
      businessName:
          (data['business_name'] ?? 'Wholesale business').toString().trim(),
      deliveryParish: (data['delivery_parish'] ?? '').toString().trim(),
      deliveredAt: DateTime.tryParse((data['delivered_at'] ?? '').toString()),
      status: (data['status'] ?? 'reported').toString().trim().toLowerCase(),
      reason: (data['reason'] ?? '').toString().trim(),
      note: (data['note'] ?? '').toString().trim(),
      financialActionRequired: data['financial_action_required'] != false,
      reportedAt: DateTime.tryParse((data['reported_at'] ?? '').toString()),
      receivedAt: DateTime.tryParse((data['received_at'] ?? '').toString()),
      closedAt: DateTime.tryParse((data['closed_at'] ?? '').toString()),
      itemCount: integer(data['item_count']),
      pendingItemCount: integer(data['pending_item_count']),
      returnQuantity: amount(data['return_quantity']),
    );
  }

  bool get isReported => status == 'reported';
  bool get isReceived => status == 'received';
  bool get isClosed => status == 'closed';

  String get statusLabel {
    if (isReceived) return 'Received / Inspecting';
    if (isClosed) return 'Closed';
    return 'Reported';
  }
}

class WarehouseReturnableItem {
  final String fulfillmentItemId;
  final String productName;
  final String unit;
  final double packedQuantity;
  final String? sourceLotId;
  final String lotCode;
  final String farmName;
  final String farmerName;
  final double issuedFromLot;
  final double alreadyReturnedItem;
  final double alreadyReturnedLot;
  final double returnableQuantity;

  const WarehouseReturnableItem({
    required this.fulfillmentItemId,
    required this.productName,
    required this.unit,
    required this.packedQuantity,
    required this.sourceLotId,
    required this.lotCode,
    required this.farmName,
    required this.farmerName,
    required this.issuedFromLot,
    required this.alreadyReturnedItem,
    required this.alreadyReturnedLot,
    required this.returnableQuantity,
  });

  factory WarehouseReturnableItem.fromSupabase(Map<String, dynamic> data) {
    double amount(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    String? nullable(dynamic value) {
      final text = value?.toString().trim() ?? '';
      return text.isEmpty ? null : text;
    }

    return WarehouseReturnableItem(
      fulfillmentItemId: (data['fulfillment_item_id'] ?? '').toString(),
      productName: (data['product_name'] ?? 'Produce').toString().trim(),
      unit: (data['unit'] ?? 'unit').toString().trim(),
      packedQuantity: amount(data['packed_quantity']),
      sourceLotId: nullable(data['source_lot_id']),
      lotCode: (data['lot_code'] ?? '').toString().trim(),
      farmName: (data['farm_name'] ?? '').toString().trim(),
      farmerName: (data['farmer_name'] ?? '').toString().trim(),
      issuedFromLot: amount(data['issued_from_lot']),
      alreadyReturnedItem: amount(data['already_returned_item']),
      alreadyReturnedLot: amount(data['already_returned_lot']),
      returnableQuantity: amount(data['returnable_quantity']),
    );
  }

  String quantity(double value) {
    final text = value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
    return '$text $unit';
  }

  String get sourceLabel {
    if (lotCode.isEmpty) return 'Untraced source';
    final source = farmName.isNotEmpty
        ? farmName
        : farmerName.isNotEmpty
            ? farmerName
            : 'Source lot';
    return '$lotCode • $source';
  }
}

class WarehouseDeliveryReturnItemRecord {
  final String id;
  final String fulfillmentItemId;
  final String? sourceLotId;
  final String lotCode;
  final String productName;
  final String unit;
  final double returnQuantity;
  final String conditionCode;
  final String note;
  final String resolution;
  final String resolutionNote;
  final DateTime? resolvedAt;

  const WarehouseDeliveryReturnItemRecord({
    required this.id,
    required this.fulfillmentItemId,
    required this.sourceLotId,
    required this.lotCode,
    required this.productName,
    required this.unit,
    required this.returnQuantity,
    required this.conditionCode,
    required this.note,
    required this.resolution,
    required this.resolutionNote,
    required this.resolvedAt,
  });

  factory WarehouseDeliveryReturnItemRecord.fromSupabase(
    Map<String, dynamic> data,
  ) {
    double amount(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    String? nullable(dynamic value) {
      final text = value?.toString().trim() ?? '';
      return text.isEmpty ? null : text;
    }

    return WarehouseDeliveryReturnItemRecord(
      id: (data['return_item_id'] ?? '').toString(),
      fulfillmentItemId: (data['fulfillment_item_id'] ?? '').toString(),
      sourceLotId: nullable(data['source_lot_id']),
      lotCode: (data['lot_code'] ?? '').toString().trim(),
      productName: (data['product_name'] ?? 'Produce').toString().trim(),
      unit: (data['unit'] ?? 'unit').toString().trim(),
      returnQuantity: amount(data['return_quantity']),
      conditionCode:
          (data['condition_code'] ?? 'unknown').toString().trim().toLowerCase(),
      note: (data['note'] ?? '').toString().trim(),
      resolution:
          (data['resolution'] ?? 'pending').toString().trim().toLowerCase(),
      resolutionNote: (data['resolution_note'] ?? '').toString().trim(),
      resolvedAt: DateTime.tryParse((data['resolved_at'] ?? '').toString()),
    );
  }

  bool get isPending => resolution == 'pending';
  String get quantityLabel {
    final text = returnQuantity == returnQuantity.roundToDouble()
        ? returnQuantity.toInt().toString()
        : returnQuantity.toStringAsFixed(1);
    return '$text $unit';
  }

  String get resolutionLabel {
    if (resolution == 'restock') return 'Restocked';
    if (resolution == 'waste') return 'Written to Waste';
    if (resolution == 'no_stock_action') return 'No Stock Action';
    return 'Pending Inspection';
  }
}

Future<List<WarehouseReturnCandidate>> fetchWarehouseReturnCandidates() async {
  await requireAdminAccess();
  final response = await supabase.rpc('admin_list_warehouse_return_candidates');
  return (response as List)
      .map(
        (row) => WarehouseReturnCandidate.fromSupabase(
          Map<String, dynamic>.from(row as Map),
        ),
      )
      .toList();
}

Future<List<WarehouseDeliveryReturnRecord>> fetchWarehouseDeliveryReturns({
  bool includeClosed = true,
}) async {
  await requireAdminAccess();
  final response = await supabase.rpc(
    'admin_list_warehouse_delivery_returns',
    params: {'p_include_closed': includeClosed},
  );
  return (response as List)
      .map(
        (row) => WarehouseDeliveryReturnRecord.fromSupabase(
          Map<String, dynamic>.from(row as Map),
        ),
      )
      .toList();
}

Future<String> createWarehouseDeliveryReturn({
  required WarehouseReturnCandidate candidate,
  required String reason,
  String note = '',
}) async {
  await requireAdminAccess();
  final response = await supabase.rpc(
    'admin_create_warehouse_delivery_return',
    params: {
      'p_dispatch_id': candidate.dispatchId,
      'p_reason': reason.trim(),
      'p_note': note.trim(),
    },
  );
  return response.toString();
}

Future<List<WarehouseReturnableItem>> fetchWarehouseReturnableItems(
  String returnId,
) async {
  await requireAdminAccess();
  final response = await supabase.rpc(
    'admin_list_warehouse_returnable_items',
    params: {'p_return_id': returnId},
  );
  return (response as List)
      .map(
        (row) => WarehouseReturnableItem.fromSupabase(
          Map<String, dynamic>.from(row as Map),
        ),
      )
      .toList();
}

Future<List<WarehouseDeliveryReturnItemRecord>>
    fetchWarehouseDeliveryReturnItems(String returnId) async {
  await requireAdminAccess();
  final response = await supabase.rpc(
    'admin_list_warehouse_delivery_return_items',
    params: {'p_return_id': returnId},
  );
  return (response as List)
      .map(
        (row) => WarehouseDeliveryReturnItemRecord.fromSupabase(
          Map<String, dynamic>.from(row as Map),
        ),
      )
      .toList();
}

Future<void> addWarehouseDeliveryReturnItem({
  required String returnId,
  required WarehouseReturnableItem candidate,
  required double quantity,
  required String conditionCode,
  String note = '',
}) async {
  await requireAdminAccess();
  await supabase.rpc(
    'admin_add_warehouse_delivery_return_item',
    params: {
      'p_return_id': returnId,
      'p_fulfillment_item_id': candidate.fulfillmentItemId,
      'p_source_lot_id': candidate.sourceLotId,
      'p_return_quantity': quantity,
      'p_condition_code': conditionCode,
      'p_note': note.trim(),
    },
  );
}

Future<void> receiveWarehouseDeliveryReturn(
  String returnId, {
  String note = '',
}) async {
  await requireAdminAccess();
  await supabase.rpc(
    'admin_receive_warehouse_delivery_return',
    params: {'p_return_id': returnId, 'p_note': note.trim()},
  );
}

Future<void> resolveWarehouseDeliveryReturnItem({
  required WarehouseDeliveryReturnItemRecord item,
  required String resolution,
  String note = '',
}) async {
  await requireAdminAccess();
  await supabase.rpc(
    'admin_resolve_warehouse_delivery_return_item',
    params: {
      'p_return_item_id': item.id,
      'p_resolution': resolution,
      'p_resolution_note': note.trim(),
    },
  );
}

String _warehouseReturnDate(DateTime? value) {
  if (value == null) return '—';
  final local = value.toLocal();
  const months = <String>[
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${local.day} ${months[local.month - 1]} ${local.year}';
}

class WarehouseReturnsScreen extends StatefulWidget {
  const WarehouseReturnsScreen({super.key});

  @override
  State<WarehouseReturnsScreen> createState() => _WarehouseReturnsScreenState();
}

class _WarehouseReturnsScreenState extends State<WarehouseReturnsScreen> {
  late Future<List<dynamic>> _future;
  bool _showClosed = true;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<dynamic>> _load() {
    return Future.wait<dynamic>([
      fetchWarehouseReturnCandidates(),
      fetchWarehouseDeliveryReturns(includeClosed: _showClosed),
    ]);
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() => _future = next);
    await next;
  }

  Future<void> _openNewReturn(WarehouseReturnCandidate candidate) async {
    final reason = TextEditingController();
    final note = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Open return • ${candidate.businessName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: reason,
              decoration: const InputDecoration(labelText: 'Return reason *'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: note,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Initial note'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reason.text.trim().isEmpty) return;
              Navigator.of(dialogContext).pop(true);
            },
            child: const Text('Open Return'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      reason.dispose();
      note.dispose();
      return;
    }

    try {
      await createWarehouseDeliveryReturn(
        candidate: candidate,
        reason: reason.text,
        note: note.text,
      );
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Return case opened. Add the physical returned items next.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyAppError(error))),
      );
    } finally {
      reason.dispose();
      note.dispose();
    }
  }

  Color _statusColor(WarehouseDeliveryReturnRecord item) {
    if (item.isClosed) return FarmColors.success;
    if (item.isReceived) return FarmColors.warning;
    return FarmColors.danger;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: const _WarehouseAppBar(title: 'Delivery Returns'),
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
              ? const <WarehouseReturnCandidate>[]
              : data[0] as List<WarehouseReturnCandidate>;
          final returns = data.length < 2
              ? const <WarehouseDeliveryReturnRecord>[]
              : data[1] as List<WarehouseDeliveryReturnRecord>;
          final available = candidates.where((c) => c.activeReturnId == null).toList();

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
                      Icon(Icons.assignment_return_outlined, color: FarmColors.primary, size: 30),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Delivery Returns',
                              style: TextStyle(
                                color: FarmColors.ink,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Record physical produce returned after delivery, receive it back at HPJ, then restock traceable good stock or write unsuitable produce to waste. Financial credits remain separate.',
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
                      child: Text(
                        '${available.length} delivered order${available.length == 1 ? '' : 's'} available for a new return',
                        style: const TextStyle(
                          color: FarmColors.mutedText,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    FilterChip(
                      label: const Text('Show closed'),
                      selected: _showClosed,
                      onSelected: (value) {
                        setState(() {
                          _showClosed = value;
                          _future = _load();
                        });
                      },
                    ),
                  ],
                ),
                if (available.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Start a Return',
                    style: TextStyle(
                      color: FarmColors.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...available.take(10).map(
                    (candidate) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: FarmCard(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(Icons.local_shipping_outlined, color: FarmColors.primary),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    candidate.businessName,
                                    style: const TextStyle(
                                      color: FarmColors.ink,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${_warehouseReturnDate(candidate.deliveredAt)}${candidate.deliveryParish.isEmpty ? '' : ' • ${candidate.deliveryParish}'}',
                                    style: const TextStyle(
                                      color: FarmColors.mutedText,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            OutlinedButton(
                              onPressed: () => _openNewReturn(candidate),
                              child: const Text('Return'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                const Text(
                  'Return Cases',
                  style: TextStyle(
                    color: FarmColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                if (returns.isEmpty)
                  const FarmEmptyState(
                    icon: Icons.assignment_return_outlined,
                    title: 'No return cases',
                    message: 'Returned wholesale produce will be controlled here.',
                  )
                else
                  ...returns.map((item) {
                    final color = _statusColor(item);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: FarmCard(
                        padding: const EdgeInsets.all(13),
                        child: InkWell(
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => WarehouseDeliveryReturnDetailScreen(returnCase: item),
                              ),
                            );
                            await _refresh();
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.businessName,
                                      style: const TextStyle(
                                        color: FarmColors.ink,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    item.statusLabel,
                                    style: TextStyle(
                                      color: color,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Text(
                                item.reason,
                                style: const TextStyle(
                                  color: FarmColors.mutedText,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                '${item.itemCount} line${item.itemCount == 1 ? '' : 's'} • ${item.pendingItemCount} pending inspection${item.financialActionRequired ? ' • financial review required' : ''}',
                                style: const TextStyle(
                                  color: FarmColors.mutedText,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
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

class WarehouseDeliveryReturnDetailScreen extends StatefulWidget {
  final WarehouseDeliveryReturnRecord returnCase;

  const WarehouseDeliveryReturnDetailScreen({
    super.key,
    required this.returnCase,
  });

  @override
  State<WarehouseDeliveryReturnDetailScreen> createState() =>
      _WarehouseDeliveryReturnDetailScreenState();
}

class _WarehouseDeliveryReturnDetailScreenState
    extends State<WarehouseDeliveryReturnDetailScreen> {
  late Future<List<dynamic>> _future;
  late WarehouseDeliveryReturnRecord _case;

  @override
  void initState() {
    super.initState();
    _case = widget.returnCase;
    _future = _load();
  }

  Future<List<dynamic>> _load() {
    return Future.wait<dynamic>([
      fetchWarehouseReturnableItems(_case.id),
      fetchWarehouseDeliveryReturnItems(_case.id),
      fetchWarehouseDeliveryReturns(includeClosed: true),
    ]);
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() => _future = next);
    final values = await next;
    final all = values[2] as List<WarehouseDeliveryReturnRecord>;
    final matches = all.where((item) => item.id == _case.id);
    if (matches.isNotEmpty && mounted) {
      setState(() => _case = matches.first);
    }
  }

  Future<void> _addItem(List<WarehouseReturnableItem> candidates) async {
    if (candidates.isEmpty) return;
    final selected = await showModalBottomSheet<WarehouseReturnableItem>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(sheetContext).size.height * 0.72,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Select Returned Product / Source Lot',
                style: TextStyle(
                  color: FarmColors.ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              ...candidates.map(
                (candidate) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(candidate.productName),
                  subtitle: Text(
                    '${candidate.sourceLabel}\nUp to ${candidate.quantity(candidate.returnableQuantity)} returnable',
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(sheetContext).pop(candidate),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (selected == null || !mounted) return;

    final quantity = TextEditingController(
      text: selected.returnableQuantity == selected.returnableQuantity.roundToDouble()
          ? selected.returnableQuantity.toInt().toString()
          : selected.returnableQuantity.toStringAsFixed(1),
    );
    final note = TextEditingController();
    String condition = 'unknown';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Return ${selected.productName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: quantity,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: 'Quantity (${selected.unit})'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: condition,
                decoration: const InputDecoration(labelText: 'Condition'),
                items: const [
                  DropdownMenuItem(value: 'unknown', child: Text('Unknown / inspect later')),
                  DropdownMenuItem(value: 'good', child: Text('Good')),
                  DropdownMenuItem(value: 'damaged', child: Text('Damaged')),
                  DropdownMenuItem(value: 'spoiled', child: Text('Spoiled')),
                  DropdownMenuItem(value: 'rejected', child: Text('Rejected by customer')),
                ],
                onChanged: (value) => setDialogState(() => condition = value ?? 'unknown'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: note,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Item note'),
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
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );

    final amount = double.tryParse(quantity.text.trim().replaceAll(',', '')) ?? 0.0;
    if (confirmed != true) {
      quantity.dispose();
      note.dispose();
      return;
    }

    try {
      await addWarehouseDeliveryReturnItem(
        returnId: _case.id,
        candidate: selected,
        quantity: amount,
        conditionCode: condition,
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

  Future<void> _receive() async {
    final note = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Receive returned produce?'),
        content: TextField(
          controller: note,
          maxLines: 2,
          decoration: const InputDecoration(labelText: 'Receiving / inspection note'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Mark Received'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      note.dispose();
      return;
    }
    try {
      await receiveWarehouseDeliveryReturn(_case.id, note: note.text);
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

  Future<void> _resolve(
    WarehouseDeliveryReturnItemRecord item,
    String resolution,
  ) async {
    final note = TextEditingController();
    final label = resolution == 'restock'
        ? 'Restock'
        : resolution == 'waste'
            ? 'Write to Waste'
            : 'No Stock Action';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('$label ${item.productName}?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if ((resolution == 'restock' || resolution == 'waste') &&
                item.sourceLotId == null)
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Text('This line has no traceable source lot. Use No Stock Action.'),
              ),
            TextField(
              controller: note,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Resolution note'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: (resolution == 'restock' || resolution == 'waste') &&
                    item.sourceLotId == null
                ? null
                : () => Navigator.of(dialogContext).pop(true),
            child: Text(label),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      note.dispose();
      return;
    }
    try {
      await resolveWarehouseDeliveryReturnItem(
        item: item,
        resolution: resolution,
        note: note.text,
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
      appBar: _WarehouseAppBar(title: 'Return • ${_case.businessName}'),
      body: FutureBuilder<List<dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError && snapshot.data == null) {
            return Center(child: Text(friendlyAppError(snapshot.error!)));
          }
          final data = snapshot.data ?? const <dynamic>[];
          final candidates = data.isEmpty
              ? const <WarehouseReturnableItem>[]
              : data[0] as List<WarehouseReturnableItem>;
          final items = data.length < 2
              ? const <WarehouseDeliveryReturnItemRecord>[]
              : data[1] as List<WarehouseDeliveryReturnItemRecord>;

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 110),
              children: [
                FarmCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _case.reason,
                        style: const TextStyle(
                          color: FarmColors.ink,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${_case.statusLabel} • Reported ${_warehouseReturnDate(_case.reportedAt)}',
                        style: const TextStyle(
                          color: FarmColors.mutedText,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (_case.note.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(_case.note),
                      ],
                      if (_case.financialActionRequired) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'Financial review required: any credit/refund is handled separately from the physical stock return.',
                          style: TextStyle(
                            color: FarmColors.warning,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (_case.isReported)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: candidates.isEmpty ? null : () => _addItem(candidates),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Add Returned Item'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: items.isEmpty ? null : _receive,
                          icon: const Icon(Icons.inventory_outlined),
                          label: const Text('Receive Return'),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 14),
                const Text(
                  'Returned Items',
                  style: TextStyle(
                    color: FarmColors.ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                if (items.isEmpty)
                  const FarmEmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'No returned items recorded',
                    message: 'Add each physical returned line before receiving the return.',
                  )
                else
                  ...items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: FarmCard(
                        padding: const EdgeInsets.all(13),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.productName,
                                    style: const TextStyle(
                                      color: FarmColors.ink,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                Text(
                                  item.quantityLabel,
                                  style: const TextStyle(
                                    color: FarmColors.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '${item.lotCode.isEmpty ? 'No source lot' : 'Lot ${item.lotCode}'} • ${item.conditionCode.replaceAll('_', ' ')} • ${item.resolutionLabel}',
                              style: const TextStyle(
                                color: FarmColors.mutedText,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (item.note.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(item.note),
                            ],
                            if (item.resolutionNote.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text('Resolution: ${item.resolutionNote}'),
                            ],
                            if (_case.isReceived && item.isPending) ...[
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 7,
                                runSpacing: 7,
                                children: [
                                  OutlinedButton(
                                    onPressed: () => _resolve(item, 'restock'),
                                    child: const Text('Restock'),
                                  ),
                                  OutlinedButton(
                                    onPressed: () => _resolve(item, 'waste'),
                                    child: const Text('Waste'),
                                  ),
                                  OutlinedButton(
                                    onPressed: () => _resolve(item, 'no_stock_action'),
                                    child: const Text('No Stock Action'),
                                  ),
                                ],
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
