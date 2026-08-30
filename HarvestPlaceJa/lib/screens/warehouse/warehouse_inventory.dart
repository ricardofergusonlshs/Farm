part of harvest_place_app;

// ================================================================
// THE HARVEST PLACE JA
// PHASE 3Y + 3Z — WAREHOUSE INVENTORY, LOT TRACKING & PUT-AWAY
// ================================================================

class WarehouseInventoryLot {
  final String id;
  final String receivingBatchId;
  final String lotCode;
  final String productName;
  final String unit;
  final String? farmerId;
  final String farmName;
  final String farmerName;
  final String parish;
  final String? storageLocationId;
  final String storageLocationCode;
  final String storageLocationName;
  final double receivedQuantity;
  final double quantityOnHand;
  final double quantityReserved;
  final double quantityWasted;
  final String status;
  final DateTime? receivedAt;
  final DateTime? bestBeforeDate;
  final String notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const WarehouseInventoryLot({
    required this.id,
    required this.receivingBatchId,
    required this.lotCode,
    required this.productName,
    required this.unit,
    required this.farmerId,
    required this.farmName,
    required this.farmerName,
    required this.parish,
    required this.storageLocationId,
    required this.storageLocationCode,
    required this.storageLocationName,
    required this.receivedQuantity,
    required this.quantityOnHand,
    required this.quantityReserved,
    required this.quantityWasted,
    required this.status,
    this.receivedAt,
    this.bestBeforeDate,
    required this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory WarehouseInventoryLot.fromSupabase(Map<String, dynamic> data) {
    double amount(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    String? nullable(dynamic value) {
      final clean = value?.toString().trim() ?? '';
      return clean.isEmpty ? null : clean;
    }

    final rawLocation = data['warehouse_storage_locations'];
    final location = rawLocation is Map
        ? Map<String, dynamic>.from(rawLocation)
        : const <String, dynamic>{};

    return WarehouseInventoryLot(
      id: (data['id'] ?? '').toString(),
      receivingBatchId: (data['receiving_batch_id'] ?? '').toString(),
      lotCode: (data['lot_code'] ?? '').toString().trim(),
      productName: (data['product_name'] ?? 'Produce').toString().trim(),
      unit: (data['unit'] ?? 'unit').toString().trim(),
      farmerId: nullable(data['farmer_id']),
      farmName: (data['farm_name'] ?? '').toString().trim(),
      farmerName: (data['farmer_name'] ?? '').toString().trim(),
      parish: (data['parish'] ?? '').toString().trim(),
      storageLocationId: nullable(data['storage_location_id']),
      storageLocationCode: (location['code'] ?? '').toString().trim(),
      storageLocationName: (location['name'] ?? '').toString().trim(),
      receivedQuantity: amount(data['received_quantity']),
      quantityOnHand: amount(data['quantity_on_hand']),
      quantityReserved: amount(data['quantity_reserved']),
      quantityWasted: amount(data['quantity_wasted']),
      status: (data['status'] ?? 'active').toString().trim().toLowerCase(),
      receivedAt: DateTime.tryParse((data['received_at'] ?? '').toString()),
      bestBeforeDate:
          DateTime.tryParse((data['best_before_date'] ?? '').toString()),
      notes: (data['notes'] ?? '').toString().trim(),
      createdAt: DateTime.tryParse((data['created_at'] ?? '').toString()),
      updatedAt: DateTime.tryParse((data['updated_at'] ?? '').toString()),
    );
  }

  double get availableQuantity {
    final value = quantityOnHand - quantityReserved;
    return value < 0 ? 0 : value;
  }

  bool get isActive => status == 'active';
  bool get isDepleted => status == 'depleted';
  bool get isQuarantined => status == 'quarantined';
  bool get isClosed => status == 'closed';
  bool get isUnassigned => storageLocationId == null;

  String get locationLabel {
    if (storageLocationCode.isEmpty && storageLocationName.isEmpty) {
      return 'Unassigned';
    }
    if (storageLocationCode.isEmpty) return storageLocationName;
    if (storageLocationName.isEmpty) return storageLocationCode;
    return '$storageLocationCode • $storageLocationName';
  }

  int? get daysToBestBefore {
    final date = bestBeforeDate;
    if (date == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    return target.difference(today).inDays;
  }

  bool get isExpired =>
      quantityOnHand > 0 && daysToBestBefore != null && daysToBestBefore! < 0;

  bool get isExpiringSoon =>
      quantityOnHand > 0 &&
      daysToBestBefore != null &&
      daysToBestBefore! >= 0 &&
      daysToBestBefore! <= 3;

  String get statusLabel {
    switch (status) {
      case 'depleted':
        return 'Depleted';
      case 'quarantined':
        return 'Quarantined';
      case 'closed':
        return 'Closed';
      default:
        return 'Active';
    }
  }

  String quantity(double value) {
    final text = value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
    return '$text $unit';
  }
}

class WarehouseStorageLocation {
  final String id;
  final String code;
  final String name;
  final String zone;
  final bool isActive;
  final String notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const WarehouseStorageLocation({
    required this.id,
    required this.code,
    required this.name,
    required this.zone,
    required this.isActive,
    required this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory WarehouseStorageLocation.fromSupabase(Map<String, dynamic> data) {
    return WarehouseStorageLocation(
      id: (data['id'] ?? '').toString(),
      code: (data['code'] ?? '').toString().trim(),
      name: (data['name'] ?? '').toString().trim(),
      zone: (data['zone'] ?? '').toString().trim(),
      isActive: data['is_active'] == true,
      notes: (data['notes'] ?? '').toString().trim(),
      createdAt: DateTime.tryParse((data['created_at'] ?? '').toString()),
      updatedAt: DateTime.tryParse((data['updated_at'] ?? '').toString()),
    );
  }

  String get label {
    if (name.isEmpty) return code;
    return '$code • $name';
  }
}

class WarehouseInventoryMovement {
  final String id;
  final String lotId;
  final String movementType;
  final double onHandDelta;
  final double reservedDelta;
  final double wasteDelta;
  final String referenceType;
  final String referenceId;
  final String note;
  final DateTime? createdAt;

  const WarehouseInventoryMovement({
    required this.id,
    required this.lotId,
    required this.movementType,
    required this.onHandDelta,
    required this.reservedDelta,
    required this.wasteDelta,
    required this.referenceType,
    required this.referenceId,
    required this.note,
    this.createdAt,
  });

  factory WarehouseInventoryMovement.fromSupabase(Map<String, dynamic> data) {
    double amount(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    return WarehouseInventoryMovement(
      id: (data['id'] ?? '').toString(),
      lotId: (data['lot_id'] ?? '').toString(),
      movementType: (data['movement_type'] ?? 'adjustment')
          .toString()
          .trim()
          .toLowerCase(),
      onHandDelta: amount(data['on_hand_delta']),
      reservedDelta: amount(data['reserved_delta']),
      wasteDelta: amount(data['waste_delta']),
      referenceType: (data['reference_type'] ?? '').toString().trim(),
      referenceId: (data['reference_id'] ?? '').toString().trim(),
      note: (data['note'] ?? '').toString().trim(),
      createdAt: DateTime.tryParse((data['created_at'] ?? '').toString()),
    );
  }
}

const String _warehouseLotSelectFields =
    'id, receiving_batch_id, lot_code, product_name, unit, farmer_id, farm_name, '
    'farmer_name, parish, storage_location_id, received_quantity, quantity_on_hand, '
    'quantity_reserved, quantity_wasted, status, received_at, best_before_date, notes, '
    'created_at, updated_at, warehouse_storage_locations(id, code, name)';

const String _warehouseMovementSelectFields =
    'id, lot_id, movement_type, on_hand_delta, reserved_delta, waste_delta, '
    'reference_type, reference_id, note, created_at';

const String _warehouseStorageLocationSelectFields =
    'id, code, name, zone, is_active, notes, created_at, updated_at';

Future<List<WarehouseInventoryLot>> fetchWarehouseInventoryLots({
  bool includeClosed = false,
}) async {
  await requireAdminAccess();
  dynamic query = supabase
      .from('warehouse_inventory_lots')
      .select(_warehouseLotSelectFields);
  if (!includeClosed) {
    query = query.neq('status', 'closed');
  }
  final response =
      await query.order('received_at', ascending: false).limit(500);
  return (response as List)
      .map(
        (row) => WarehouseInventoryLot.fromSupabase(
          Map<String, dynamic>.from(row),
        ),
      )
      .toList();
}

Future<List<WarehouseStorageLocation>> fetchWarehouseStorageLocations({
  bool includeInactive = true,
}) async {
  await requireAdminAccess();
  dynamic query = supabase
      .from('warehouse_storage_locations')
      .select(_warehouseStorageLocationSelectFields);
  if (!includeInactive) {
    query = query.eq('is_active', true);
  }
  final response = await query.order('code');
  return (response as List)
      .map(
        (row) => WarehouseStorageLocation.fromSupabase(
          Map<String, dynamic>.from(row),
        ),
      )
      .toList();
}

Future<void> createWarehouseStorageLocation({
  required String code,
  required String name,
  String zone = '',
  String notes = '',
}) async {
  await requireAdminAccess();
  await supabase.rpc(
    'admin_create_warehouse_storage_location',
    params: {
      'p_code': code.trim(),
      'p_name': name.trim(),
      'p_zone': zone.trim(),
      'p_notes': notes.trim(),
    },
  );
}

Future<void> updateWarehouseStorageLocation({
  required WarehouseStorageLocation location,
  required String name,
  required String zone,
  required bool isActive,
  required String notes,
}) async {
  await requireAdminAccess();
  await supabase.rpc(
    'admin_update_warehouse_storage_location',
    params: {
      'p_location_id': location.id,
      'p_name': name.trim(),
      'p_zone': zone.trim(),
      'p_is_active': isActive,
      'p_notes': notes.trim(),
    },
  );
}

Future<void> assignWarehouseLotLocation({
  required WarehouseInventoryLot lot,
  String? locationId,
  String note = '',
}) async {
  await requireAdminAccess();
  await supabase.rpc(
    'admin_assign_warehouse_lot_location',
    params: {
      'p_lot_id': lot.id,
      'p_location_id': locationId,
      'p_note': note.trim(),
    },
  );
}

Future<List<WarehouseInventoryMovement>> fetchWarehouseInventoryMovements(
  String lotId,
) async {
  await requireAdminAccess();
  final response = await supabase
      .from('warehouse_inventory_movements')
      .select(_warehouseMovementSelectFields)
      .eq('lot_id', lotId)
      .order('created_at', ascending: false)
      .limit(100);
  return (response as List)
      .map(
        (row) => WarehouseInventoryMovement.fromSupabase(
          Map<String, dynamic>.from(row),
        ),
      )
      .toList();
}

Future<void> adjustWarehouseInventoryLot({
  required WarehouseInventoryLot lot,
  required String action,
  double quantity = 0,
  String note = '',
}) async {
  await requireAdminAccess();
  await supabase.rpc(
    'admin_adjust_warehouse_inventory_lot',
    params: {
      'p_lot_id': lot.id,
      'p_action': action.trim().toLowerCase(),
      'p_quantity': quantity,
      'p_note': note.trim(),
    },
  );
}

Future<void> updateWarehouseLotBestBefore({
  required WarehouseInventoryLot lot,
  DateTime? bestBeforeDate,
  String? notes,
}) async {
  await requireAdminAccess();
  await supabase.rpc(
    'admin_update_warehouse_lot_details',
    params: {
      'p_lot_id': lot.id,
      'p_best_before_date': bestBeforeDate == null
          ? null
          : '${bestBeforeDate.year.toString().padLeft(4, '0')}-'
              '${bestBeforeDate.month.toString().padLeft(2, '0')}-'
              '${bestBeforeDate.day.toString().padLeft(2, '0')}',
      'p_notes': notes?.trim(),
    },
  );
}

String _warehouseInventoryDate(DateTime? date) {
  if (date == null) return '—';
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
  final value = date.toLocal();
  return '${value.day} ${months[value.month - 1]} ${value.year}';
}

class WarehouseInventoryScreen extends StatefulWidget {
  const WarehouseInventoryScreen({super.key});

  @override
  State<WarehouseInventoryScreen> createState() =>
      _WarehouseInventoryScreenState();
}

class _WarehouseInventoryScreenState extends State<WarehouseInventoryScreen> {
  late Future<List<WarehouseInventoryLot>> _future;
  String _filter = 'available';

  @override
  void initState() {
    super.initState();
    _future = fetchWarehouseInventoryLots();
  }

  Future<void> _refresh() async {
    final next = fetchWarehouseInventoryLots(includeClosed: _filter == 'all');
    setState(() => _future = next);
    await next;
  }

  Future<void> _inventoryAction(
    WarehouseInventoryLot lot,
    String action,
    String title,
  ) async {
    final needsQuantity =
        !<String>{'quarantine', 'activate', 'close'}.contains(action);
    final quantity = TextEditingController();
    final note = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (needsQuantity)
              TextField(
                controller: quantity,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Quantity (${lot.unit})',
                ),
              ),
            if (needsQuantity) const SizedBox(height: 10),
            TextField(
              controller: note,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Reason / note',
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
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      quantity.dispose();
      note.dispose();
      return;
    }

    final double amount = needsQuantity
        ? double.tryParse(quantity.text.trim().replaceAll(',', '')) ?? 0.0
        : 0.0;

    try {
      await adjustWarehouseInventoryLot(
        lot: lot,
        action: action,
        quantity: amount,
        note: note.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$title completed.')),
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

  Future<void> _editLot(WarehouseInventoryLot lot) async {
    DateTime? selectedDate = lot.bestBeforeDate;
    final notes = TextEditingController(text: lot.notes);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text('Lot ${lot.lotCode}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Best-before date'),
                  subtitle: Text(_warehouseInventoryDate(selectedDate)),
                  trailing: const Icon(Icons.calendar_month_outlined),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate ?? DateTime.now(),
                      firstDate:
                          DateTime.now().subtract(const Duration(days: 30)),
                      lastDate: DateTime.now().add(const Duration(days: 730)),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedDate = picked);
                    }
                  },
                ),
                TextField(
                  controller: notes,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Lot notes'),
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
        );
      },
    );

    if (confirmed != true) {
      notes.dispose();
      return;
    }

    try {
      await updateWarehouseLotBestBefore(
        lot: lot,
        bestBeforeDate: selectedDate,
        notes: notes.text,
      );
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyAppError(error))),
      );
    } finally {
      notes.dispose();
    }
  }

  Future<void> _assignLocation(WarehouseInventoryLot lot) async {
    try {
      final allLocations = await fetchWarehouseStorageLocations();
      if (!mounted) return;

      final locations = allLocations.where((item) => item.isActive).toList();
      String selectedLocationId = locations.any(
        (item) => item.id == lot.storageLocationId,
      )
          ? lot.storageLocationId!
          : '__unassigned__';
      final note = TextEditingController();

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
              title: Text('Put Away • ${lot.lotCode}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedLocationId,
                    decoration: const InputDecoration(
                      labelText: 'Storage location',
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: '__unassigned__',
                        child: Text('Unassigned'),
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
                      setDialogState(() => selectedLocationId = value);
                    },
                  ),
                  if (locations.isEmpty) ...[
                    const SizedBox(height: 10),
                    const Text(
                      'No active storage locations exist yet. Create one from Warehouse Operations → Storage Locations.',
                      style: TextStyle(
                        color: FarmColors.mutedText,
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  TextField(
                    controller: note,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Put-away note (optional)',
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
                  child: const Text('Save Location'),
                ),
              ],
            ),
          );
        },
      );

      if (confirmed != true) {
        note.dispose();
        return;
      }

      await assignWarehouseLotLocation(
        lot: lot,
        locationId:
            selectedLocationId == '__unassigned__' ? null : selectedLocationId,
        note: note.text,
      );
      note.dispose();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Warehouse location updated.')),
      );
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyAppError(error))),
      );
    }
  }

  Future<void> _showHistory(WarehouseInventoryLot lot) async {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(sheetContext).size.height * 0.72,
            child: FutureBuilder<List<WarehouseInventoryMovement>>(
              future: fetchWarehouseInventoryMovements(lot.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final movements =
                    snapshot.data ?? const <WarehouseInventoryMovement>[];
                return ListView(
                  padding: const EdgeInsets.all(18),
                  children: [
                    Text(
                      'Lot ${lot.lotCode} Movement History',
                      style: const TextStyle(
                        color: FarmColors.ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (movements.isEmpty)
                      const Text('No movement history yet.')
                    else
                      ...movements.map(
                        (movement) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const CircleAvatar(
                            backgroundColor: FarmColors.primarySoft,
                            child: Icon(
                              Icons.swap_vert_rounded,
                              color: FarmColors.primary,
                            ),
                          ),
                          title: Text(
                            movement.movementType
                                .replaceAll('_', ' ')
                                .toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          subtitle: Text(
                            'On hand ${movement.onHandDelta >= 0 ? '+' : ''}${movement.onHandDelta.toStringAsFixed(1)} • Reserved ${movement.reservedDelta >= 0 ? '+' : ''}${movement.reservedDelta.toStringAsFixed(1)}${movement.note.isEmpty ? '' : '\n${movement.note}'}',
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Color _statusColor(WarehouseInventoryLot lot) {
    if (lot.isExpired || lot.isQuarantined) return FarmColors.danger;
    if (lot.isExpiringSoon) return FarmColors.warning;
    if (lot.isDepleted || lot.isClosed) return FarmColors.mutedText;
    return FarmColors.success;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: const _WarehouseAppBar(title: 'Warehouse Inventory'),
      body: FutureBuilder<List<WarehouseInventoryLot>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError && snapshot.data == null) {
            return Center(child: Text(friendlyAppError(snapshot.error!)));
          }

          final lots = snapshot.data ?? const <WarehouseInventoryLot>[];
          final filtered = lots.where((lot) {
            switch (_filter) {
              case 'available':
                return lot.isActive && lot.availableQuantity > 0;
              case 'reserved':
                return lot.quantityReserved > 0;
              case 'quarantine':
                return lot.isQuarantined;
              case 'unassigned':
                return lot.quantityOnHand > 0 && lot.isUnassigned;
              case 'expiring':
                return lot.isExpiringSoon;
              case 'expired':
                return lot.isExpired;
              case 'all':
                return true;
              default:
                return true;
            }
          }).toList();

          final activeLots = lots.where((lot) => lot.isActive).length;
          final reservedLots =
              lots.where((lot) => lot.quantityReserved > 0).length;
          final quarantined = lots.where((lot) => lot.isQuarantined).length;
          final unassigned = lots
              .where((lot) => lot.quantityOnHand > 0 && lot.isUnassigned)
              .length;
          final expiring = lots.where((lot) => lot.isExpiringSoon).length;

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
                      Icon(
                        Icons.inventory_2_outlined,
                        color: FarmColors.primary,
                        size: 30,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Inventory & Lot Tracking',
                              style: TextStyle(
                                color: FarmColors.ink,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Completed receiving batches become traceable lots. Put each lot into a physical storage location, monitor expiry, and keep every reservation or stock adjustment in the movement ledger.',
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
                      child: _InventoryMetric(
                          label: 'Active Lots', value: '$activeLots'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _InventoryMetric(
                          label: 'Reserved', value: '$reservedLots'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _InventoryMetric(
                          label: 'Quarantine', value: '$quarantined'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _InventoryMetric(
                          label: 'Unassigned', value: '$unassigned'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _InventoryMetric(
                          label: 'Expiring ≤3d', value: '$expiring'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                const WarehouseStorageLocationsScreen(),
                          ),
                        ),
                        icon: const Icon(Icons.grid_view_outlined, size: 17),
                        label: const Text('Locations'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Available'),
                        selected: _filter == 'available',
                        onSelected: (_) {
                          setState(() {
                            _filter = 'available';
                            _future = fetchWarehouseInventoryLots();
                          });
                        },
                      ),
                      const SizedBox(width: 7),
                      ChoiceChip(
                        label: const Text('Reserved'),
                        selected: _filter == 'reserved',
                        onSelected: (_) {
                          setState(() {
                            _filter = 'reserved';
                            _future = fetchWarehouseInventoryLots();
                          });
                        },
                      ),
                      const SizedBox(width: 7),
                      ChoiceChip(
                        label: const Text('Quarantine'),
                        selected: _filter == 'quarantine',
                        onSelected: (_) {
                          setState(() {
                            _filter = 'quarantine';
                            _future = fetchWarehouseInventoryLots();
                          });
                        },
                      ),
                      const SizedBox(width: 7),
                      ChoiceChip(
                        label: const Text('Unassigned'),
                        selected: _filter == 'unassigned',
                        onSelected: (_) {
                          setState(() {
                            _filter = 'unassigned';
                            _future = fetchWarehouseInventoryLots();
                          });
                        },
                      ),
                      const SizedBox(width: 7),
                      ChoiceChip(
                        label: const Text('Expiring'),
                        selected: _filter == 'expiring',
                        onSelected: (_) {
                          setState(() {
                            _filter = 'expiring';
                            _future = fetchWarehouseInventoryLots();
                          });
                        },
                      ),
                      const SizedBox(width: 7),
                      ChoiceChip(
                        label: const Text('Expired'),
                        selected: _filter == 'expired',
                        onSelected: (_) {
                          setState(() {
                            _filter = 'expired';
                            _future = fetchWarehouseInventoryLots();
                          });
                        },
                      ),
                      const SizedBox(width: 7),
                      ChoiceChip(
                        label: const Text('All'),
                        selected: _filter == 'all',
                        onSelected: (_) {
                          setState(() {
                            _filter = 'all';
                            _future = fetchWarehouseInventoryLots(
                              includeClosed: true,
                            );
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                if (filtered.isEmpty)
                  const FarmEmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: 'No warehouse lots in this view',
                    message:
                        'Complete a Receiving batch to create the first traceable warehouse lot.',
                  )
                else
                  ...filtered.map((lot) {
                    final color = _statusColor(lot);
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
                                    lot.productName,
                                    style: const TextStyle(
                                      color: FarmColors.ink,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                Text(
                                  lot.statusLabel,
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Lot ${lot.lotCode} • ${lot.farmName.isEmpty ? 'HPJ receiving' : lot.farmName}${lot.parish.isEmpty ? '' : ' • ${lot.parish}'}',
                              style: const TextStyle(
                                color: FarmColors.mutedText,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                Icon(
                                  lot.isUnassigned
                                      ? Icons.location_off_outlined
                                      : Icons.location_on_outlined,
                                  size: 15,
                                  color: lot.isUnassigned
                                      ? FarmColors.warning
                                      : FarmColors.primary,
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    'Storage: ${lot.locationLabel}',
                                    style: TextStyle(
                                      color: lot.isUnassigned
                                          ? FarmColors.warning
                                          : FarmColors.mutedText,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
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
                                _InventoryValue(
                                  label: 'On hand',
                                  value: lot.quantity(lot.quantityOnHand),
                                ),
                                _InventoryValue(
                                  label: 'Reserved',
                                  value: lot.quantity(lot.quantityReserved),
                                ),
                                _InventoryValue(
                                  label: 'Available',
                                  value: lot.quantity(lot.availableQuantity),
                                ),
                                _InventoryValue(
                                  label: 'Waste',
                                  value: lot.quantity(lot.quantityWasted),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Received ${_warehouseInventoryDate(lot.receivedAt)} • Best before ${_warehouseInventoryDate(lot.bestBeforeDate)}${lot.isExpired ? ' • EXPIRED' : lot.isExpiringSoon ? ' • EXPIRING SOON' : ''}',
                              style: const TextStyle(
                                color: FarmColors.mutedText,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 7,
                              runSpacing: 7,
                              children: [
                                if (lot.isActive) ...[
                                  OutlinedButton(
                                    onPressed: () => _inventoryAction(
                                      lot,
                                      'reserve',
                                      'Reserve Stock',
                                    ),
                                    child: const Text('Reserve'),
                                  ),
                                  if (lot.quantityReserved > 0)
                                    OutlinedButton(
                                      onPressed: () => _inventoryAction(
                                        lot,
                                        'release',
                                        'Release Reservation',
                                      ),
                                      child: const Text('Release'),
                                    ),
                                  OutlinedButton(
                                    onPressed: () => _inventoryAction(
                                      lot,
                                      'issue',
                                      'Issue / Pack Stock',
                                    ),
                                    child: const Text('Issue'),
                                  ),
                                  OutlinedButton(
                                    onPressed: () => _inventoryAction(
                                      lot,
                                      'waste',
                                      'Record Waste',
                                    ),
                                    child: const Text('Waste'),
                                  ),
                                  TextButton(
                                    onPressed: () => _inventoryAction(
                                      lot,
                                      'quarantine',
                                      'Quarantine Lot',
                                    ),
                                    child: const Text('Quarantine'),
                                  ),
                                ],
                                if (lot.isQuarantined)
                                  ElevatedButton(
                                    onPressed: () => _inventoryAction(
                                      lot,
                                      'activate',
                                      'Return Lot to Active',
                                    ),
                                    child: const Text('Return Active'),
                                  ),
                                OutlinedButton.icon(
                                  onPressed: () => _assignLocation(lot),
                                  icon: const Icon(Icons.place_outlined,
                                      size: 16),
                                  label: Text(
                                      lot.isUnassigned ? 'Put Away' : 'Move'),
                                ),
                                TextButton.icon(
                                  onPressed: () => _editLot(lot),
                                  icon:
                                      const Icon(Icons.edit_outlined, size: 16),
                                  label: const Text('Lot Details'),
                                ),
                                TextButton.icon(
                                  onPressed: () => _showHistory(lot),
                                  icon: const Icon(Icons.history_rounded,
                                      size: 16),
                                  label: const Text('History'),
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

class _InventoryMetric extends StatelessWidget {
  final String label;
  final String value;

  const _InventoryMetric({required this.label, required this.value});

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

class _InventoryValue extends StatelessWidget {
  final String label;
  final String value;

  const _InventoryValue({required this.label, required this.value});

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

// ================================================================
// PHASE 3Z — STORAGE LOCATION MANAGEMENT
// ================================================================

class WarehouseStorageLocationsScreen extends StatefulWidget {
  const WarehouseStorageLocationsScreen({super.key});

  @override
  State<WarehouseStorageLocationsScreen> createState() =>
      _WarehouseStorageLocationsScreenState();
}

class _WarehouseStorageLocationsScreenState
    extends State<WarehouseStorageLocationsScreen> {
  late Future<List<WarehouseStorageLocation>> _future;

  @override
  void initState() {
    super.initState();
    _future = fetchWarehouseStorageLocations();
  }

  Future<void> _refresh() async {
    final next = fetchWarehouseStorageLocations();
    setState(() => _future = next);
    await next;
  }

  Future<void> _editLocation([WarehouseStorageLocation? location]) async {
    final isNew = location == null;
    final code = TextEditingController(text: location?.code ?? '');
    final name = TextEditingController(text: location?.name ?? '');
    final zone = TextEditingController(text: location?.zone ?? '');
    final notes = TextEditingController(text: location?.notes ?? '');
    var isActive = location?.isActive ?? true;

    try {
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
                      Text(
                        isNew
                            ? 'Add Storage Location'
                            : 'Edit ${location.code}',
                        style: const TextStyle(
                          color: FarmColors.ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Use short physical codes such as A-01, CHILL-02 or RACK-B3 so pickers can find stock quickly.',
                        style: TextStyle(
                          color: FarmColors.mutedText,
                          fontSize: 10.5,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: code,
                        enabled: isNew,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Location code *',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: name,
                        decoration: const InputDecoration(
                          labelText: 'Location name *',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: zone,
                        decoration: const InputDecoration(
                          labelText: 'Zone / area (optional)',
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
                      if (!isNew) ...[
                        const SizedBox(height: 8),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          value: isActive,
                          title: const Text(
                            'Location active',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: const Text(
                            'Inactive locations stay in history but cannot receive new put-away assignments.',
                          ),
                          onChanged: (value) {
                            setSheetState(() => isActive = value);
                          },
                        ),
                      ],
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.of(sheetContext).pop(true),
                          icon: Icon(isNew
                              ? Icons.add_location_alt_outlined
                              : Icons.save_outlined),
                          label:
                              Text(isNew ? 'Create Location' : 'Save Location'),
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

      if (isNew) {
        await createWarehouseStorageLocation(
          code: code.text,
          name: name.text,
          zone: zone.text,
          notes: notes.text,
        );
      } else {
        await updateWarehouseStorageLocation(
          location: location,
          name: name.text,
          zone: zone.text,
          isActive: isActive,
          notes: notes.text,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isNew ? 'Storage location created.' : 'Storage location updated.',
          ),
        ),
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
      zone.dispose();
      notes.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: const _WarehouseAppBar(title: 'Storage Locations'),
      body: FutureBuilder<List<WarehouseStorageLocation>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError && snapshot.data == null) {
            return Center(child: Text(friendlyAppError(snapshot.error!)));
          }

          final locations = snapshot.data ?? const <WarehouseStorageLocation>[];
          final active = locations.where((item) => item.isActive).length;
          final inactive = locations.length - active;

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
                            Icons.grid_view_outlined,
                            color: FarmColors.primary,
                            size: 30,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Warehouse Put-Away Locations',
                                  style: TextStyle(
                                    color: FarmColors.ink,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Define the real shelves, racks, rooms or zones where received lots are stored. Lot history keeps the location even when a location is later disabled.',
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
                          onPressed: () => _editLocation(),
                          icon: const Icon(Icons.add_location_alt_outlined),
                          label: const Text('Add Storage Location'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _InventoryMetric(
                        label: 'Active',
                        value: '$active',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _InventoryMetric(
                        label: 'Inactive',
                        value: '$inactive',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (locations.isEmpty)
                  const FarmEmptyState(
                    icon: Icons.add_location_alt_outlined,
                    title: 'No storage locations yet',
                    message:
                        'Create the physical locations you will use for put-away and picking.',
                  )
                else
                  ...locations.map(
                    (location) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: FarmCard(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: location.isActive
                                    ? FarmColors.primarySoft
                                    : FarmColors.cardSoft,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                location.code,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: location.isActive
                                      ? FarmColors.primary
                                      : FarmColors.mutedText,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    location.name,
                                    style: const TextStyle(
                                      color: FarmColors.ink,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    [
                                      if (location.zone.isNotEmpty)
                                        location.zone,
                                      location.isActive ? 'Active' : 'Inactive',
                                    ].join(' • '),
                                    style: TextStyle(
                                      color: location.isActive
                                          ? FarmColors.success
                                          : FarmColors.mutedText,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  if (location.notes.isNotEmpty) ...[
                                    const SizedBox(height: 5),
                                    Text(
                                      location.notes,
                                      style: const TextStyle(
                                        color: FarmColors.mutedText,
                                        fontSize: 10.5,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Edit location',
                              onPressed: () => _editLocation(location),
                              icon: const Icon(Icons.edit_outlined),
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
