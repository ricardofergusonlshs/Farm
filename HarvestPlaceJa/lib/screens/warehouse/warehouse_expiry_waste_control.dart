part of harvest_place_app;

// ================================================================
// THE HARVEST PLACE JA
// PHASE 3AP — EXPIRY + WASTE CONTROL
// ================================================================

class WarehouseInventoryRiskRow {
  final String lotId;
  final String lotCode;
  final String productName;
  final String unit;
  final String storageLocationCode;
  final double quantityOnHand;
  final double quantityReserved;
  final double availableQuantity;
  final double quantityWasted;
  final DateTime? bestBeforeDate;
  final int ageDays;
  final int? daysToBestBefore;
  final double? estimatedDaysCover;
  final double wasteRatioPercent;
  final String riskType;
  final String riskReason;
  final String reviewStatus;
  final String reviewNote;
  final DateTime? reviewUpdatedAt;

  const WarehouseInventoryRiskRow({
    required this.lotId,
    required this.lotCode,
    required this.productName,
    required this.unit,
    required this.storageLocationCode,
    required this.quantityOnHand,
    required this.quantityReserved,
    required this.availableQuantity,
    required this.quantityWasted,
    this.bestBeforeDate,
    required this.ageDays,
    this.daysToBestBefore,
    this.estimatedDaysCover,
    required this.wasteRatioPercent,
    required this.riskType,
    required this.riskReason,
    required this.reviewStatus,
    required this.reviewNote,
    this.reviewUpdatedAt,
  });

  factory WarehouseInventoryRiskRow.fromSupabase(Map<String, dynamic> data) {
    double amount(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    double? optionalAmount(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    int? optionalInt(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString());
    }

    return WarehouseInventoryRiskRow(
      lotId: (data['lot_id'] ?? '').toString(),
      lotCode: (data['lot_code'] ?? '').toString().trim(),
      productName: (data['product_name'] ?? 'Produce').toString().trim(),
      unit: (data['unit'] ?? 'unit').toString().trim(),
      storageLocationCode:
          (data['storage_location_code'] ?? '').toString().trim(),
      quantityOnHand: amount(data['quantity_on_hand']),
      quantityReserved: amount(data['quantity_reserved']),
      availableQuantity: amount(data['available_quantity']),
      quantityWasted: amount(data['quantity_wasted']),
      bestBeforeDate:
          DateTime.tryParse((data['best_before_date'] ?? '').toString()),
      ageDays: optionalInt(data['age_days']) ?? 0,
      daysToBestBefore: optionalInt(data['days_to_best_before']),
      estimatedDaysCover: optionalAmount(data['estimated_days_cover']),
      wasteRatioPercent: amount(data['waste_ratio_percent']),
      riskType: (data['risk_type'] ?? 'risk').toString().trim().toLowerCase(),
      riskReason: (data['risk_reason'] ?? '').toString().trim(),
      reviewStatus:
          (data['review_status'] ?? 'open').toString().trim().toLowerCase(),
      reviewNote: (data['review_note'] ?? '').toString().trim(),
      reviewUpdatedAt:
          DateTime.tryParse((data['review_updated_at'] ?? '').toString()),
    );
  }

  bool get isExpiry => const {
        'expired',
        'critical_expiry',
        'expiring_soon',
        'missing_best_before',
      }.contains(riskType);

  bool get isWaste => riskType == 'high_waste';
  bool get isSlow => const {'stale', 'slow_moving'}.contains(riskType);

  String quantity(double value) {
    final text = value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
    return '$text $unit';
  }

  String get riskLabel {
    switch (riskType) {
      case 'expired':
        return 'Expired';
      case 'critical_expiry':
        return 'Critical Expiry';
      case 'expiring_soon':
        return 'Expiring Soon';
      case 'missing_best_before':
        return 'Missing Best-Before';
      case 'high_waste':
        return 'High Waste';
      case 'stale':
        return 'Stale';
      case 'slow_moving':
        return 'Slow Moving';
      case 'quarantined':
        return 'Quarantined';
      default:
        return 'Inventory Risk';
    }
  }
}

Future<List<WarehouseInventoryRiskRow>> fetchWarehouseInventoryRiskQueue() async {
  await requireAdminAccess();
  final response = await supabase.rpc('admin_list_warehouse_inventory_risk_queue');
  return (response as List)
      .map(
        (row) => WarehouseInventoryRiskRow.fromSupabase(
          Map<String, dynamic>.from(row),
        ),
      )
      .toList();
}

Future<void> updateWarehouseInventoryRiskReview({
  required WarehouseInventoryRiskRow row,
  required String status,
  String note = '',
}) async {
  await requireAdminAccess();
  await supabase.rpc(
    'admin_update_warehouse_inventory_risk_review',
    params: {
      'p_lot_id': row.lotId,
      'p_risk_type': row.riskType,
      'p_status': status,
      'p_note': note.trim(),
    },
  );
}

Future<void> applyWarehouseInventoryRiskAction({
  required WarehouseInventoryRiskRow row,
  required String action,
  double quantity = 0,
  String note = '',
}) async {
  await requireAdminAccess();
  await supabase.rpc(
    'admin_apply_warehouse_inventory_risk_action',
    params: {
      'p_lot_id': row.lotId,
      'p_risk_type': row.riskType,
      'p_action': action,
      'p_quantity': quantity,
      'p_note': note.trim(),
    },
  );
}

class WarehouseExpiryWasteControlScreen extends StatefulWidget {
  const WarehouseExpiryWasteControlScreen({super.key});

  @override
  State<WarehouseExpiryWasteControlScreen> createState() =>
      _WarehouseExpiryWasteControlScreenState();
}

class _WarehouseExpiryWasteControlScreenState
    extends State<WarehouseExpiryWasteControlScreen> {
  late Future<List<WarehouseInventoryRiskRow>> _future;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _future = fetchWarehouseInventoryRiskQueue();
  }

  Future<void> _refresh() async {
    final next = fetchWarehouseInventoryRiskQueue();
    setState(() => _future = next);
    await next;
  }

  Color _riskColor(WarehouseInventoryRiskRow row) {
    if (row.riskType == 'expired' || row.riskType == 'critical_expiry') {
      return FarmColors.danger;
    }
    if (row.riskType == 'quarantined') return FarmColors.danger;
    return FarmColors.warning;
  }

  Future<void> _setReview(
    WarehouseInventoryRiskRow row,
    String status,
  ) async {
    final note = TextEditingController(text: row.reviewNote);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(status == 'monitoring' ? 'Monitor this risk?' : 'Acknowledge risk?'),
        content: TextField(
          controller: note,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Review note (optional)'),
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
    if (confirmed != true) {
      note.dispose();
      return;
    }
    try {
      await updateWarehouseInventoryRiskReview(
        row: row,
        status: status,
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

  Future<void> _quarantine(WarehouseInventoryRiskRow row) async {
    final note = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Quarantine ${row.lotCode}?'),
        content: TextField(
          controller: note,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Reason / handling note',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Quarantine'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      note.dispose();
      return;
    }
    try {
      await applyWarehouseInventoryRiskAction(
        row: row,
        action: 'quarantine',
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

  Future<void> _recordWaste(WarehouseInventoryRiskRow row) async {
    final quantity = TextEditingController(
      text: row.availableQuantity.toStringAsFixed(
        row.availableQuantity == row.availableQuantity.roundToDouble() ? 0 : 1,
      ),
    );
    final note = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Record waste • ${row.lotCode}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: quantity,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Waste quantity (${row.unit})',
                helperText:
                    'Available unreserved stock: ${row.quantity(row.availableQuantity)}',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: note,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Waste reason'),
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
            child: const Text('Record Waste'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      quantity.dispose();
      note.dispose();
      return;
    }
    final amount = double.tryParse(quantity.text.trim().replaceAll(',', '')) ?? 0;
    try {
      await applyWarehouseInventoryRiskAction(
        row: row,
        action: 'waste',
        quantity: amount,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: const _WarehouseAppBar(title: 'Expiry & Waste Control'),
      body: FutureBuilder<List<WarehouseInventoryRiskRow>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError && snapshot.data == null) {
            return Center(child: Text(friendlyAppError(snapshot.error!)));
          }
          final rows = snapshot.data ?? const <WarehouseInventoryRiskRow>[];
          final filtered = rows.where((row) {
            switch (_filter) {
              case 'expiry':
                return row.isExpiry;
              case 'waste':
                return row.isWaste;
              case 'slow':
                return row.isSlow;
              case 'quarantine':
                return row.riskType == 'quarantined';
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
                        Icons.health_and_safety_outlined,
                        color: FarmColors.primary,
                        size: 30,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Expiry & Waste Risk Queue',
                              style: TextStyle(
                                color: FarmColors.ink,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Review risky lots, monitor them, quarantine questionable stock, or record waste against unreserved inventory.',
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
                      for (final entry in const [
                        ('all', 'All'),
                        ('expiry', 'Expiry'),
                        ('waste', 'Waste'),
                        ('slow', 'Slow'),
                        ('quarantine', 'Quarantine'),
                      ]) ...[
                        ChoiceChip(
                          label: Text(entry.$2),
                          selected: _filter == entry.$1,
                          onSelected: (_) => setState(() => _filter = entry.$1),
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
                    title: 'No open inventory risks',
                    message:
                        'Current inventory health does not have any unresolved risk in this filter.',
                  )
                else
                  ...filtered.map((row) {
                    final color = _riskColor(row);
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
                                    '${row.productName} • ${row.lotCode}',
                                    style: const TextStyle(
                                      color: FarmColors.ink,
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                Text(
                                  row.riskLabel,
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              row.riskReason,
                              style: const TextStyle(
                                color: FarmColors.mutedText,
                                fontSize: 10.5,
                                height: 1.35,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 9),
                            Wrap(
                              spacing: 7,
                              runSpacing: 7,
                              children: [
                                _WarehouseIntelChip(
                                  label: 'Available',
                                  value: row.quantity(row.availableQuantity),
                                ),
                                _WarehouseIntelChip(
                                  label: 'Reserved',
                                  value: row.quantity(row.quantityReserved),
                                ),
                                _WarehouseIntelChip(
                                  label: 'Age',
                                  value: '${row.ageDays} days',
                                ),
                                _WarehouseIntelChip(
                                  label: 'Waste',
                                  value:
                                      '${row.wasteRatioPercent.toStringAsFixed(1)}%',
                                ),
                              ],
                            ),
                            if (row.reviewStatus != 'open' ||
                                row.reviewNote.isNotEmpty) ...[
                              const SizedBox(height: 9),
                              Text(
                                'Review: ${row.reviewStatus}${row.reviewNote.isEmpty ? '' : ' • ${row.reviewNote}'}',
                                style: const TextStyle(
                                  color: FarmColors.mutedText,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 7,
                              runSpacing: 7,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () => _setReview(row, 'monitoring'),
                                  icon: const Icon(Icons.visibility_outlined),
                                  label: const Text('Monitor'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () => _setReview(row, 'acknowledged'),
                                  icon: const Icon(Icons.done_outlined),
                                  label: const Text('Acknowledge'),
                                ),
                                if (row.riskType != 'quarantined')
                                  OutlinedButton.icon(
                                    onPressed: () => _quarantine(row),
                                    icon: const Icon(Icons.block_outlined),
                                    label: const Text('Quarantine'),
                                  ),
                                if (row.availableQuantity > 0)
                                  ElevatedButton.icon(
                                    onPressed: () => _recordWaste(row),
                                    icon: const Icon(Icons.delete_outline),
                                    label: const Text('Record Waste'),
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
