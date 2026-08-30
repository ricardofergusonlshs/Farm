part of harvest_place_app;

// ================================================================
// THE HARVEST PLACE JA
// PHASE 3AL — FARMER / SUPPLIER PERFORMANCE
// ================================================================

class WarehouseSupplierPerformanceRow {
  final String farmerId;
  final String farmName;
  final String farmerName;
  final String phone;
  final String parish;
  final String verificationStatus;
  final String sourcingStatus;
  final double? targetSharePercent;
  final String adminNotes;
  final int distinctProducts;
  final int activeSupplyLines;
  final int confirmedSupplyLines;
  final int completedBatches;
  final int cancelledBatches;
  final int rejectedBatches;
  final double? fillRatePct;
  final double? acceptanceRatePct;
  final double? onTimeRatePct;
  final double? completionRatePct;
  final double? supplierScore;
  final String performanceBand;
  final DateTime? lastCompletedAt;

  const WarehouseSupplierPerformanceRow({
    required this.farmerId,
    required this.farmName,
    required this.farmerName,
    required this.phone,
    required this.parish,
    required this.verificationStatus,
    required this.sourcingStatus,
    required this.targetSharePercent,
    required this.adminNotes,
    required this.distinctProducts,
    required this.activeSupplyLines,
    required this.confirmedSupplyLines,
    required this.completedBatches,
    required this.cancelledBatches,
    required this.rejectedBatches,
    required this.fillRatePct,
    required this.acceptanceRatePct,
    required this.onTimeRatePct,
    required this.completionRatePct,
    required this.supplierScore,
    required this.performanceBand,
    this.lastCompletedAt,
  });

  factory WarehouseSupplierPerformanceRow.fromSupabase(
    Map<String, dynamic> data,
  ) {
    double? optionalDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    int whole(dynamic value) {
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    return WarehouseSupplierPerformanceRow(
      farmerId: (data['farmer_id'] ?? '').toString(),
      farmName: (data['farm_name'] ?? 'Farm').toString().trim(),
      farmerName: (data['farmer_name'] ?? 'Farmer').toString().trim(),
      phone: (data['phone'] ?? '').toString().trim(),
      parish: (data['parish'] ?? '').toString().trim(),
      verificationStatus: (data['verification_status'] ?? 'pending')
          .toString()
          .trim()
          .toLowerCase(),
      sourcingStatus:
          (data['sourcing_status'] ?? 'active').toString().trim().toLowerCase(),
      targetSharePercent: optionalDouble(data['target_share_percent']),
      adminNotes: (data['admin_notes'] ?? '').toString().trim(),
      distinctProducts: whole(data['distinct_products']),
      activeSupplyLines: whole(data['active_supply_lines']),
      confirmedSupplyLines: whole(data['confirmed_supply_lines']),
      completedBatches: whole(data['completed_batches']),
      cancelledBatches: whole(data['cancelled_batches']),
      rejectedBatches: whole(data['rejected_batches']),
      fillRatePct: optionalDouble(data['fill_rate_pct']),
      acceptanceRatePct: optionalDouble(data['acceptance_rate_pct']),
      onTimeRatePct: optionalDouble(data['on_time_rate_pct']),
      completionRatePct: optionalDouble(data['completion_rate_pct']),
      supplierScore: optionalDouble(data['supplier_score']),
      performanceBand:
          (data['performance_band'] ?? 'new').toString().trim().toLowerCase(),
      lastCompletedAt:
          DateTime.tryParse((data['last_completed_at'] ?? '').toString()),
    );
  }

  bool get isPreferred => sourcingStatus == 'preferred';
  bool get isPaused => sourcingStatus == 'paused';
  bool get isRisk => performanceBand == 'risk';
  bool get isNew => performanceBand == 'new';

  String get sourcingLabel {
    switch (sourcingStatus) {
      case 'preferred':
        return 'Preferred';
      case 'watch':
        return 'Watch';
      case 'paused':
        return 'Paused';
      default:
        return 'Active';
    }
  }

  String get performanceLabel {
    switch (performanceBand) {
      case 'excellent':
        return 'Excellent';
      case 'strong':
        return 'Strong';
      case 'watch':
        return 'Watch';
      case 'risk':
        return 'At Risk';
      default:
        return 'New';
    }
  }
}

Future<List<WarehouseSupplierPerformanceRow>>
    fetchWarehouseSupplierPerformance() async {
  await requireAdminAccess();
  final response = await supabase.rpc(
    'admin_list_farmer_supplier_performance',
  );
  return (response as List)
      .map(
        (row) => WarehouseSupplierPerformanceRow.fromSupabase(
          Map<String, dynamic>.from(row as Map),
        ),
      )
      .toList();
}

Future<void> updateWarehouseSupplierSetting({
  required WarehouseSupplierPerformanceRow supplier,
  required String sourcingStatus,
  double? targetSharePercent,
  String adminNotes = '',
}) async {
  await requireAdminAccess();
  await supabase.rpc(
    'admin_update_farmer_supplier_setting',
    params: {
      'p_farmer_id': supplier.farmerId,
      'p_sourcing_status': sourcingStatus.trim().toLowerCase(),
      'p_target_share_percent': targetSharePercent,
      'p_admin_notes': adminNotes.trim(),
    },
  );
}

String _supplierPerfPercent(double? value) {
  if (value == null) return '—';
  return '${value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1)}%';
}

String _supplierPerfDate(DateTime? date) {
  if (date == null) return 'No completed receipt yet';
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
  final local = date.toLocal();
  return '${local.day} ${months[local.month - 1]} ${local.year}';
}

class WarehouseSupplierPerformanceScreen extends StatefulWidget {
  const WarehouseSupplierPerformanceScreen({super.key});

  @override
  State<WarehouseSupplierPerformanceScreen> createState() =>
      _WarehouseSupplierPerformanceScreenState();
}

class _WarehouseSupplierPerformanceScreenState
    extends State<WarehouseSupplierPerformanceScreen> {
  late Future<List<WarehouseSupplierPerformanceRow>> _future;
  String _filter = 'all';
  String _search = '';

  @override
  void initState() {
    super.initState();
    _future = fetchWarehouseSupplierPerformance();
  }

  Future<void> _refresh() async {
    final next = fetchWarehouseSupplierPerformance();
    setState(() => _future = next);
    await next;
  }

  Color _bandColor(WarehouseSupplierPerformanceRow row) {
    if (row.isPaused || row.isRisk) return FarmColors.danger;
    if (row.performanceBand == 'watch' || row.sourcingStatus == 'watch') {
      return FarmColors.warning;
    }
    if (row.isPreferred || row.performanceBand == 'excellent') {
      return FarmColors.success;
    }
    return FarmColors.primary;
  }

  Future<void> _editSupplier(WarehouseSupplierPerformanceRow supplier) async {
    String status = supplier.sourcingStatus;
    final target = TextEditingController(
      text: supplier.targetSharePercent == null
          ? ''
          : supplier.targetSharePercent!.toStringAsFixed(
              supplier.targetSharePercent ==
                      supplier.targetSharePercent!.roundToDouble()
                  ? 0
                  : 1,
            ),
    );
    final notes = TextEditingController(text: supplier.adminNotes);

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
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
                      supplier.farmName,
                      style: const TextStyle(
                        color: FarmColors.ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Supplier sourcing control • ${supplier.farmerName}',
                      style: const TextStyle(
                        color: FarmColors.mutedText,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: status,
                      decoration: const InputDecoration(
                        labelText: 'Sourcing status',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'preferred',
                          child: Text('Preferred'),
                        ),
                        DropdownMenuItem(
                          value: 'active',
                          child: Text('Active'),
                        ),
                        DropdownMenuItem(
                          value: 'watch',
                          child: Text('Watch'),
                        ),
                        DropdownMenuItem(
                          value: 'paused',
                          child: Text('Paused'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setSheetState(() => status = value);
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: target,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Target sourcing share % (optional)',
                        helperText:
                            'Planning target only; it does not reserve farmer supply.',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: notes,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Admin sourcing notes',
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.of(sheetContext).pop(true),
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Save Supplier Setting'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (saved != true) {
      target.dispose();
      notes.dispose();
      return;
    }

    final targetText = target.text.trim();
    final targetValue = targetText.isEmpty
        ? null
        : double.tryParse(targetText.replaceAll(',', ''));

    if (targetText.isNotEmpty && targetValue == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a valid target percentage.')),
        );
      }
      target.dispose();
      notes.dispose();
      return;
    }

    try {
      await updateWarehouseSupplierSetting(
        supplier: supplier,
        sourcingStatus: status,
        targetSharePercent: targetValue,
        adminNotes: notes.text,
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
      width: 124,
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
      appBar: const _WarehouseAppBar(title: 'Supplier Performance'),
      body: FutureBuilder<List<WarehouseSupplierPerformanceRow>>(
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
              snapshot.data ?? const <WarehouseSupplierPerformanceRow>[];
          final search = _search.trim().toLowerCase();
          final filtered = rows.where((row) {
            final matchesSearch = search.isEmpty ||
                row.farmName.toLowerCase().contains(search) ||
                row.farmerName.toLowerCase().contains(search) ||
                row.parish.toLowerCase().contains(search);
            if (!matchesSearch) return false;
            switch (_filter) {
              case 'preferred':
                return row.isPreferred;
              case 'watch':
                return row.sourcingStatus == 'watch' ||
                    row.performanceBand == 'watch';
              case 'risk':
                return row.isRisk || row.isPaused;
              case 'new':
                return row.isNew;
              default:
                return true;
            }
          }).toList();

          final preferred = rows.where((row) => row.isPreferred).length;
          final risk = rows.where((row) => row.isRisk || row.isPaused).length;
          final scored =
              rows.where((row) => row.supplierScore != null).toList();
          final avgScore = scored.isEmpty
              ? null
              : scored.fold<double>(
                    0,
                    (sum, row) => sum + (row.supplierScore ?? 0),
                  ) /
                  scored.length;

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
                        Icons.agriculture_outlined,
                        color: FarmColors.primary,
                        size: 30,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Farmer / Supplier Performance',
                              style: TextStyle(
                                color: FarmColors.ink,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Score suppliers from actual receiving performance without mixing incompatible units. Fill, acceptance and on-time rates are calculated per receiving batch.',
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
                      _metric('Suppliers', '${rows.length}'),
                      const SizedBox(width: 8),
                      _metric('Preferred', '$preferred'),
                      const SizedBox(width: 8),
                      _metric('Risk / Paused', '$risk'),
                      const SizedBox(width: 8),
                      _metric(
                        'Average Score',
                        avgScore == null ? '—' : avgScore.toStringAsFixed(1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (value) => setState(() => _search = value),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search_rounded),
                    hintText: 'Search farm, farmer or parish',
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final entry in const <String, String>{
                        'all': 'All',
                        'preferred': 'Preferred',
                        'watch': 'Watch',
                        'risk': 'Risk',
                        'new': 'New',
                      }.entries) ...[
                        ChoiceChip(
                          label: Text(entry.value),
                          selected: _filter == entry.key,
                          onSelected: (_) =>
                              setState(() => _filter = entry.key),
                        ),
                        const SizedBox(width: 7),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                if (filtered.isEmpty)
                  const FarmEmptyState(
                    icon: Icons.agriculture_outlined,
                    title: 'No suppliers match this view',
                    message:
                        'Supplier performance appears as farmer receiving history is completed.',
                  )
                else
                  ...filtered.map((row) {
                    final color = _bandColor(row);
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
                                        row.farmName,
                                        style: const TextStyle(
                                          color: FarmColors.ink,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${row.farmerName}${row.parish.isEmpty ? '' : ' • ${row.parish}'}',
                                        style: const TextStyle(
                                          color: FarmColors.mutedText,
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(.10),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    row.supplierScore == null
                                        ? row.performanceLabel.toUpperCase()
                                        : '${row.supplierScore!.toStringAsFixed(1)} • ${row.performanceLabel.toUpperCase()}',
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
                            Wrap(
                              spacing: 7,
                              runSpacing: 7,
                              children: [
                                _SupplierPerfChip(
                                  label: 'Fill',
                                  value: _supplierPerfPercent(row.fillRatePct),
                                ),
                                _SupplierPerfChip(
                                  label: 'Accepted',
                                  value: _supplierPerfPercent(
                                      row.acceptanceRatePct),
                                ),
                                _SupplierPerfChip(
                                  label: 'On time',
                                  value:
                                      _supplierPerfPercent(row.onTimeRatePct),
                                ),
                                _SupplierPerfChip(
                                  label: 'Completion',
                                  value: _supplierPerfPercent(
                                      row.completionRatePct),
                                ),
                                _SupplierPerfChip(
                                  label: 'Completed',
                                  value: '${row.completedBatches}',
                                ),
                                _SupplierPerfChip(
                                  label: 'Rejected batches',
                                  value: '${row.rejectedBatches}',
                                ),
                                _SupplierPerfChip(
                                  label: 'Active crops',
                                  value: '${row.distinctProducts}',
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${row.sourcingLabel}${row.targetSharePercent == null ? '' : ' • target ${_supplierPerfPercent(row.targetSharePercent)}'}\nLast completed: ${_supplierPerfDate(row.lastCompletedAt)}',
                                    style: const TextStyle(
                                      color: FarmColors.mutedText,
                                      fontSize: 9.5,
                                      height: 1.35,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () => _editSupplier(row),
                                  icon:
                                      const Icon(Icons.tune_rounded, size: 17),
                                  label: const Text('Manage'),
                                ),
                              ],
                            ),
                            if (row.adminNotes.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                row.adminNotes,
                                style: const TextStyle(
                                  color: FarmColors.mutedText,
                                  fontSize: 9.5,
                                  fontStyle: FontStyle.italic,
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
    );
  }
}

class _SupplierPerfChip extends StatelessWidget {
  final String label;
  final String value;

  const _SupplierPerfChip({required this.label, required this.value});

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
