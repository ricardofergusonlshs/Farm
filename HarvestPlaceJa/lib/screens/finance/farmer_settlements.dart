part of harvest_place_app;

// ================================================================
// THE HARVEST PLACE JA
// PHASE 4B — FARMER / SUPPLIER SETTLEMENTS
//
// Settlement batches group the existing farmer_payouts records. They do not
// create duplicate farmer payables.
// ================================================================

class FarmerSettlementCandidate {
  final String farmerId;
  final String farmerName;
  final String farmName;
  final String parish;
  final int payoutCount;
  final double totalAmount;
  final DateTime? oldestPayoutAt;
  final DateTime? newestPayoutAt;

  const FarmerSettlementCandidate({required this.farmerId, required this.farmerName, required this.farmName, required this.parish, required this.payoutCount, required this.totalAmount, this.oldestPayoutAt, this.newestPayoutAt});

  factory FarmerSettlementCandidate.fromSupabase(Map<String, dynamic> data) {
    double n(dynamic value) => value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '') ?? 0;
    int i(dynamic value) => value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;
    return FarmerSettlementCandidate(
      farmerId: (data['farmer_id'] ?? '').toString(),
      farmerName: (data['farmer_name'] ?? 'Farmer').toString().trim(),
      farmName: (data['farm_name'] ?? '').toString().trim(),
      parish: (data['parish'] ?? '').toString().trim(),
      payoutCount: i(data['payout_count']),
      totalAmount: n(data['total_amount']),
      oldestPayoutAt: DateTime.tryParse((data['oldest_payout_at'] ?? '').toString()),
      newestPayoutAt: DateTime.tryParse((data['newest_payout_at'] ?? '').toString()),
    );
  }
}

class FarmerSettlementBatch {
  final String id;
  final String settlementNumber;
  final String farmerId;
  final String farmerName;
  final String farmName;
  final String status;
  final int payoutCount;
  final double totalAmount;
  final String payoutMethod;
  final String payoutReference;
  final String notes;
  final DateTime? createdAt;
  final DateTime? approvedAt;
  final DateTime? paidAt;

  const FarmerSettlementBatch({required this.id, required this.settlementNumber, required this.farmerId, required this.farmerName, required this.farmName, required this.status, required this.payoutCount, required this.totalAmount, required this.payoutMethod, required this.payoutReference, required this.notes, this.createdAt, this.approvedAt, this.paidAt});

  factory FarmerSettlementBatch.fromSupabase(Map<String, dynamic> data) {
    double n(dynamic value) => value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '') ?? 0;
    int i(dynamic value) => value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;
    return FarmerSettlementBatch(
      id: (data['settlement_id'] ?? data['id'] ?? '').toString(),
      settlementNumber: (data['settlement_number'] ?? '').toString(),
      farmerId: (data['farmer_id'] ?? '').toString(),
      farmerName: (data['farmer_name'] ?? 'Farmer').toString().trim(),
      farmName: (data['farm_name'] ?? '').toString().trim(),
      status: (data['status'] ?? 'draft').toString().trim().toLowerCase(),
      payoutCount: i(data['payout_count']),
      totalAmount: n(data['total_amount']),
      payoutMethod: (data['payout_method'] ?? '').toString().trim(),
      payoutReference: (data['payout_reference'] ?? '').toString().trim(),
      notes: (data['notes'] ?? '').toString().trim(),
      createdAt: DateTime.tryParse((data['created_at'] ?? '').toString()),
      approvedAt: DateTime.tryParse((data['approved_at'] ?? '').toString()),
      paidAt: DateTime.tryParse((data['paid_at'] ?? '').toString()),
    );
  }

  bool get isDraft => status == 'draft';
  bool get isApproved => status == 'approved';
  bool get isPaid => status == 'paid';
  bool get isCancelled => status == 'cancelled';
}

Future<List<FarmerSettlementCandidate>> fetchFarmerSettlementCandidates() async {
  await requireAdminAccess();
  final response = await supabase.rpc('admin_list_farmer_settlement_candidates');
  return (response as List).map((row) => FarmerSettlementCandidate.fromSupabase(Map<String, dynamic>.from(row as Map))).toList();
}

Future<List<FarmerSettlementBatch>> fetchFarmerSettlementBatches() async {
  await requireAdminAccess();
  final response = await supabase.rpc('admin_list_farmer_settlement_batches', params: {'p_limit': 150});
  return (response as List).map((row) => FarmerSettlementBatch.fromSupabase(Map<String, dynamic>.from(row as Map))).toList();
}

Future<String> createFarmerSettlementBatch(FarmerSettlementCandidate farmer, {String notes = ''}) async {
  await requireAdminAccess();
  final response = await supabase.rpc('admin_create_farmer_settlement_batch', params: {'p_farmer_id': farmer.farmerId, 'p_notes': notes.trim()});
  return response?.toString() ?? '';
}

Future<void> approveFarmerSettlementBatch(FarmerSettlementBatch batch) async {
  await requireAdminAccess();
  await supabase.rpc('admin_approve_farmer_settlement_batch', params: {'p_settlement_id': batch.id});
}

Future<void> markFarmerSettlementPaid(FarmerSettlementBatch batch, {required String paymentMethod, required String reference, String notes = ''}) async {
  await requireAdminAccess();
  await supabase.rpc('admin_mark_farmer_settlement_paid', params: {'p_settlement_id': batch.id, 'p_payment_method': paymentMethod.trim().toLowerCase(), 'p_reference': reference.trim(), 'p_notes': notes.trim()});
}

Future<void> cancelFarmerSettlementBatch(FarmerSettlementBatch batch, {String reason = ''}) async {
  await requireAdminAccess();
  await supabase.rpc('admin_cancel_farmer_settlement_batch', params: {'p_settlement_id': batch.id, 'p_reason': reason.trim()});
}

class FarmerSettlementsScreen extends StatefulWidget {
  const FarmerSettlementsScreen({super.key});
  @override
  State<FarmerSettlementsScreen> createState() => _FarmerSettlementsScreenState();
}

class _FarmerSettlementsScreenState extends State<FarmerSettlementsScreen> {
  late Future<List<dynamic>> _future;
  @override
  void initState() { super.initState(); _future = _load(); }
  Future<List<dynamic>> _load() => Future.wait<dynamic>([fetchFarmerSettlementCandidates(), fetchFarmerSettlementBatches()]);
  Future<void> _refresh() async { final next = _load(); setState(() => _future = next); await next; }

  Future<String?> _noteDialog(String title, {String label = 'Note (optional)'}) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(context: context, builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: TextField(controller: controller, maxLines: 3, decoration: InputDecoration(labelText: label)),
      actions: [TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')), ElevatedButton(onPressed: () => Navigator.of(dialogContext).pop(controller.text), child: const Text('Confirm'))],
    ));
    controller.dispose();
    return result;
  }

  Future<void> _prepare(FarmerSettlementCandidate farmer) async {
    final note = await _noteDialog('Prepare settlement for ${farmer.farmerName}?');
    if (note == null) return;
    try {
      await createFarmerSettlementBatch(farmer, notes: note);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Farmer settlement prepared.')));
      await _refresh();
    } catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyAppError(error)))); }
  }

  Future<void> _approve(FarmerSettlementBatch batch) async {
    try { await approveFarmerSettlementBatch(batch); await _refresh(); }
    catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyAppError(error)))); }
  }

  Future<void> _pay(FarmerSettlementBatch batch) async {
    final method = TextEditingController(text: 'bank_transfer');
    final reference = TextEditingController();
    final note = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
      title: Text('Mark ${batch.settlementNumber} paid'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: method, decoration: const InputDecoration(labelText: 'Payment method')),
        const SizedBox(height: 10),
        TextField(controller: reference, decoration: const InputDecoration(labelText: 'Transaction / transfer reference')),
        const SizedBox(height: 10),
        TextField(controller: note, maxLines: 2, decoration: const InputDecoration(labelText: 'Note (optional)')),
      ])),
      actions: [TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')), ElevatedButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Mark Paid'))],
    ));
    if (ok == true) {
      try {
        await markFarmerSettlementPaid(batch, paymentMethod: method.text, reference: reference.text, notes: note.text);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settlement marked paid and farmer payouts released.')));
        await _refresh();
      } catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyAppError(error)))); }
    }
    method.dispose(); reference.dispose(); note.dispose();
  }

  Future<void> _cancel(FarmerSettlementBatch batch) async {
    final reason = await _noteDialog('Cancel ${batch.settlementNumber}?', label: 'Reason');
    if (reason == null) return;
    try { await cancelFarmerSettlementBatch(batch, reason: reason); await _refresh(); }
    catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyAppError(error)))); }
  }

  Color _statusColor(FarmerSettlementBatch batch) {
    if (batch.isPaid) return FarmColors.success;
    if (batch.isCancelled) return FarmColors.danger;
    if (batch.isApproved) return FarmColors.primary;
    return FarmColors.warning;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: AppBar(title: const Text('Farmer Settlements')),
      body: FutureBuilder<List<dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && snapshot.data == null) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError && snapshot.data == null) return Center(child: Text(friendlyAppError(snapshot.error!)));
          final data = snapshot.data ?? const <dynamic>[];
          final candidates = data.isNotEmpty ? data[0] as List<FarmerSettlementCandidate> : <FarmerSettlementCandidate>[];
          final batches = data.length > 1 ? data[1] as List<FarmerSettlementBatch> : <FarmerSettlementBatch>[];
          final pendingTotal = candidates.fold<double>(0, (sum, item) => sum + item.totalAmount);
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
              children: [
                FarmCard(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Supplier Payables', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  const Text('Settlement batches group existing pending farmer payout records. Preparing a settlement holds those payout rows; paying the settlement releases them together.', style: TextStyle(color: FarmColors.mutedText, fontSize: 10.5, height: 1.35, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Text('${formatJmd(pendingTotal)} ready to settle • ${candidates.length} farmer(s)', style: const TextStyle(color: FarmColors.primary, fontWeight: FontWeight.w900)),
                ])),
                const SizedBox(height: 16),
                const Text('Ready to Settle', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                if (candidates.isEmpty)
                  const FarmEmptyState(icon: Icons.agriculture_outlined, title: 'No pending farmer payables', message: 'Completed receiving payouts will appear here when they are ready for settlement.')
                else
                  ...candidates.map((farmer) => Padding(padding: const EdgeInsets.only(bottom: 10), child: FarmCard(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${farmer.farmName.isEmpty ? farmer.farmerName : farmer.farmName} • ${farmer.farmerName}', style: const TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text('${farmer.payoutCount} payout(s) • ${formatJmd(farmer.totalAmount)}${farmer.parish.isEmpty ? '' : ' • ${farmer.parish}'}', style: const TextStyle(color: FarmColors.mutedText, fontWeight: FontWeight.w700, fontSize: 10.5)),
                    const SizedBox(height: 9),
                    ElevatedButton.icon(onPressed: () => _prepare(farmer), icon: const Icon(Icons.playlist_add_check_rounded, size: 17), label: const Text('Prepare Settlement')),
                  ])))),
                const SizedBox(height: 18),
                const Text('Settlement Batches', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                if (batches.isEmpty)
                  const FarmCard(child: Text('No settlement batches yet.'))
                else
                  ...batches.map((batch) {
                    final color = _statusColor(batch);
                    return Padding(padding: const EdgeInsets.only(bottom: 10), child: FarmCard(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [Expanded(child: Text('${batch.settlementNumber} • ${batch.farmName.isEmpty ? batch.farmerName : batch.farmName}', style: const TextStyle(fontWeight: FontWeight.w900))), Text(batch.status.toUpperCase(), style: TextStyle(color: color, fontSize: 9.5, fontWeight: FontWeight.w900))]),
                      const SizedBox(height: 5),
                      Text('${batch.payoutCount} payout(s) • ${formatJmd(batch.totalAmount)}', style: const TextStyle(color: FarmColors.mutedText, fontWeight: FontWeight.w700)),
                      if (batch.payoutReference.isNotEmpty) Text('Reference: ${batch.payoutReference}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
                      if (batch.isDraft || batch.isApproved) ...[
                        const SizedBox(height: 9),
                        Wrap(spacing: 7, runSpacing: 7, children: [
                          if (batch.isDraft) ElevatedButton(onPressed: () => _approve(batch), child: const Text('Approve')),
                          if (batch.isApproved) ElevatedButton.icon(onPressed: () => _pay(batch), icon: const Icon(Icons.payments_outlined, size: 17), label: const Text('Mark Paid')),
                          OutlinedButton(onPressed: () => _cancel(batch), child: const Text('Cancel')),
                        ]),
                      ],
                    ])));
                  }),
              ],
            ),
          );
        },
      ),
    );
  }
}
