part of harvest_place_app;

// ================================================================
// THE HARVEST PLACE JA
// PHASE 3AI — DELIVERY PROOF REVIEW
// ================================================================

class WarehouseDeliveryProofRecord {
  final String id;
  final String dispatchId;
  final String? runId;
  final String runNumber;
  final String? driverId;
  final String driverName;
  final String businessName;
  final String contactName;
  final String contactPhone;
  final String deliveryAddress;
  final String deliveryParish;
  final String recipientName;
  final String proofNote;
  final String proofPhotoPath;
  final double? latitude;
  final double? longitude;
  final DateTime? deliveredAt;
  final String reviewStatus;
  final String reviewNote;
  final DateTime? reviewedAt;

  const WarehouseDeliveryProofRecord({
    required this.id,
    required this.dispatchId,
    required this.runId,
    required this.runNumber,
    required this.driverId,
    required this.driverName,
    required this.businessName,
    required this.contactName,
    required this.contactPhone,
    required this.deliveryAddress,
    required this.deliveryParish,
    required this.recipientName,
    required this.proofNote,
    required this.proofPhotoPath,
    required this.latitude,
    required this.longitude,
    required this.deliveredAt,
    required this.reviewStatus,
    required this.reviewNote,
    required this.reviewedAt,
  });

  factory WarehouseDeliveryProofRecord.fromSupabase(
    Map<String, dynamic> data,
  ) {
    double? number(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    String? nullable(dynamic value) {
      final text = value?.toString().trim() ?? '';
      return text.isEmpty ? null : text;
    }

    return WarehouseDeliveryProofRecord(
      id: (data['proof_id'] ?? '').toString(),
      dispatchId: (data['dispatch_id'] ?? '').toString(),
      runId: nullable(data['run_id']),
      runNumber: (data['run_number'] ?? '').toString().trim(),
      driverId: nullable(data['driver_id']),
      driverName: (data['driver_name'] ?? '').toString().trim(),
      businessName:
          (data['business_name'] ?? 'Wholesale business').toString().trim(),
      contactName: (data['contact_name'] ?? '').toString().trim(),
      contactPhone: (data['contact_phone'] ?? '').toString().trim(),
      deliveryAddress: (data['delivery_address'] ?? '').toString().trim(),
      deliveryParish: (data['delivery_parish'] ?? '').toString().trim(),
      recipientName: (data['recipient_name'] ?? '').toString().trim(),
      proofNote: (data['proof_note'] ?? '').toString().trim(),
      proofPhotoPath: (data['proof_photo_path'] ?? '').toString().trim(),
      latitude: number(data['delivery_latitude']),
      longitude: number(data['delivery_longitude']),
      deliveredAt: DateTime.tryParse((data['delivered_at'] ?? '').toString()),
      reviewStatus:
          (data['review_status'] ?? 'unverified').toString().trim().toLowerCase(),
      reviewNote: (data['review_note'] ?? '').toString().trim(),
      reviewedAt: DateTime.tryParse((data['reviewed_at'] ?? '').toString()),
    );
  }

  bool get isVerified => reviewStatus == 'verified';
  bool get isDisputed => reviewStatus == 'disputed';
  bool get isUnverified => !isVerified && !isDisputed;

  String get statusLabel {
    if (isVerified) return 'Verified';
    if (isDisputed) return 'Disputed';
    return 'Needs Review';
  }

  String get locationLabel {
    if (latitude == null || longitude == null) return 'No GPS recorded';
    return '${latitude!.toStringAsFixed(5)}, ${longitude!.toStringAsFixed(5)}';
  }
}

Future<List<WarehouseDeliveryProofRecord>> fetchWarehouseDeliveryProofs({
  String? reviewStatus,
}) async {
  await requireAdminAccess();
  final response = await supabase.rpc(
    'admin_list_warehouse_delivery_proofs',
    params: {
      'p_review_status': reviewStatus,
      'p_limit': 300,
    },
  );
  return (response as List)
      .map(
        (row) => WarehouseDeliveryProofRecord.fromSupabase(
          Map<String, dynamic>.from(row as Map),
        ),
      )
      .toList();
}

Future<void> reviewWarehouseDeliveryProof({
  required WarehouseDeliveryProofRecord proof,
  required String status,
  String note = '',
}) async {
  await requireAdminAccess();
  await supabase.rpc(
    'admin_review_warehouse_delivery_proof',
    params: {
      'p_proof_id': proof.id,
      'p_review_status': status,
      'p_review_note': note.trim(),
    },
  );
}

String _warehouseProofDateTime(DateTime? value) {
  if (value == null) return 'Unknown time';
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
  return '${local.day} ${months[local.month - 1]} ${local.year} • $hour:$minute $period';
}

class WarehouseDeliveryProofScreen extends StatefulWidget {
  const WarehouseDeliveryProofScreen({super.key});

  @override
  State<WarehouseDeliveryProofScreen> createState() =>
      _WarehouseDeliveryProofScreenState();
}

class _WarehouseDeliveryProofScreenState
    extends State<WarehouseDeliveryProofScreen> {
  late Future<List<WarehouseDeliveryProofRecord>> _future;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<WarehouseDeliveryProofRecord>> _load() {
    return fetchWarehouseDeliveryProofs(
      reviewStatus: _filter == 'all' ? null : _filter,
    );
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() => _future = next);
    await next;
  }

  Future<void> _review(
    WarehouseDeliveryProofRecord proof,
    String status,
  ) async {
    final note = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(status == 'verified' ? 'Verify delivery proof?' : 'Dispute delivery proof?'),
        content: TextField(
          controller: note,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: status == 'verified'
                ? 'Verification note (optional)'
                : 'Reason for dispute *',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (status == 'disputed' && note.text.trim().isEmpty) return;
              Navigator.of(dialogContext).pop(true);
            },
            child: Text(status == 'verified' ? 'Verify' : 'Dispute'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      note.dispose();
      return;
    }

    try {
      await reviewWarehouseDeliveryProof(
        proof: proof,
        status: status,
        note: note.text,
      );
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(status == 'verified' ? 'Delivery proof verified.' : 'Delivery proof marked disputed.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyAppError(error))),
      );
    } finally {
      note.dispose();
    }
  }

  Color _statusColor(WarehouseDeliveryProofRecord proof) {
    if (proof.isVerified) return FarmColors.success;
    if (proof.isDisputed) return FarmColors.danger;
    return FarmColors.warning;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: const _WarehouseAppBar(title: 'Delivery Proof'),
      body: FutureBuilder<List<WarehouseDeliveryProofRecord>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError && snapshot.data == null) {
            return Center(child: Text(friendlyAppError(snapshot.error!)));
          }

          final proofs = snapshot.data ?? const <WarehouseDeliveryProofRecord>[];
          final verified = proofs.where((p) => p.isVerified).length;
          final disputed = proofs.where((p) => p.isDisputed).length;
          final pending = proofs.where((p) => p.isUnverified).length;

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
                      Icon(Icons.verified_user_outlined, color: FarmColors.primary, size: 30),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Delivery Proof Review',
                              style: TextStyle(
                                color: FarmColors.ink,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Review the recipient, driver photo, GPS and delivery notes already captured by the HPJ driver workflow.',
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
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _WarehouseProofMetric(label: 'Needs Review', value: '$pending'),
                    _WarehouseProofMetric(label: 'Verified', value: '$verified'),
                    _WarehouseProofMetric(label: 'Disputed', value: '$disputed'),
                  ],
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final filter in const <String>['all', 'unverified', 'verified', 'disputed']) ...[
                        ChoiceChip(
                          label: Text(
                            filter == 'all'
                                ? 'All'
                                : filter == 'unverified'
                                    ? 'Needs Review'
                                    : filter[0].toUpperCase() + filter.substring(1),
                          ),
                          selected: _filter == filter,
                          onSelected: (_) {
                            setState(() {
                              _filter = filter;
                              _future = _load();
                            });
                          },
                        ),
                        const SizedBox(width: 7),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                if (proofs.isEmpty)
                  const FarmEmptyState(
                    icon: Icons.verified_outlined,
                    title: 'No delivery proofs here',
                    message: 'Completed HPJ wholesale deliveries will appear here automatically.',
                  )
                else
                  ...proofs.map((proof) {
                    final color = _statusColor(proof);
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
                                    proof.businessName,
                                    style: const TextStyle(
                                      color: FarmColors.ink,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.10),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    proof.statusLabel.toUpperCase(),
                                    style: TextStyle(
                                      color: color,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${_warehouseProofDateTime(proof.deliveredAt)}${proof.runNumber.isEmpty ? '' : ' • ${proof.runNumber}'}',
                              style: const TextStyle(
                                color: FarmColors.mutedText,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 9),
                            _WarehouseProofLine(label: 'Recipient', value: proof.recipientName.isEmpty ? 'Not recorded' : proof.recipientName),
                            _WarehouseProofLine(label: 'Driver', value: proof.driverName.isEmpty ? 'Assigned driver' : proof.driverName),
                            _WarehouseProofLine(label: 'GPS', value: proof.locationLabel),
                            _WarehouseProofLine(label: 'Photo', value: proof.proofPhotoPath.isEmpty ? 'No photo recorded' : 'Proof photo recorded'),
                            if (proof.proofNote.isNotEmpty)
                              _WarehouseProofLine(label: 'Proof note', value: proof.proofNote),
                            if (proof.reviewNote.isNotEmpty)
                              _WarehouseProofLine(label: 'Review note', value: proof.reviewNote),
                            if (proof.proofPhotoPath.startsWith('http')) ...[
                              const SizedBox(height: 10),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  proof.proofPhotoPath,
                                  height: 150,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    height: 80,
                                    alignment: Alignment.center,
                                    color: FarmColors.cardSoft,
                                    child: const Text('Proof photo could not be loaded.'),
                                  ),
                                ),
                              ),
                            ],
                            if (!proof.isVerified) ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _review(proof, 'verified'),
                                      icon: const Icon(Icons.verified_outlined),
                                      label: const Text('Verify'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _review(proof, 'disputed'),
                                      icon: const Icon(Icons.report_problem_outlined),
                                      label: const Text('Dispute'),
                                    ),
                                  ),
                                ],
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

class _WarehouseProofMetric extends StatelessWidget {
  final String label;
  final String value;

  const _WarehouseProofMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      padding: const EdgeInsets.all(12),
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
}

class _WarehouseProofLine extends StatelessWidget {
  final String label;
  final String value;

  const _WarehouseProofLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: FarmColors.mutedText,
          fontSize: 10.5,
          height: 1.3,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
