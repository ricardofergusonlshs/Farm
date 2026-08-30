part of harvest_place_app;

// ================================================================
// THE HARVEST PLACE JA
// PHASE 3AK — END-TO-END LOT TRACEABILITY
// ================================================================

class WarehouseLotTraceRow {
  final String dispatchId;
  final String requestId;
  final String fulfillmentId;
  final String fulfillmentItemId;
  final String businessName;
  final String deliveryParish;
  final String dispatchStatus;
  final DateTime? deliveredAt;
  final String recipientName;
  final String proofReviewStatus;
  final String productName;
  final String unit;
  final double packedQuantity;
  final String lotId;
  final String lotCode;
  final String farmName;
  final String farmerName;
  final String farmerParish;
  final DateTime? receivedAt;
  final DateTime? bestBeforeDate;
  final double issuedQuantity;
  final double returnedQuantity;
  final double restockedQuantity;
  final double wastedReturnQuantity;
  final String lotStatus;

  const WarehouseLotTraceRow({
    required this.dispatchId,
    required this.requestId,
    required this.fulfillmentId,
    required this.fulfillmentItemId,
    required this.businessName,
    required this.deliveryParish,
    required this.dispatchStatus,
    required this.deliveredAt,
    required this.recipientName,
    required this.proofReviewStatus,
    required this.productName,
    required this.unit,
    required this.packedQuantity,
    required this.lotId,
    required this.lotCode,
    required this.farmName,
    required this.farmerName,
    required this.farmerParish,
    required this.receivedAt,
    required this.bestBeforeDate,
    required this.issuedQuantity,
    required this.returnedQuantity,
    required this.restockedQuantity,
    required this.wastedReturnQuantity,
    required this.lotStatus,
  });

  factory WarehouseLotTraceRow.fromSupabase(Map<String, dynamic> data) {
    double amount(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    return WarehouseLotTraceRow(
      dispatchId: (data['dispatch_id'] ?? '').toString(),
      requestId: (data['request_id'] ?? '').toString(),
      fulfillmentId: (data['fulfillment_id'] ?? '').toString(),
      fulfillmentItemId: (data['fulfillment_item_id'] ?? '').toString(),
      businessName:
          (data['business_name'] ?? 'Wholesale business').toString().trim(),
      deliveryParish: (data['delivery_parish'] ?? '').toString().trim(),
      dispatchStatus:
          (data['dispatch_status'] ?? '').toString().trim().toLowerCase(),
      deliveredAt: DateTime.tryParse((data['delivered_at'] ?? '').toString()),
      recipientName: (data['recipient_name'] ?? '').toString().trim(),
      proofReviewStatus: (data['proof_review_status'] ?? 'unverified')
          .toString()
          .trim()
          .toLowerCase(),
      productName: (data['product_name'] ?? 'Produce').toString().trim(),
      unit: (data['unit'] ?? 'unit').toString().trim(),
      packedQuantity: amount(data['packed_quantity']),
      lotId: (data['lot_id'] ?? '').toString(),
      lotCode: (data['lot_code'] ?? '').toString().trim(),
      farmName: (data['farm_name'] ?? '').toString().trim(),
      farmerName: (data['farmer_name'] ?? '').toString().trim(),
      farmerParish: (data['farmer_parish'] ?? '').toString().trim(),
      receivedAt: DateTime.tryParse((data['received_at'] ?? '').toString()),
      bestBeforeDate:
          DateTime.tryParse((data['best_before_date'] ?? '').toString()),
      issuedQuantity: amount(data['issued_quantity']),
      returnedQuantity: amount(data['returned_quantity']),
      restockedQuantity: amount(data['restocked_quantity']),
      wastedReturnQuantity: amount(data['wasted_return_quantity']),
      lotStatus: (data['lot_status'] ?? '').toString().trim().toLowerCase(),
    );
  }

  String quantity(double value) {
    final text = value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
    return '$text $unit';
  }

  String get sourceLabel {
    final source = farmName.isNotEmpty
        ? farmName
        : farmerName.isNotEmpty
            ? farmerName
            : 'Unknown source';
    return '$lotCode • $source${farmerParish.isEmpty ? '' : ' • $farmerParish'}';
  }
}

class WarehouseLotRecallImpact {
  final String dispatchId;
  final String businessName;
  final String contactName;
  final String contactPhone;
  final String deliveryAddress;
  final String deliveryParish;
  final String dispatchStatus;
  final DateTime? deliveredAt;
  final String productName;
  final String unit;
  final double issuedQuantity;
  final double returnedQuantity;
  final String recipientName;

  const WarehouseLotRecallImpact({
    required this.dispatchId,
    required this.businessName,
    required this.contactName,
    required this.contactPhone,
    required this.deliveryAddress,
    required this.deliveryParish,
    required this.dispatchStatus,
    required this.deliveredAt,
    required this.productName,
    required this.unit,
    required this.issuedQuantity,
    required this.returnedQuantity,
    required this.recipientName,
  });

  factory WarehouseLotRecallImpact.fromSupabase(Map<String, dynamic> data) {
    double amount(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    return WarehouseLotRecallImpact(
      dispatchId: (data['dispatch_id'] ?? '').toString(),
      businessName:
          (data['business_name'] ?? 'Wholesale business').toString().trim(),
      contactName: (data['contact_name'] ?? '').toString().trim(),
      contactPhone: (data['contact_phone'] ?? '').toString().trim(),
      deliveryAddress: (data['delivery_address'] ?? '').toString().trim(),
      deliveryParish: (data['delivery_parish'] ?? '').toString().trim(),
      dispatchStatus:
          (data['dispatch_status'] ?? '').toString().trim().toLowerCase(),
      deliveredAt: DateTime.tryParse((data['delivered_at'] ?? '').toString()),
      productName: (data['product_name'] ?? 'Produce').toString().trim(),
      unit: (data['unit'] ?? 'unit').toString().trim(),
      issuedQuantity: amount(data['issued_quantity']),
      returnedQuantity: amount(data['returned_quantity']),
      recipientName: (data['recipient_name'] ?? '').toString().trim(),
    );
  }
}

Future<List<WarehouseLotTraceRow>> fetchWarehouseLotTraceability({
  String search = '',
}) async {
  await requireAdminAccess();
  final response = await supabase.rpc(
    'admin_list_warehouse_lot_traceability',
    params: {
      'p_search': search.trim(),
      'p_limit': 500,
    },
  );
  return (response as List)
      .map(
        (row) => WarehouseLotTraceRow.fromSupabase(
          Map<String, dynamic>.from(row as Map),
        ),
      )
      .toList();
}

Future<List<WarehouseLotRecallImpact>> fetchWarehouseLotRecallImpact(
  String lotId,
) async {
  await requireAdminAccess();
  final response = await supabase.rpc(
    'admin_list_warehouse_lot_recall_impact',
    params: {'p_lot_id': lotId},
  );
  return (response as List)
      .map(
        (row) => WarehouseLotRecallImpact.fromSupabase(
          Map<String, dynamic>.from(row as Map),
        ),
      )
      .toList();
}

String _warehouseTraceDate(DateTime? value) {
  if (value == null) return '—';
  final local = value.toLocal();
  const months = <String>[
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${local.day} ${months[local.month - 1]} ${local.year}';
}

class WarehouseTraceabilityScreen extends StatefulWidget {
  const WarehouseTraceabilityScreen({super.key});

  @override
  State<WarehouseTraceabilityScreen> createState() =>
      _WarehouseTraceabilityScreenState();
}

class _WarehouseTraceabilityScreenState
    extends State<WarehouseTraceabilityScreen> {
  final TextEditingController _search = TextEditingController();
  late Future<List<WarehouseLotTraceRow>> _future;

  @override
  void initState() {
    super.initState();
    _future = fetchWarehouseLotTraceability();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _runSearch() async {
    final next = fetchWarehouseLotTraceability(search: _search.text);
    setState(() => _future = next);
    await next;
  }

  Future<void> _showRecallImpact(WarehouseLotTraceRow row) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: MediaQuery.of(sheetContext).size.height * 0.78,
          child: FutureBuilder<List<WarehouseLotRecallImpact>>(
            future: fetchWarehouseLotRecallImpact(row.lotId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text(friendlyAppError(snapshot.error!)));
              }
              final impacts = snapshot.data ?? const <WarehouseLotRecallImpact>[];
              return ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  Text(
                    'Recall Impact • Lot ${row.lotCode}',
                    style: const TextStyle(
                      color: FarmColors.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    row.sourceLabel,
                    style: const TextStyle(
                      color: FarmColors.mutedText,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (impacts.isEmpty)
                    const FarmEmptyState(
                      icon: Icons.shield_outlined,
                      title: 'No business deliveries affected',
                      message: 'No issued wholesale deliveries were found for this lot.',
                    )
                  else
                    ...impacts.map(
                      (impact) => Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: FarmCard(
                          padding: const EdgeInsets.all(13),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                impact.businessName,
                                style: const TextStyle(
                                  color: FarmColors.ink,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${impact.productName} • ${impact.issuedQuantity.toStringAsFixed(1)} ${impact.unit} issued${impact.returnedQuantity > 0 ? ' • ${impact.returnedQuantity.toStringAsFixed(1)} returned' : ''}',
                                style: const TextStyle(
                                  color: FarmColors.mutedText,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${impact.deliveryParish}${impact.contactPhone.isEmpty ? '' : ' • ${impact.contactPhone}'} • ${_warehouseTraceDate(impact.deliveredAt)}',
                                style: const TextStyle(
                                  color: FarmColors.mutedText,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: const _WarehouseAppBar(title: 'Lot Traceability'),
      body: FutureBuilder<List<WarehouseLotTraceRow>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError && snapshot.data == null) {
            return Center(child: Text(friendlyAppError(snapshot.error!)));
          }
          final rows = snapshot.data ?? const <WarehouseLotTraceRow>[];
          final lotCount = rows.map((r) => r.lotId).toSet().length;
          final businessCount = rows.map((r) => r.businessName).toSet().length;

          return RefreshIndicator(
            onRefresh: _runSearch,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 110),
              children: [
                FarmCard(
                  padding: const EdgeInsets.all(16),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.account_tree_outlined, color: FarmColors.primary, size: 30),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Farmer-to-Customer Traceability',
                              style: TextStyle(
                                color: FarmColors.ink,
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Search by lot, farmer, farm, produce, business, parish or dispatch ID. HPJ shows which issued lot supplied each delivered wholesale line and any physical returns.',
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
                TextField(
                  controller: _search,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _runSearch(),
                  decoration: InputDecoration(
                    labelText: 'Search traceability',
                    hintText: 'Lot code, farmer, business, product…',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: IconButton(
                      onPressed: _runSearch,
                      icon: const Icon(Icons.arrow_forward_rounded),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${rows.length} trace line${rows.length == 1 ? '' : 's'} • $lotCount lot${lotCount == 1 ? '' : 's'} • $businessCount business${businessCount == 1 ? '' : 'es'}',
                  style: const TextStyle(
                    color: FarmColors.mutedText,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                if (rows.isEmpty)
                  const FarmEmptyState(
                    icon: Icons.account_tree_outlined,
                    title: 'No trace records found',
                    message: 'Traceability appears after warehouse lot reservations have been issued into packed wholesale deliveries.',
                  )
                else
                  ...rows.map(
                    (row) => Padding(
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
                                Text(
                                  row.quantity(row.issuedQuantity),
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
                              row.sourceLabel,
                              style: const TextStyle(
                                color: FarmColors.mutedText,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              '→ ${row.businessName}${row.deliveryParish.isEmpty ? '' : ' • ${row.deliveryParish}'}',
                              style: const TextStyle(
                                color: FarmColors.ink,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${row.dispatchStatus.replaceAll('_', ' ')} • delivered ${_warehouseTraceDate(row.deliveredAt)} • proof ${row.proofReviewStatus.replaceAll('_', ' ')}',
                              style: const TextStyle(
                                color: FarmColors.mutedText,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (row.returnedQuantity > 0) ...[
                              const SizedBox(height: 5),
                              Text(
                                'Returned ${row.quantity(row.returnedQuantity)} • restocked ${row.quantity(row.restockedQuantity)} • waste ${row.quantity(row.wastedReturnQuantity)}',
                                style: const TextStyle(
                                  color: FarmColors.warning,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: () => _showRecallImpact(row),
                                icon: const Icon(Icons.shield_outlined),
                                label: const Text('Recall Impact'),
                              ),
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
