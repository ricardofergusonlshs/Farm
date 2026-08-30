part of harvest_place_app;

// ================================================================
// THE HARVEST PLACE JA
// PHASE 3AT — AUTOMATED PROCUREMENT SUGGESTIONS
// ================================================================

class WarehouseProcurementSuggestion {
  final String id;
  final String productName;
  final String unit;
  final int horizonDays;
  final double forecastDemandSnapshot;
  final double trustedSupplySnapshot;
  final double expectedSupplySignalSnapshot;
  final double gapQuantity;
  final double suggestedQuantity;
  final DateTime? needByDate;
  final String priority;
  final String status;
  final String rationale;
  final String reviewNote;
  final String? linkedActionId;
  final DateTime? generatedAt;
  final DateTime? reviewedAt;

  const WarehouseProcurementSuggestion({
    required this.id,
    required this.productName,
    required this.unit,
    required this.horizonDays,
    required this.forecastDemandSnapshot,
    required this.trustedSupplySnapshot,
    required this.expectedSupplySignalSnapshot,
    required this.gapQuantity,
    required this.suggestedQuantity,
    this.needByDate,
    required this.priority,
    required this.status,
    required this.rationale,
    required this.reviewNote,
    this.linkedActionId,
    this.generatedAt,
    this.reviewedAt,
  });

  factory WarehouseProcurementSuggestion.fromSupabase(
      Map<String, dynamic> data) {
    double n(dynamic value) => value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '') ?? 0;
    int i(dynamic value) => value is num
        ? value.toInt()
        : int.tryParse(value?.toString() ?? '') ?? 0;
    String? nullable(dynamic value) {
      final text = value?.toString().trim() ?? '';
      return text.isEmpty ? null : text;
    }

    return WarehouseProcurementSuggestion(
      id: (data['suggestion_id'] ?? data['id'] ?? '').toString(),
      productName: (data['product_name'] ?? 'Produce').toString().trim(),
      unit: (data['unit'] ?? 'unit').toString().trim(),
      horizonDays: i(data['horizon_days']),
      forecastDemandSnapshot: n(data['forecast_demand_snapshot']),
      trustedSupplySnapshot: n(data['trusted_supply_snapshot']),
      expectedSupplySignalSnapshot: n(data['expected_supply_signal_snapshot']),
      gapQuantity: n(data['gap_quantity']),
      suggestedQuantity: n(data['suggested_quantity']),
      needByDate: DateTime.tryParse((data['need_by_date'] ?? '').toString()),
      priority: (data['priority'] ?? 'normal').toString().trim().toLowerCase(),
      status: (data['status'] ?? 'suggested').toString().trim().toLowerCase(),
      rationale: (data['rationale'] ?? '').toString().trim(),
      reviewNote: (data['review_note'] ?? '').toString().trim(),
      linkedActionId: nullable(data['linked_action_id']),
      generatedAt: DateTime.tryParse((data['generated_at'] ?? '').toString()),
      reviewedAt: DateTime.tryParse((data['reviewed_at'] ?? '').toString()),
    );
  }

  String quantity(double value) {
    final text = value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
    return '$text $unit';
  }
}

Future<List<WarehouseProcurementSuggestion>>
    fetchWarehouseProcurementSuggestions({
  int? horizonDays,
  String status = 'suggested',
}) async {
  await requireAdminAccess();
  final response = await supabase.rpc(
    'admin_list_warehouse_procurement_suggestions',
    params: {'p_horizon_days': horizonDays, 'p_status': status},
  );
  return (response as List)
      .map((row) => WarehouseProcurementSuggestion.fromSupabase(
          Map<String, dynamic>.from(row as Map)))
      .toList();
}

Future<int> refreshWarehouseProcurementSuggestions({
  int horizonDays = 30,
  int historyDays = 90,
}) async {
  await requireAdminAccess();
  final response = await supabase.rpc(
    'admin_refresh_warehouse_procurement_suggestions',
    params: {'p_horizon_days': horizonDays, 'p_history_days': historyDays},
  );
  if (response is num) return response.toInt();
  return int.tryParse(response?.toString() ?? '') ?? 0;
}

Future<String> acceptWarehouseProcurementSuggestion(
  WarehouseProcurementSuggestion suggestion, {
  String note = '',
}) async {
  await requireAdminAccess();
  final response = await supabase.rpc(
    'admin_accept_warehouse_procurement_suggestion',
    params: {'p_suggestion_id': suggestion.id, 'p_note': note.trim()},
  );
  return response?.toString() ?? '';
}

Future<void> dismissWarehouseProcurementSuggestion(
  WarehouseProcurementSuggestion suggestion, {
  String note = '',
}) async {
  await requireAdminAccess();
  await supabase.rpc(
    'admin_dismiss_warehouse_procurement_suggestion',
    params: {'p_suggestion_id': suggestion.id, 'p_note': note.trim()},
  );
}

class WarehouseProcurementSuggestionsScreen extends StatefulWidget {
  const WarehouseProcurementSuggestionsScreen({super.key});
  @override
  State<WarehouseProcurementSuggestionsScreen> createState() =>
      _WarehouseProcurementSuggestionsScreenState();
}

class _WarehouseProcurementSuggestionsScreenState
    extends State<WarehouseProcurementSuggestionsScreen> {
  int _horizon = 30;
  late Future<List<WarehouseProcurementSuggestion>> _future;

  @override
  void initState() {
    super.initState();
    _future = fetchWarehouseProcurementSuggestions(horizonDays: _horizon);
  }

  Future<void> _refresh() async {
    final next = fetchWarehouseProcurementSuggestions(horizonDays: _horizon);
    setState(() => _future = next);
    await next;
  }

  void _changeHorizon(int days) {
    setState(() {
      _horizon = days;
      _future = fetchWarehouseProcurementSuggestions(horizonDays: days);
    });
  }

  Future<void> _generate() async {
    try {
      final count =
          await refreshWarehouseProcurementSuggestions(horizonDays: _horizon);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              '$count procurement suggestion${count == 1 ? '' : 's'} generated.')));
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(friendlyAppError(error))));
    }
  }

  Future<String?> _noteDialog(String title) async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Note (optional)')),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(controller.text),
              child: const Text('Confirm')),
        ],
      ),
    );
    controller.dispose();
    return value;
  }

  Future<void> _accept(WarehouseProcurementSuggestion item) async {
    final note = await _noteDialog('Create procurement action?');
    if (note == null) return;
    try {
      await acceptWarehouseProcurementSuggestion(item, note: note);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Suggestion moved to the procurement action queue.')));
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(friendlyAppError(error))));
    }
  }

  Future<void> _dismiss(WarehouseProcurementSuggestion item) async {
    final note = await _noteDialog('Dismiss suggestion?');
    if (note == null) return;
    try {
      await dismissWarehouseProcurementSuggestion(item, note: note);
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(friendlyAppError(error))));
    }
  }

  Color _priorityColor(String priority) {
    if (priority == 'critical') return FarmColors.danger;
    if (priority == 'high') return FarmColors.warning;
    return FarmColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: const _WarehouseAppBar(title: 'Procurement Suggestions'),
      body: FutureBuilder<List<WarehouseProcurementSuggestion>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError && snapshot.data == null) {
            return Center(child: Text(friendlyAppError(snapshot.error!)));
          }
          final rows =
              snapshot.data ?? const <WarehouseProcurementSuggestion>[];
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 110),
              children: [
                const FarmCard(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Generate sourcing recommendations from the forecast supply gap. Suggestions never place an order or reserve farmer supply automatically. Accepting one only creates or escalates an item in the existing procurement action queue.',
                    style: TextStyle(
                        color: FarmColors.mutedText,
                        fontSize: 11,
                        height: 1.4,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(spacing: 7, runSpacing: 7, children: [
                  ...[7, 14, 30, 60].map((days) => ChoiceChip(
                      label: Text('$days days'),
                      selected: _horizon == days,
                      onSelected: (_) => _changeHorizon(days))),
                  ElevatedButton.icon(
                      onPressed: _generate,
                      icon: const Icon(Icons.analytics_outlined, size: 17),
                      label: const Text('Generate')),
                ]),
                const SizedBox(height: 14),
                if (rows.isEmpty)
                  const FarmEmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: 'No active suggestions',
                      message:
                          'Tap Generate to evaluate the current forecast and create sourcing recommendations.')
                else
                  ...rows.map((item) {
                    final color = _priorityColor(item.priority);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: FarmCard(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Expanded(
                                    child: Text(item.productName,
                                        style: const TextStyle(
                                            color: FarmColors.ink,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w900))),
                                Text(item.priority.toUpperCase(),
                                    style: TextStyle(
                                        color: color,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w900)),
                              ]),
                              const SizedBox(height: 4),
                              Text(
                                  'Source ${item.quantity(item.suggestedQuantity)} • ${item.horizonDays}-day horizon',
                                  style: const TextStyle(
                                      color: FarmColors.primary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900)),
                              const SizedBox(height: 9),
                              Wrap(spacing: 7, runSpacing: 7, children: [
                                _ProcurementSuggestionValue(
                                    label: 'Forecast',
                                    value: item
                                        .quantity(item.forecastDemandSnapshot)),
                                _ProcurementSuggestionValue(
                                    label: 'Trusted supply',
                                    value: item
                                        .quantity(item.trustedSupplySnapshot)),
                                _ProcurementSuggestionValue(
                                    label: 'Gap',
                                    value: item.quantity(item.gapQuantity)),
                                _ProcurementSuggestionValue(
                                    label: 'Expected signal',
                                    value: item.quantity(
                                        item.expectedSupplySignalSnapshot)),
                              ]),
                              const SizedBox(height: 9),
                              Text(item.rationale,
                                  style: const TextStyle(
                                      color: FarmColors.mutedText,
                                      fontSize: 10.5,
                                      height: 1.35,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 10),
                              Wrap(spacing: 8, children: [
                                ElevatedButton.icon(
                                    onPressed: () => _accept(item),
                                    icon: const Icon(
                                        Icons.playlist_add_check_rounded,
                                        size: 17),
                                    label: const Text('Create Action')),
                                TextButton(
                                    onPressed: () => _dismiss(item),
                                    child: const Text('Dismiss')),
                              ]),
                            ]),
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

class _ProcurementSuggestionValue extends StatelessWidget {
  final String label;
  final String value;
  const _ProcurementSuggestionValue({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        decoration: BoxDecoration(
            color: FarmColors.cardSoft,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: FarmColors.line)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(
                  color: FarmColors.mutedText,
                  fontSize: 9,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  color: FarmColors.ink,
                  fontSize: 11,
                  fontWeight: FontWeight.w900)),
        ]),
      );
}
