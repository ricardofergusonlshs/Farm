part of harvest_place_app;

// ================================================================
// THE HARVEST PLACE JA
// PHASE 3AM–3AN — PROCUREMENT INTELLIGENCE + ACTION QUEUE
// ================================================================

class WarehouseProcurementRecommendation {
  final String productName;
  final String unit;
  final double shortageQuantity;
  final double requiredQuantity;
  final double warehouseAvailable;
  final double unallocatedConfirmedSupply;
  final String? farmerId;
  final String farmName;
  final String farmerName;
  final String parish;
  final String? supplyForecastId;
  final String supplyStatus;
  final double candidateQuantity;
  final double trustedQuantity;
  final DateTime? expectedHarvestDate;
  final int? daysToHarvest;
  final double? supplierScore;
  final String performanceBand;
  final String sourcingStatus;
  final double recommendationScore;
  final double recommendedQuantity;
  final String recommendationAction;
  final String recommendationReason;
  final int candidateRank;

  const WarehouseProcurementRecommendation({
    required this.productName,
    required this.unit,
    required this.shortageQuantity,
    required this.requiredQuantity,
    required this.warehouseAvailable,
    required this.unallocatedConfirmedSupply,
    required this.farmerId,
    required this.farmName,
    required this.farmerName,
    required this.parish,
    required this.supplyForecastId,
    required this.supplyStatus,
    required this.candidateQuantity,
    required this.trustedQuantity,
    this.expectedHarvestDate,
    this.daysToHarvest,
    required this.supplierScore,
    required this.performanceBand,
    required this.sourcingStatus,
    required this.recommendationScore,
    required this.recommendedQuantity,
    required this.recommendationAction,
    required this.recommendationReason,
    required this.candidateRank,
  });

  factory WarehouseProcurementRecommendation.fromSupabase(
    Map<String, dynamic> data,
  ) {
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

    String? nullable(dynamic value) {
      final text = value?.toString().trim() ?? '';
      return text.isEmpty ? null : text;
    }

    return WarehouseProcurementRecommendation(
      productName: (data['product_name'] ?? 'Produce').toString().trim(),
      unit: (data['unit'] ?? 'unit').toString().trim(),
      shortageQuantity: amount(data['shortage_quantity']),
      requiredQuantity: amount(data['required_quantity']),
      warehouseAvailable: amount(data['warehouse_available']),
      unallocatedConfirmedSupply: amount(data['unallocated_confirmed_supply']),
      farmerId: nullable(data['farmer_id']),
      farmName: (data['farm_name'] ?? '').toString().trim(),
      farmerName: (data['farmer_name'] ?? '').toString().trim(),
      parish: (data['parish'] ?? '').toString().trim(),
      supplyForecastId: nullable(data['supply_forecast_id']),
      supplyStatus:
          (data['supply_status'] ?? 'none').toString().trim().toLowerCase(),
      candidateQuantity: amount(data['candidate_quantity']),
      trustedQuantity: amount(data['trusted_quantity']),
      expectedHarvestDate:
          DateTime.tryParse((data['expected_harvest_date'] ?? '').toString()),
      daysToHarvest: optionalInt(data['days_to_harvest']),
      supplierScore: optionalAmount(data['supplier_score']),
      performanceBand:
          (data['performance_band'] ?? 'new').toString().trim().toLowerCase(),
      sourcingStatus:
          (data['sourcing_status'] ?? 'active').toString().trim().toLowerCase(),
      recommendationScore: amount(data['recommendation_score']),
      recommendedQuantity: amount(data['recommended_quantity']),
      recommendationAction:
          (data['recommendation_action'] ?? 'source_additional_supplier')
              .toString()
              .trim()
              .toLowerCase(),
      recommendationReason:
          (data['recommendation_reason'] ?? '').toString().trim(),
      candidateRank: optionalInt(data['candidate_rank']) ?? 1,
    );
  }

  bool get hasFarmer => farmerId != null && farmerId!.isNotEmpty;
  bool get isTrusted => trustedQuantity > 0.000001;
  bool get needsExternalSource =>
      recommendationAction == 'source_additional_supplier';

  String quantity(double value) {
    final text = value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
    return '$text $unit';
  }

  String get actionLabel {
    switch (recommendationAction) {
      case 'reserve_confirmed_supply':
        return 'Review Confirmed Supply';
      case 'contact_farmer_to_confirm':
        return 'Contact Farmer';
      case 'monitor_and_verify_supply':
        return 'Monitor / Verify';
      default:
        return 'Source Additional Supplier';
    }
  }
}

class WarehouseProcurementAction {
  final String id;
  final String productName;
  final String unit;
  final String? farmerId;
  final String farmName;
  final String farmerName;
  final String parish;
  final String? supplyForecastId;
  final String supplyStatus;
  final String actionType;
  final String priority;
  final String status;
  final double shortageQuantitySnapshot;
  final double targetQuantity;
  final DateTime? needByDate;
  final String notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const WarehouseProcurementAction({
    required this.id,
    required this.productName,
    required this.unit,
    required this.farmerId,
    required this.farmName,
    required this.farmerName,
    required this.parish,
    required this.supplyForecastId,
    required this.supplyStatus,
    required this.actionType,
    required this.priority,
    required this.status,
    required this.shortageQuantitySnapshot,
    required this.targetQuantity,
    this.needByDate,
    required this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory WarehouseProcurementAction.fromSupabase(Map<String, dynamic> data) {
    double amount(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    String? nullable(dynamic value) {
      final text = value?.toString().trim() ?? '';
      return text.isEmpty ? null : text;
    }

    return WarehouseProcurementAction(
      id: (data['action_id'] ?? '').toString(),
      productName: (data['product_name'] ?? 'Produce').toString().trim(),
      unit: (data['unit'] ?? 'unit').toString().trim(),
      farmerId: nullable(data['farmer_id']),
      farmName: (data['farm_name'] ?? '').toString().trim(),
      farmerName: (data['farmer_name'] ?? '').toString().trim(),
      parish: (data['parish'] ?? '').toString().trim(),
      supplyForecastId: nullable(data['supply_forecast_id']),
      supplyStatus:
          (data['supply_status'] ?? '').toString().trim().toLowerCase(),
      actionType: (data['action_type'] ?? 'source_additional_supplier')
          .toString()
          .trim()
          .toLowerCase(),
      priority: (data['priority'] ?? 'normal').toString().trim().toLowerCase(),
      status: (data['status'] ?? 'open').toString().trim().toLowerCase(),
      shortageQuantitySnapshot: amount(data['shortage_quantity_snapshot']),
      targetQuantity: amount(data['target_quantity']),
      needByDate: DateTime.tryParse((data['need_by_date'] ?? '').toString()),
      notes: (data['notes'] ?? '').toString().trim(),
      createdAt: DateTime.tryParse((data['created_at'] ?? '').toString()),
      updatedAt: DateTime.tryParse((data['updated_at'] ?? '').toString()),
    );
  }

  String quantity(double value) {
    final text = value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
    return '$text $unit';
  }

  String get actionLabel {
    switch (actionType) {
      case 'reserve_confirmed_supply':
        return 'Review Confirmed Supply';
      case 'contact_farmer_to_confirm':
        return 'Contact Farmer';
      case 'monitor_and_verify_supply':
        return 'Monitor / Verify';
      default:
        return 'Source Additional Supplier';
    }
  }

  String get statusLabel {
    switch (status) {
      case 'contacted':
        return 'Contacted';
      case 'committed':
        return 'Supplier Committed';
      case 'closed':
        return 'Closed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Open';
    }
  }
}

Future<List<WarehouseProcurementRecommendation>>
    fetchWarehouseProcurementRecommendations() async {
  await requireAdminAccess();
  final response = await supabase.rpc(
    'admin_list_procurement_supplier_recommendations',
  );
  return (response as List)
      .map(
        (row) => WarehouseProcurementRecommendation.fromSupabase(
          Map<String, dynamic>.from(row as Map),
        ),
      )
      .toList();
}

Future<List<WarehouseProcurementAction>> fetchWarehouseProcurementActions({
  bool includeClosed = false,
}) async {
  await requireAdminAccess();
  final response = await supabase.rpc(
    'admin_list_procurement_actions',
    params: {'p_include_closed': includeClosed},
  );
  return (response as List)
      .map(
        (row) => WarehouseProcurementAction.fromSupabase(
          Map<String, dynamic>.from(row as Map),
        ),
      )
      .toList();
}

Future<void> createWarehouseProcurementAction({
  required WarehouseProcurementRecommendation recommendation,
  required String actionType,
  required String priority,
  required double targetQuantity,
  DateTime? needByDate,
  String notes = '',
}) async {
  await requireAdminAccess();
  await supabase.rpc(
    'admin_create_procurement_action',
    params: {
      'p_product_name': recommendation.productName,
      'p_unit': recommendation.unit,
      'p_farmer_id': recommendation.farmerId,
      'p_supply_forecast_id': recommendation.supplyForecastId,
      'p_action_type': actionType.trim().toLowerCase(),
      'p_priority': priority.trim().toLowerCase(),
      'p_shortage_quantity_snapshot': recommendation.shortageQuantity,
      'p_target_quantity': targetQuantity,
      'p_need_by_date': needByDate == null
          ? null
          : '${needByDate.year.toString().padLeft(4, '0')}-'
              '${needByDate.month.toString().padLeft(2, '0')}-'
              '${needByDate.day.toString().padLeft(2, '0')}',
      'p_notes': notes.trim(),
    },
  );
}

Future<void> updateWarehouseProcurementAction({
  required WarehouseProcurementAction action,
  String? status,
  String? priority,
  double? targetQuantity,
  DateTime? needByDate,
  bool clearNeedByDate = false,
  String? notes,
}) async {
  await requireAdminAccess();
  await supabase.rpc(
    'admin_update_procurement_action',
    params: {
      'p_action_id': action.id,
      'p_status': status,
      'p_priority': priority,
      'p_target_quantity': targetQuantity,
      'p_need_by_date': needByDate == null
          ? null
          : '${needByDate.year.toString().padLeft(4, '0')}-'
              '${needByDate.month.toString().padLeft(2, '0')}-'
              '${needByDate.day.toString().padLeft(2, '0')}',
      'p_clear_need_by_date': clearNeedByDate,
      'p_notes': notes,
    },
  );
}

String _procIntelDate(DateTime? value) {
  if (value == null) return 'Not set';
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
  final local = value.toLocal();
  return '${local.day} ${months[local.month - 1]} ${local.year}';
}

class WarehouseProcurementIntelligenceScreen extends StatefulWidget {
  const WarehouseProcurementIntelligenceScreen({super.key});

  @override
  State<WarehouseProcurementIntelligenceScreen> createState() =>
      _WarehouseProcurementIntelligenceScreenState();
}

class _WarehouseProcurementIntelligenceScreenState
    extends State<WarehouseProcurementIntelligenceScreen> {
  late Future<List<dynamic>> _future;
  String _view = 'recommendations';
  String _search = '';
  bool _includeClosed = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<dynamic>> _load() async {
    return Future.wait<dynamic>([
      fetchWarehouseProcurementRecommendations(),
      fetchWarehouseProcurementActions(includeClosed: _includeClosed),
    ]);
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() => _future = next);
    await next;
  }

  Color _recommendationColor(WarehouseProcurementRecommendation row) {
    if (row.isTrusted) return FarmColors.success;
    if (row.needsExternalSource) return FarmColors.danger;
    return FarmColors.warning;
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'critical':
        return FarmColors.danger;
      case 'high':
        return FarmColors.warning;
      case 'low':
        return FarmColors.mutedText;
      default:
        return FarmColors.primary;
    }
  }

  Future<void> _createAction(WarehouseProcurementRecommendation row) async {
    String actionType = row.recommendationAction;
    String priority = row.shortageQuantity > 0 ? 'high' : 'normal';
    DateTime? needByDate;
    double initialTarget = row.recommendedQuantity;
    if (initialTarget <= 0 && row.candidateQuantity > 0) {
      initialTarget = row.shortageQuantity < row.candidateQuantity
          ? row.shortageQuantity
          : row.candidateQuantity;
    }
    if (initialTarget <= 0) {
      initialTarget = row.shortageQuantity;
    }
    final target = TextEditingController(
      text: initialTarget.toStringAsFixed(
        initialTarget == initialTarget.roundToDouble() ? 0 : 1,
      ),
    );
    final notes = TextEditingController();

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
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
                  'Sourcing Action • ${row.productName}',
                  style: const TextStyle(
                    color: FarmColors.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  row.hasFarmer
                      ? '${row.farmName} • ${row.quantity(row.shortageQuantity)} shortage'
                      : '${row.quantity(row.shortageQuantity)} shortage • no eligible farmer candidate',
                  style: const TextStyle(
                    color: FarmColors.mutedText,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: actionType,
                  decoration: const InputDecoration(labelText: 'Action'),
                  items: const [
                    DropdownMenuItem(
                      value: 'reserve_confirmed_supply',
                      child: Text('Review Confirmed Supply'),
                    ),
                    DropdownMenuItem(
                      value: 'contact_farmer_to_confirm',
                      child: Text('Contact Farmer to Confirm'),
                    ),
                    DropdownMenuItem(
                      value: 'monitor_and_verify_supply',
                      child: Text('Monitor / Verify Supply'),
                    ),
                    DropdownMenuItem(
                      value: 'source_additional_supplier',
                      child: Text('Source Additional Supplier'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setSheetState(() => actionType = value);
                    }
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: priority,
                  decoration: const InputDecoration(labelText: 'Priority'),
                  items: const [
                    DropdownMenuItem(value: 'low', child: Text('Low')),
                    DropdownMenuItem(value: 'normal', child: Text('Normal')),
                    DropdownMenuItem(value: 'high', child: Text('High')),
                    DropdownMenuItem(
                        value: 'critical', child: Text('Critical')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setSheetState(() => priority = value);
                    }
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: target,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Target quantity (${row.unit})',
                  ),
                ),
                const SizedBox(height: 10),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Need-by date'),
                  subtitle: Text(_procIntelDate(needByDate)),
                  trailing: const Icon(Icons.calendar_month_outlined),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: needByDate ?? DateTime.now(),
                      firstDate:
                          DateTime.now().subtract(const Duration(days: 1)),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setSheetState(() => needByDate = picked);
                    }
                  },
                ),
                TextField(
                  controller: notes,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Sourcing notes',
                    helperText:
                        'This action tracks follow-up only; it does not reserve supply.',
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(sheetContext).pop(true),
                    icon: const Icon(Icons.add_task_rounded),
                    label: const Text('Create Sourcing Action'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (confirmed != true) {
      target.dispose();
      notes.dispose();
      return;
    }

    final targetValue =
        double.tryParse(target.text.trim().replaceAll(',', '')) ?? -1;
    if (targetValue < 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a valid target quantity.')),
        );
      }
      target.dispose();
      notes.dispose();
      return;
    }

    try {
      await createWarehouseProcurementAction(
        recommendation: row,
        actionType: actionType,
        priority: priority,
        targetQuantity: targetValue,
        needByDate: needByDate,
        notes: notes.text,
      );
      if (!mounted) return;
      setState(() => _view = 'actions');
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyAppError(error))),
      );
    } finally {
      target.dispose();
      notes.dispose();
    }
  }

  Future<void> _editAction(WarehouseProcurementAction action) async {
    String status = action.status;
    String priority = action.priority;
    DateTime? needByDate = action.needByDate;
    bool clearNeedByDate = false;
    final target = TextEditingController(
      text: action.targetQuantity.toStringAsFixed(
        action.targetQuantity == action.targetQuantity.roundToDouble() ? 0 : 1,
      ),
    );
    final notes = TextEditingController(text: action.notes);

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
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
                  action.productName,
                  style: const TextStyle(
                    color: FarmColors.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: const [
                    DropdownMenuItem(value: 'open', child: Text('Open')),
                    DropdownMenuItem(
                        value: 'contacted', child: Text('Contacted')),
                    DropdownMenuItem(
                      value: 'committed',
                      child: Text('Supplier Committed'),
                    ),
                    DropdownMenuItem(value: 'closed', child: Text('Closed')),
                    DropdownMenuItem(
                        value: 'cancelled', child: Text('Cancelled')),
                  ],
                  onChanged: (value) {
                    if (value != null) setSheetState(() => status = value);
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: priority,
                  decoration: const InputDecoration(labelText: 'Priority'),
                  items: const [
                    DropdownMenuItem(value: 'low', child: Text('Low')),
                    DropdownMenuItem(value: 'normal', child: Text('Normal')),
                    DropdownMenuItem(value: 'high', child: Text('High')),
                    DropdownMenuItem(
                        value: 'critical', child: Text('Critical')),
                  ],
                  onChanged: (value) {
                    if (value != null) setSheetState(() => priority = value);
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: target,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Target quantity (${action.unit})',
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Need-by date'),
                  subtitle: Text(
                    clearNeedByDate ? 'Cleared' : _procIntelDate(needByDate),
                  ),
                  trailing: Wrap(
                    spacing: 2,
                    children: [
                      IconButton(
                        tooltip: 'Choose date',
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: needByDate ?? DateTime.now(),
                            firstDate: DateTime.now()
                                .subtract(const Duration(days: 1)),
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setSheetState(() {
                              needByDate = picked;
                              clearNeedByDate = false;
                            });
                          }
                        },
                        icon: const Icon(Icons.calendar_month_outlined),
                      ),
                      IconButton(
                        tooltip: 'Clear date',
                        onPressed: () => setSheetState(() {
                          needByDate = null;
                          clearNeedByDate = true;
                        }),
                        icon: const Icon(Icons.clear_rounded),
                      ),
                    ],
                  ),
                ),
                TextField(
                  controller: notes,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Notes'),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(sheetContext).pop(true),
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save Action'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (confirmed != true) {
      target.dispose();
      notes.dispose();
      return;
    }

    final targetValue =
        double.tryParse(target.text.trim().replaceAll(',', '')) ?? -1;
    if (targetValue < 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a valid target quantity.')),
        );
      }
      target.dispose();
      notes.dispose();
      return;
    }

    try {
      await updateWarehouseProcurementAction(
        action: action,
        status: status,
        priority: priority,
        targetQuantity: targetValue,
        needByDate: needByDate,
        clearNeedByDate: clearNeedByDate,
        notes: notes.text,
      );
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyAppError(error))),
      );
    } finally {
      target.dispose();
      notes.dispose();
    }
  }

  Widget _metric(String label, String value) {
    return Container(
      width: 126,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FarmColors.cardSoft,
        borderRadius: BorderRadius.circular(16),
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
          const SizedBox(height: 2),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: const _WarehouseAppBar(title: 'Procurement Intelligence'),
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
          final recommendations = data.isEmpty
              ? const <WarehouseProcurementRecommendation>[]
              : data[0] as List<WarehouseProcurementRecommendation>;
          final actions = data.length < 2
              ? const <WarehouseProcurementAction>[]
              : data[1] as List<WarehouseProcurementAction>;

          final search = _search.trim().toLowerCase();
          final shownRecommendations = recommendations.where((row) {
            if (row.candidateRank > 3) return false;
            return search.isEmpty ||
                row.productName.toLowerCase().contains(search) ||
                row.farmName.toLowerCase().contains(search) ||
                row.farmerName.toLowerCase().contains(search) ||
                row.parish.toLowerCase().contains(search);
          }).toList();
          final shownActions = actions.where((row) {
            return search.isEmpty ||
                row.productName.toLowerCase().contains(search) ||
                row.farmName.toLowerCase().contains(search) ||
                row.farmerName.toLowerCase().contains(search) ||
                row.status.toLowerCase().contains(search);
          }).toList();

          final shortageKeys = recommendations
              .map((row) =>
                  '${row.productName.toLowerCase()}|${row.unit.toLowerCase()}')
              .toSet();
          final trusted = recommendations.where((row) => row.isTrusted).length;
          final external = recommendations
              .where((row) => row.needsExternalSource && !row.hasFarmer)
              .length;
          final openActions = actions
              .where(
                  (row) => row.status != 'closed' && row.status != 'cancelled')
              .length;

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
                        Icons.insights_outlined,
                        color: FarmColors.primary,
                        size: 30,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Procurement Intelligence',
                              style: TextStyle(
                                color: FarmColors.ink,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Rank farmers around live shortage lines. This screen is advisory: use Wholesale → Procurement to verify and actually reserve farmer supply. Action Queue entries track follow-up only.',
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
                      _metric('Shortage Lines', '${shortageKeys.length}'),
                      const SizedBox(width: 8),
                      _metric('Trusted Candidates', '$trusted'),
                      const SizedBox(width: 8),
                      _metric('External Sourcing', '$external'),
                      const SizedBox(width: 8),
                      _metric('Open Actions', '$openActions'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Recommendations'),
                        selected: _view == 'recommendations',
                        onSelected: (_) =>
                            setState(() => _view = 'recommendations'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Action Queue'),
                        selected: _view == 'actions',
                        onSelected: (_) => setState(() => _view = 'actions'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  onChanged: (value) => setState(() => _search = value),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search_rounded),
                    hintText: 'Search product, farm, farmer or parish',
                  ),
                ),
                if (_view == 'actions') ...[
                  const SizedBox(height: 8),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: _includeClosed,
                    title: const Text('Show closed / cancelled actions'),
                    onChanged: (value) {
                      setState(() {
                        _includeClosed = value;
                        _future = _load();
                      });
                    },
                  ),
                ],
                const SizedBox(height: 12),
                if (_view == 'recommendations')
                  if (shownRecommendations.isEmpty)
                    const FarmEmptyState(
                      icon: Icons.check_circle_outline,
                      title: 'No procurement shortage recommendations',
                      message:
                          'When committed demand exceeds trusted supply, ranked sourcing recommendations will appear here.',
                    )
                  else
                    ...shownRecommendations.map((row) {
                      final color = _recommendationColor(row);
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
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          row.productName,
                                          style: const TextStyle(
                                            color: FarmColors.ink,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${row.quantity(row.shortageQuantity)} short • candidate #${row.candidateRank}',
                                          style: TextStyle(
                                            color: color,
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w900,
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
                                      color: color.withOpacity(.10),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      row.actionLabel.toUpperCase(),
                                      style: TextStyle(
                                        color: color,
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              if (row.hasFarmer) ...[
                                Text(
                                  '${row.farmName} • ${row.farmerName}${row.parish.isEmpty ? '' : ' • ${row.parish}'}',
                                  style: const TextStyle(
                                    color: FarmColors.ink,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 7),
                                Wrap(
                                  spacing: 7,
                                  runSpacing: 7,
                                  children: [
                                    _ProcIntelChip(
                                      label: row.isTrusted
                                          ? 'Trusted available'
                                          : 'Supply signal',
                                      value: row.quantity(
                                        row.isTrusted
                                            ? row.trustedQuantity
                                            : row.candidateQuantity,
                                      ),
                                    ),
                                    _ProcIntelChip(
                                      label: 'Supplier score',
                                      value: row.supplierScore == null
                                          ? 'New'
                                          : row.supplierScore!
                                              .toStringAsFixed(1),
                                    ),
                                    _ProcIntelChip(
                                      label: 'Sourcing',
                                      value: row.sourcingStatus,
                                    ),
                                    _ProcIntelChip(
                                      label: 'Harvest',
                                      value: _procIntelDate(
                                        row.expectedHarvestDate,
                                      ),
                                    ),
                                  ],
                                ),
                              ] else
                                const Text(
                                  'No eligible farmer supply candidate is currently available for this product and unit.',
                                  style: TextStyle(
                                    color: FarmColors.danger,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              const SizedBox(height: 9),
                              Text(
                                row.recommendationReason,
                                style: const TextStyle(
                                  color: FarmColors.mutedText,
                                  fontSize: 10,
                                  height: 1.35,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (row.recommendedQuantity > 0) ...[
                                const SizedBox(height: 6),
                                Text(
                                  row.recommendationAction ==
                                          'reserve_confirmed_supply'
                                      ? 'Suggested allocation follow-up: ${row.quantity(row.recommendedQuantity)}'
                                      : 'Suggested sourcing target: ${row.quantity(row.recommendedQuantity)}',
                                  style: TextStyle(
                                    color: row.recommendationAction ==
                                            'reserve_confirmed_supply'
                                        ? FarmColors.success
                                        : FarmColors.warning,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () => _createAction(row),
                                  icon: const Icon(Icons.add_task_rounded),
                                  label:
                                      const Text('Create Sourcing Follow-up'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    })
                else if (shownActions.isEmpty)
                  const FarmEmptyState(
                    icon: Icons.task_alt_outlined,
                    title: 'No sourcing actions',
                    message:
                        'Create follow-up actions from procurement recommendations when staff need to contact, verify or source supply.',
                  )
                else
                  ...shownActions.map((action) {
                    final color = _priorityColor(action.priority);
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
                                    action.productName,
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
                                    color: color.withOpacity(.10),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    action.priority.toUpperCase(),
                                    style: TextStyle(
                                      color: color,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '${action.actionLabel} • ${action.statusLabel}',
                              style: const TextStyle(
                                color: FarmColors.primary,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            if (action.farmName.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                '${action.farmName} • ${action.farmerName}${action.parish.isEmpty ? '' : ' • ${action.parish}'}',
                                style: const TextStyle(
                                  color: FarmColors.mutedText,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 7,
                              runSpacing: 7,
                              children: [
                                _ProcIntelChip(
                                  label: 'Target',
                                  value: action.quantity(action.targetQuantity),
                                ),
                                _ProcIntelChip(
                                  label: 'Shortage at creation',
                                  value: action.quantity(
                                    action.shortageQuantitySnapshot,
                                  ),
                                ),
                                _ProcIntelChip(
                                  label: 'Need by',
                                  value: _procIntelDate(action.needByDate),
                                ),
                              ],
                            ),
                            if (action.notes.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                action.notes,
                                style: const TextStyle(
                                  color: FarmColors.mutedText,
                                  fontSize: 9.5,
                                  height: 1.35,
                                ),
                              ),
                            ],
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => _editAction(action),
                                icon: const Icon(Icons.edit_outlined),
                                label: const Text('Update Action'),
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

class _ProcIntelChip extends StatelessWidget {
  final String label;
  final String value;

  const _ProcIntelChip({required this.label, required this.value});

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
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: FarmColors.ink,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
