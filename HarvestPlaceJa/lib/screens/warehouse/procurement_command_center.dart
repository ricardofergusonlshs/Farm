part of harvest_place_app;

// ================================================================
// THE HARVEST PLACE JA
// PHASE 3W — PROCUREMENT COMMAND CENTER
//
// Compares approved wholesale demand, reserved future demand,
// HPJ-confirmed farmer supply, and available warehouse inventory.
// Quantities are compared only when product name AND unit match.
// ================================================================

class WarehouseProcurementRow {
  final String productName;
  final String unit;
  final double planningDemand;
  final double reservedDemand;
  final double approvedOrderDemand;
  final double warehouseAvailable;
  final double confirmedFarmSupply;
  final double allocatedConfirmedSupply;
  final double unallocatedConfirmedSupply;
  final double requiredQuantity;
  final double trustedSupply;
  final double balanceQuantity;
  final String coverageStatus;

  const WarehouseProcurementRow({
    required this.productName,
    required this.unit,
    required this.planningDemand,
    required this.reservedDemand,
    required this.approvedOrderDemand,
    required this.warehouseAvailable,
    required this.confirmedFarmSupply,
    required this.allocatedConfirmedSupply,
    required this.unallocatedConfirmedSupply,
    required this.requiredQuantity,
    required this.trustedSupply,
    required this.balanceQuantity,
    required this.coverageStatus,
  });

  factory WarehouseProcurementRow.fromSupabase(Map<String, dynamic> data) {
    double amount(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    return WarehouseProcurementRow(
      productName: (data['product_name'] ?? 'Produce').toString().trim(),
      unit: (data['unit'] ?? 'unit').toString().trim(),
      planningDemand: amount(data['planning_demand']),
      reservedDemand: amount(data['reserved_demand']),
      approvedOrderDemand: amount(data['approved_order_demand']),
      warehouseAvailable: amount(data['warehouse_available']),
      confirmedFarmSupply: amount(data['confirmed_farm_supply']),
      allocatedConfirmedSupply: amount(data['allocated_confirmed_supply']),
      unallocatedConfirmedSupply:
          amount(data['unallocated_confirmed_supply']),
      requiredQuantity: amount(data['required_quantity']),
      trustedSupply: amount(data['trusted_supply']),
      balanceQuantity: amount(data['balance_quantity']),
      coverageStatus:
          (data['coverage_status'] ?? 'covered').toString().trim().toLowerCase(),
    );
  }

  bool get isShortage => coverageStatus == 'shortage';
  bool get isSurplus => coverageStatus == 'surplus';
  bool get isCovered => !isShortage && !isSurplus;

  String quantity(double value) {
    final text = value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
    return '$text $unit';
  }

  String get balanceLabel {
    if (balanceQuantity < -0.001) {
      return '${quantity(balanceQuantity.abs())} short';
    }
    if (balanceQuantity > 0.001) {
      return '${quantity(balanceQuantity)} surplus';
    }
    return 'Covered';
  }
}

Future<List<WarehouseProcurementRow>> fetchWarehouseProcurementSummary() async {
  await requireAdminAccess();

  final response = await supabase.rpc(
    'admin_warehouse_procurement_summary',
  );

  return (response as List)
      .map(
        (row) => WarehouseProcurementRow.fromSupabase(
          Map<String, dynamic>.from(row),
        ),
      )
      .toList();
}


// ================================================================
// REPAIR 034 — ELITE WAREHOUSE FLOW MVP
//
// Purpose:
// One operational surface that tells staff what needs attention next,
// while preserving every existing warehouse source of truth.
//
// Core chain remains:
// receiving -> warehouse lot -> FEFO reservation -> pick -> pack ->
// dispatch.
//
// This screen coordinates existing modules; it does not duplicate them.
// ================================================================

String _warehouseMvpShortId(String value) {
  final clean = value.replaceAll('-', '').toUpperCase();
  if (clean.isEmpty) return '—';
  return clean.length <= 8 ? clean : clean.substring(0, 8);
}

String _warehouseMvpDateTime(DateTime? value) {
  if (value == null) return 'Time unavailable';

  final local = value.toLocal();
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

  final hour = local.hour == 0
      ? 12
      : local.hour > 12
          ? local.hour - 12
          : local.hour;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour >= 12 ? 'PM' : 'AM';

  return '${local.day} ${months[local.month - 1]} ${local.year} • '
      '$hour:$minute $period';
}

Future<List<T>> _warehouseMvpSafeList<T>({
  required String label,
  required Future<List<T>> Function() load,
}) async {
  try {
    return await load();
  } catch (error) {
    // Optional operational modules should not take the whole Warehouse Today
    // screen down. Their dedicated screen will still surface its own error.
    farmDebugLog(
      'Warehouse Today skipped $label snapshot: $error',
    );
    return <T>[];
  }
}

class _WarehouseMvpSnapshot {
  final List<WarehouseProcurementRow> procurement;
  final List<WholesaleReceivingBatch> receiving;
  final List<WarehouseInventoryLot> lots;
  final List<WholesaleFulfillment> fulfillments;
  final List<WholesaleDispatch> dispatches;
  final List<WarehousePickQueueRow> picks;
  final List<WarehouseExceptionItem> exceptions;

  const _WarehouseMvpSnapshot({
    required this.procurement,
    required this.receiving,
    required this.lots,
    required this.fulfillments,
    required this.dispatches,
    required this.picks,
    required this.exceptions,
  });

  int get shortageLines =>
      procurement.where((row) => row.isShortage).length;

  int get activeLots =>
      lots.where((lot) => lot.isActive && lot.quantityOnHand > 0).length;

  int get inboundActionCount => receiving.where((batch) {
        return batch.isCollected ||
            batch.isReceived ||
            batch.isInspected;
      }).length;

  int get waitingStock =>
      fulfillments.where((item) => item.isWaitingStock).length;

  int get readyToPrepare =>
      fulfillments.where((item) => item.isReadyToPrepare).length;

  int get preparing =>
      fulfillments.where((item) => item.isPreparing).length;

  int get packing =>
      fulfillments.where((item) => item.isPacking).length;

  int get readyForDispatch =>
      fulfillments.where((item) => item.isReadyForDispatch).length;

  int get pickWork => picks.where((row) {
        return row.remainingQuantity > 0.001 &&
            (row.isPending || row.isPartial);
      }).length;

  int get activeDispatches =>
      dispatches.where((item) => item.isActive).length;

  int get criticalExceptions =>
      exceptions.where((item) => item.isCritical).length;
}

Future<_WarehouseMvpSnapshot> fetchWarehouseMvpSnapshot() async {
  final values = await Future.wait<Object>([
    _warehouseMvpSafeList<WarehouseProcurementRow>(
      label: 'procurement coverage',
      load: fetchWarehouseProcurementSummary,
    ),
    _warehouseMvpSafeList<WholesaleReceivingBatch>(
      label: 'receiving',
      load: () => fetchWholesaleReceivingBatches(),
    ),
    _warehouseMvpSafeList<WarehouseInventoryLot>(
      label: 'inventory',
      load: () => fetchWarehouseInventoryLots(),
    ),
    _warehouseMvpSafeList<WholesaleFulfillment>(
      label: 'fulfilment',
      load: () => fetchAdminWholesaleFulfillments(),
    ),
    _warehouseMvpSafeList<WholesaleDispatch>(
      label: 'dispatch',
      load: () => fetchAdminWholesaleDispatches(),
    ),
    _warehouseMvpSafeList<WarehousePickQueueRow>(
      label: 'pick queue',
      load: () => fetchWarehousePickQueue(),
    ),
    _warehouseMvpSafeList<WarehouseExceptionItem>(
      label: 'exceptions',
      load: fetchWarehouseExceptions,
    ),
  ]);

  return _WarehouseMvpSnapshot(
    procurement: values[0] as List<WarehouseProcurementRow>,
    receiving: values[1] as List<WholesaleReceivingBatch>,
    lots: values[2] as List<WarehouseInventoryLot>,
    fulfillments: values[3] as List<WholesaleFulfillment>,
    dispatches: values[4] as List<WholesaleDispatch>,
    picks: values[5] as List<WarehousePickQueueRow>,
    exceptions: values[6] as List<WarehouseExceptionItem>,
  );
}

class _WarehouseNextJob {
  final int priority;
  final IconData icon;
  final Color color;
  final String eyebrow;
  final String title;
  final String detail;
  final String actionLabel;
  final Widget screen;

  const _WarehouseNextJob({
    required this.priority,
    required this.icon,
    required this.color,
    required this.eyebrow,
    required this.title,
    required this.detail,
    required this.actionLabel,
    required this.screen,
  });
}

class ProcurementCommandCenterScreen extends StatelessWidget {
  const ProcurementCommandCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: FarmColors.background,
      appBar: _WarehouseAppBar(
        title: 'Warehouse Command Center',
      ),
      body: SafeArea(
        child: WarehouseOperationsPanel(),
      ),
    );
  }
}

class _WarehouseAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final String title;

  const _WarehouseAppBar({
    required this.title,
  });

  @override
  Size get preferredSize =>
      const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
    );
  }
}

class _WarehouseWholesaleActionScreen extends StatefulWidget {
  final String title;
  final String section;
  final String receivingMode;
  final String receivingFilter;

  const _WarehouseWholesaleActionScreen({
    required this.title,
    required this.section,
    this.receivingMode = 'all',
    this.receivingFilter = 'all',
  });

  @override
  State<_WarehouseWholesaleActionScreen> createState() =>
      _WarehouseWholesaleActionScreenState();
}

class _WarehouseWholesaleActionScreenState
    extends State<_WarehouseWholesaleActionScreen> {
  int _refreshKey = 0;

  void _changed() {
    if (!mounted) return;
    setState(() => _refreshKey++);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: _WarehouseAppBar(
        title: widget.title,
      ),
      body: SafeArea(
        child: AdminWholesaleManagementTab(
          refreshKey: _refreshKey,
          onChanged: _changed,
          sections: <String>[
            widget.section,
          ],
          initialSection: widget.section,
          receivingMode: widget.receivingMode,
          receivingFilter: widget.receivingFilter,
        ),
      ),
    );
  }
}

class WarehouseOperationsPanel extends StatefulWidget {
  final bool showNavigationCards;

  const WarehouseOperationsPanel({
    super.key,
    this.showNavigationCards = true,
  });

  @override
  State<WarehouseOperationsPanel> createState() =>
      _WarehouseOperationsPanelState();
}

class _WarehouseOperationsPanelState
    extends State<WarehouseOperationsPanel> {
  late Future<_WarehouseMvpSnapshot> _future;
  String _coverageFilter = 'shortage';
  bool _recheckingStock = false;

  @override
  void initState() {
    super.initState();
    _future = fetchWarehouseMvpSnapshot();
  }

  Future<void> _refresh() async {
    final next = fetchWarehouseMvpSnapshot();

    if (mounted) {
      setState(() {
        _future = next;
      });
    }

    await next;
  }

  Future<void> _open(
    BuildContext context,
    Widget screen,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => screen,
      ),
    );

    if (mounted) {
      await _refresh();
    }
  }

  Future<void> _recheckWaitingStock() async {
    if (_recheckingStock) return;

    setState(() {
      _recheckingStock = true;
    });

    try {
      final result = await autoReleaseWaitingWarehouseOrders(
        limit: 100,
      );

      await _refresh();

      if (!mounted) return;

      final message = result.released > 0
          ? '${result.released} waiting '
              '${result.released == 1 ? 'order is' : 'orders are'} '
              'now Ready to Prepare.'
          : result.checked == 0
              ? 'There are no Waiting Stock orders to recheck.'
              : 'No additional orders could be fully covered yet.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            friendlyAppError(error),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _recheckingStock = false;
        });
      }
    }
  }

  Widget _stagePill({
    required IconData icon,
    required String label,
    required bool active,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: active
            ? FarmColors.primarySoft
            : FarmColors.cardSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: active
              ? FarmColors.primary.withOpacity(0.24)
              : FarmColors.line,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: active
                ? FarmColors.green
                : FarmColors.mutedText,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: active
                  ? FarmColors.green
                  : FarmColors.mutedText,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric({
    required String label,
    required int value,
    required IconData icon,
    Color? color,
  }) {
    final accent = color ?? FarmColors.primary;

    return Container(
      width: 126,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FarmColors.card,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: FarmColors.line,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icon,
              size: 18,
              color: accent,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            '$value',
            style: const TextStyle(
              color: FarmColors.ink,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: FarmColors.mutedText,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _coreToolCard({
    required BuildContext context,
    required double width,
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget screen,
  }) {
    return SizedBox(
      width: width,
      child: Material(
        color: FarmColors.card,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _open(
            context,
            screen,
          ),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: FarmColors.line,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 39,
                  height: 39,
                  decoration: BoxDecoration(
                    color: FarmColors.primarySoft,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    icon,
                    color: FarmColors.green,
                    size: 21,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: const TextStyle(
                    color: FarmColors.ink,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: FarmColors.mutedText,
                    fontSize: 10.5,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<_WarehouseNextJob> _nextJobs(
    _WarehouseMvpSnapshot data,
  ) {
    final jobs = <_WarehouseNextJob>[];

    if (data.exceptions.isNotEmpty) {
      final critical = data.criticalExceptions;
      jobs.add(
        _WarehouseNextJob(
          priority: 0,
          icon: Icons.warning_amber_rounded,
          color: critical > 0
              ? FarmColors.danger
              : FarmColors.warning,
          eyebrow: 'NEEDS ATTENTION',
          title: critical > 0
              ? '$critical critical warehouse '
                  '${critical == 1 ? 'issue' : 'issues'}'
              : '${data.exceptions.length} warehouse '
                  '${data.exceptions.length == 1 ? 'issue' : 'issues'}',
          detail:
              'Resolve exceptions first so normal warehouse work can keep moving.',
          actionLabel: 'Review Exceptions',
          screen: const WarehouseExceptionsScreen(),
        ),
      );
    }

    final inbound = data.receiving
        .where(
          (batch) =>
              batch.isCollected ||
              batch.isReceived ||
              batch.isInspected,
        )
        .toList()
      ..sort((a, b) {
        int rank(WholesaleReceivingBatch batch) {
          if (batch.isInspected) return 0;
          if (batch.isReceived) return 1;
          return 2;
        }

        final rankCompare =
            rank(a).compareTo(rank(b));
        if (rankCompare != 0) return rankCompare;

        final ad = a.updatedAt ??
            a.receivedAt ??
            a.collectedAt ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bd = b.updatedAt ??
            b.receivedAt ??
            b.collectedAt ??
            DateTime.fromMillisecondsSinceEpoch(0);

        return ad.compareTo(bd);
      });

    for (final batch in inbound.take(2)) {
      final next = batch.isInspected
          ? 'Complete Receiving'
          : batch.isReceived
              ? 'Inspect Quality'
              : 'Receive at Warehouse';

      final quantity = batch.isInspected
          ? batch.acceptedQuantity
          : batch.isReceived
              ? batch.receivedQuantity
              : batch.collectedQuantity;

      jobs.add(
        _WarehouseNextJob(
          priority: batch.isInspected ? 10 : 15,
          icon: batch.isInspected
              ? Icons.verified_outlined
              : Icons.warehouse_outlined,
          color: FarmColors.green,
          eyebrow: 'INBOUND • $next',
          title: '${batch.productName} • '
              '${batch.quantityLabel(quantity)}',
          detail: batch.lotCode.trim().isEmpty
              ? 'Receiving batch '
                  '#${_warehouseMvpShortId(batch.id)}'
              : 'Lot ${batch.lotCode} • '
                  '${_warehouseMvpDateTime(batch.updatedAt ?? batch.receivedAt ?? batch.collectedAt)}',
          actionLabel: next,
          screen: const _WarehouseWholesaleActionScreen(
            title: 'Warehouse Receiving',
            section: 'receiving',
            receivingMode: 'receiving',
          ),
        ),
      );
    }

    if (data.pickWork > 0) {
      jobs.add(
        _WarehouseNextJob(
          priority: 20,
          icon: Icons.playlist_add_check_circle_outlined,
          color: FarmColors.primary,
          eyebrow: 'PICK QUEUE',
          title: '${data.pickWork} '
              '${data.pickWork == 1 ? 'line needs' : 'lines need'} picking',
          detail:
              'Reserved stock is ready for FEFO warehouse picking.',
          actionLabel: 'Open Pick Queue',
          screen: const WarehousePickingScreen(),
        ),
      );
    }

    final activeFulfillments = data.fulfillments
        .where(
          (item) =>
              item.isReadyToPrepare ||
              item.isPreparing ||
              item.isPacking ||
              item.isReadyForDispatch,
        )
        .toList()
      ..sort((a, b) {
        int rank(WholesaleFulfillment item) {
          if (item.isReadyForDispatch) return 0;
          if (item.isPacking) return 1;
          if (item.isPreparing) return 2;
          return 3;
        }

        final c = rank(a).compareTo(rank(b));
        if (c != 0) return c;

        final ad = a.updatedAt ??
            a.createdAt ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bd = b.updatedAt ??
            b.createdAt ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return ad.compareTo(bd);
      });

    for (final fulfillment in activeFulfillments.take(3)) {
      final productNames = fulfillment.items
          .map((item) => item.productName)
          .where((name) => name.trim().isNotEmpty)
          .take(2)
          .join(', ');

      final action = fulfillment.isReadyForDispatch
          ? 'Create Dispatch'
          : fulfillment.isPacking
              ? 'Continue Packing'
              : fulfillment.isPreparing
                  ? 'Start Packing'
                  : 'Start Preparing';

      final targetScreen = fulfillment.isReadyForDispatch
          ? const _WarehouseWholesaleActionScreen(
              title: 'Wholesale Delivery',
              section: 'dispatch',
            )
          : const _WarehouseWholesaleActionScreen(
              title: 'Prepare & Pack',
              section: 'fulfillment',
            );

      jobs.add(
        _WarehouseNextJob(
          priority: fulfillment.isReadyForDispatch
              ? 22
              : fulfillment.isPacking
                  ? 24
                  : 26,
          icon: fulfillment.isReadyForDispatch
              ? Icons.local_shipping_outlined
              : fulfillment.isPacking
                  ? Icons.inventory_2_outlined
                  : Icons.play_arrow_outlined,
          color: fulfillment.isReadyForDispatch
              ? FarmColors.green
              : FarmColors.primary,
          eyebrow: fulfillment.statusLabel.toUpperCase(),
          title:
              'Request #${_warehouseMvpShortId(fulfillment.requestId)}',
          detail: productNames.isEmpty
              ? fulfillment.progressLabel
              : '$productNames • ${fulfillment.progressLabel}',
          actionLabel: action,
          screen: targetScreen,
        ),
      );
    }

    if (data.waitingStock > 0) {
      jobs.add(
        _WarehouseNextJob(
          priority: 40,
          icon: Icons.inventory_outlined,
          color: FarmColors.warning,
          eyebrow: 'WAITING STOCK',
          title: '${data.waitingStock} '
              '${data.waitingStock == 1 ? 'order is' : 'orders are'} waiting for stock',
          detail:
              'HPJ automatically rechecks this queue after receiving. Recheck manually after stock adjustments.',
          actionLabel: 'Open Prepare & Pack',
          screen: const _WarehouseWholesaleActionScreen(
            title: 'Prepare & Pack',
            section: 'fulfillment',
          ),
        ),
      );
    }

    if (data.activeDispatches > 0) {
      jobs.add(
        _WarehouseNextJob(
          priority: 50,
          icon: Icons.route_outlined,
          color: FarmColors.green,
          eyebrow: 'DELIVERY',
          title: '${data.activeDispatches} active '
              '${data.activeDispatches == 1 ? 'dispatch' : 'dispatches'}',
          detail:
              'Assign, send and complete deliveries or business collections.',
          actionLabel: 'Open Delivery',
          screen: const _WarehouseWholesaleActionScreen(
            title: 'Wholesale Delivery',
            section: 'dispatch',
          ),
        ),
      );
    }

    jobs.sort(
      (a, b) => a.priority.compareTo(
        b.priority,
      ),
    );

    return jobs.take(8).toList();
  }

  Widget _jobCard(
    BuildContext context,
    _WarehouseNextJob job, {
    bool primary = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 10,
      ),
      child: Material(
        color: FarmColors.card,
        borderRadius: BorderRadius.circular(
          primary ? 21 : 18,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(
            primary ? 21 : 18,
          ),
          onTap: () => _open(
            context,
            job.screen,
          ),
          child: Container(
            padding: EdgeInsets.all(
              primary ? 16 : 14,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                primary ? 21 : 18,
              ),
              border: Border.all(
                color: primary
                    ? job.color.withOpacity(0.30)
                    : FarmColors.line,
                width: primary ? 1.4 : 1,
              ),
              boxShadow: primary
                  ? [
                      BoxShadow(
                        color: job.color.withOpacity(0.08),
                        blurRadius: 18,
                        offset: const Offset(0, 7),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: primary ? 48 : 42,
                  height: primary ? 48 : 42,
                  decoration: BoxDecoration(
                    color: job.color.withOpacity(
                      primary ? 0.14 : 0.10,
                    ),
                    borderRadius: BorderRadius.circular(
                      primary ? 16 : 14,
                    ),
                  ),
                  child: Icon(
                    job.icon,
                    color: job.color,
                    size: primary ? 24 : 21,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        primary
                            ? 'DO THIS NEXT • ${job.eyebrow}'
                            : job.eyebrow,
                        style: TextStyle(
                          color: job.color,
                          fontSize: primary ? 10 : 9.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.45,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        job.title,
                        style: TextStyle(
                          color: FarmColors.ink,
                          fontSize: primary ? 15.5 : 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        job.detail,
                        style: const TextStyle(
                          color: FarmColors.mutedText,
                          fontSize: 10.8,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(
                        height: primary ? 10 : 8,
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: primary ? 10 : 0,
                          vertical: primary ? 7 : 0,
                        ),
                        decoration: primary
                            ? BoxDecoration(
                                color: FarmColors.primarySoft,
                                borderRadius:
                                    BorderRadius.circular(11),
                              )
                            : null,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              job.actionLabel,
                              style: TextStyle(
                                color: FarmColors.green,
                                fontSize: primary ? 12 : 11.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(width: 3),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              color: FarmColors.green,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _coverageColor(
    WarehouseProcurementRow row,
  ) {
    if (row.isShortage) return FarmColors.danger;
    if (row.isSurplus) return FarmColors.warning;
    return FarmColors.success;
  }

  String _coverageLabel(
    WarehouseProcurementRow row,
  ) {
    if (row.isShortage) return 'SHORTAGE';
    if (row.isSurplus) return 'SURPLUS';
    return 'COVERED';
  }

  Widget _coverageCard(
    WarehouseProcurementRow row,
  ) {
    final color = _coverageColor(row);

    return Padding(
      padding: const EdgeInsets.only(
        bottom: 9,
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: FarmColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: FarmColors.line,
          ),
        ),
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
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _coverageLabel(row),
                    style: TextStyle(
                      color: color,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${row.unit} • ${row.balanceLabel}',
              style: TextStyle(
                color: color,
                fontSize: 10.8,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                _ProcurementValueChip(
                  label: 'Orders',
                  value: row.quantity(
                    row.approvedOrderDemand,
                  ),
                ),
                _ProcurementValueChip(
                  label: 'Warehouse',
                  value: row.quantity(
                    row.warehouseAvailable,
                  ),
                ),
                _ProcurementValueChip(
                  label: 'Confirmed farm',
                  value: row.quantity(
                    row.unallocatedConfirmedSupply,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _coreTools(
    BuildContext context,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth =
            (constraints.maxWidth - 9) / 2;

        return Wrap(
          spacing: 9,
          runSpacing: 9,
          children: [
            _coreToolCard(
              context: context,
              width: cardWidth,
              icon: Icons.warehouse_outlined,
              title: 'Receiving',
              subtitle:
                  'Receive, inspect and complete inbound produce.',
              screen: const _WarehouseWholesaleActionScreen(
                title: 'Warehouse Receiving',
                section: 'receiving',
                receivingMode: 'receiving',
              ),
            ),
            _coreToolCard(
              context: context,
              width: cardWidth,
              icon: Icons.inventory_2_outlined,
              title: 'Inventory',
              subtitle:
                  'Lots, available stock, movements and adjustments.',
              screen: const WarehouseInventoryScreen(),
            ),
            _coreToolCard(
              context: context,
              width: cardWidth,
              icon: Icons.playlist_add_check_circle_outlined,
              title: 'Pick Queue',
              subtitle:
                  'Pick reserved stock in FEFO order.',
              screen: const WarehousePickingScreen(),
            ),
            _coreToolCard(
              context: context,
              width: cardWidth,
              icon: Icons.inventory_outlined,
              title: 'Prepare & Pack',
              subtitle:
                  'Prepare, pack and release wholesale orders.',
              screen: const _WarehouseWholesaleActionScreen(
                title: 'Prepare & Pack',
                section: 'fulfillment',
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _moreTools(
    BuildContext context,
  ) {
    final tools = <({
      IconData icon,
      String label,
      Widget screen,
    })>[
      (
        icon: Icons.route_outlined,
        label: 'Collections',
        screen: const CollectionPlanningScreen(),
      ),
      (
        icon: Icons.view_week_outlined,
        label: 'Packing Waves',
        screen: const WarehousePackingWavesScreen(),
      ),
      (
        icon: Icons.move_to_inbox_outlined,
        label: 'Dispatch Staging',
        screen: const WarehouseDispatchStagingScreen(),
      ),
      (
        icon: Icons.warning_amber_rounded,
        label: 'Exceptions',
        screen: const WarehouseExceptionsScreen(),
      ),
      (
        icon: Icons.local_shipping_outlined,
        label: 'Dispatch Center',
        screen: const WarehouseDispatchCommandCenterScreen(),
      ),
      (
        icon: Icons.route_rounded,
        label: 'Delivery Runs',
        screen: const WarehouseDeliveryRunsScreen(),
      ),
      (
        icon: Icons.fact_check_outlined,
        label: 'Cycle Counts',
        screen: const WarehouseCycleCountsScreen(),
      ),
      (
        icon: Icons.grid_view_outlined,
        label: 'Storage / Put-Away',
        screen: const WarehouseStorageLocationsScreen(),
      ),
    ];

    return FarmCard(
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 3,
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            12,
            0,
            12,
            12,
          ),
          leading: const Icon(
            Icons.apps_outlined,
            color: FarmColors.primary,
          ),
          title: const Text(
            'More Warehouse Tools',
            style: TextStyle(
              color: FarmColors.ink,
              fontWeight: FontWeight.w900,
            ),
          ),
          subtitle: const Text(
            'Collections, waves, staging, counts and storage',
            style: TextStyle(
              color: FarmColors.mutedText,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tools.map((tool) {
                return OutlinedButton.icon(
                  onPressed: () => _open(
                    context,
                    tool.screen,
                  ),
                  icon: Icon(
                    tool.icon,
                    size: 18,
                  ),
                  label: Text(
                    tool.label,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_WarehouseMvpSnapshot>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
                ConnectionState.waiting &&
            snapshot.data == null) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError &&
            snapshot.data == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 38,
                    color: FarmColors.warning,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    friendlyAppError(
                      snapshot.error!,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _refresh,
                    icon: const Icon(
                      Icons.refresh_rounded,
                    ),
                    label: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          );
        }

        final data = snapshot.data ??
            const _WarehouseMvpSnapshot(
              procurement: <WarehouseProcurementRow>[],
              receiving: <WholesaleReceivingBatch>[],
              lots: <WarehouseInventoryLot>[],
              fulfillments: <WholesaleFulfillment>[],
              dispatches: <WholesaleDispatch>[],
              picks: <WarehousePickQueueRow>[],
              exceptions: <WarehouseExceptionItem>[],
            );

        final jobs = _nextJobs(data);

        final filteredCoverage =
            data.procurement.where((row) {
          switch (_coverageFilter) {
            case 'shortage':
              return row.isShortage;
            case 'covered':
              return row.isCovered;
            case 'surplus':
              return row.isSurplus;
            default:
              return true;
          }
        }).toList();

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics:
                const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              14,
              14,
              14,
              110,
            ),
            children: [
              // ------------------------------------------------
              // ELITE HEADER
              // ------------------------------------------------
              Container(
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: FarmColors.primary,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: FarmColors.primary.withOpacity(
                        0.12,
                      ),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(
                              0.12,
                            ),
                            borderRadius:
                                BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.warehouse_outlined,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Warehouse Today',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 21,
                                  fontWeight:
                                      FontWeight.w900,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'HPJ keeps the next action clear from receiving to dispatch.',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11.5,
                                  height: 1.3,
                                  fontWeight:
                                      FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _stagePill(
                            icon: Icons.warehouse_outlined,
                            label: 'Receive',
                            active:
                                data.inboundActionCount > 0,
                          ),
                          const SizedBox(width: 6),
                          _stagePill(
                            icon: Icons.inventory_outlined,
                            label: 'Reserve',
                            active:
                                data.waitingStock > 0 ||
                                    data.readyToPrepare > 0,
                          ),
                          const SizedBox(width: 6),
                          _stagePill(
                            icon: Icons.playlist_add_check_circle_outlined,
                            label: 'Pick',
                            active: data.pickWork > 0,
                          ),
                          const SizedBox(width: 6),
                          _stagePill(
                            icon: Icons.inventory_2_outlined,
                            label: 'Pack',
                            active:
                                data.preparing > 0 ||
                                    data.packing > 0,
                          ),
                          const SizedBox(width: 6),
                          _stagePill(
                            icon: Icons.local_shipping_outlined,
                            label: 'Dispatch',
                            active:
                                data.readyForDispatch > 0 ||
                                    data.activeDispatches > 0,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ------------------------------------------------
              // OPERATIONAL COUNTS
              // ------------------------------------------------
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _metric(
                      label: 'Attention',
                      value: data.exceptions.length,
                      icon: Icons.warning_amber_rounded,
                      color: data.criticalExceptions > 0
                          ? FarmColors.danger
                          : FarmColors.warning,
                    ),
                    const SizedBox(width: 8),
                    _metric(
                      label: 'Inbound',
                      value: data.inboundActionCount,
                      icon: Icons.warehouse_outlined,
                    ),
                    const SizedBox(width: 8),
                    _metric(
                      label: 'Pick Lines',
                      value: data.pickWork,
                      icon: Icons.playlist_add_check_circle_outlined,
                    ),
                    const SizedBox(width: 8),
                    _metric(
                      label: 'Preparing',
                      value: data.readyToPrepare +
                          data.preparing,
                      icon: Icons.play_arrow_outlined,
                    ),
                    const SizedBox(width: 8),
                    _metric(
                      label: 'Packing',
                      value: data.packing,
                      icon: Icons.inventory_2_outlined,
                    ),
                    const SizedBox(width: 8),
                    _metric(
                      label: 'Dispatch',
                      value: data.readyForDispatch +
                          data.activeDispatches,
                      icon: Icons.local_shipping_outlined,
                    ),
                    const SizedBox(width: 8),
                    _metric(
                      label: 'Active Lots',
                      value: data.activeLots,
                      icon: Icons.grid_view_outlined,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 15),

              // ------------------------------------------------
              // WHAT NEEDS TO BE DONE NEXT?
              // ------------------------------------------------
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'What needs to be done next?',
                          style: TextStyle(
                            color: FarmColors.ink,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Start with the first task. HPJ reprioritizes the queue as work is completed.',
                          style: TextStyle(
                            color: FarmColors.mutedText,
                            fontSize: 10.8,
                            height: 1.35,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Refresh warehouse',
                    onPressed: _refresh,
                    icon: const Icon(
                      Icons.refresh_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (jobs.isEmpty)
                const FarmEmptyState(
                  icon: Icons.check_circle_outline,
                  title: 'You are caught up',
                  message:
                      'No warehouse action needs attention right now.',
                )
              else ...[
                _jobCard(
                  context,
                  jobs.first,
                  primary: true,
                ),
                if (jobs.length > 1) ...[
                  const SizedBox(height: 5),
                  const Padding(
                    padding: EdgeInsets.only(
                      bottom: 8,
                    ),
                    child: Text(
                      'Coming Up',
                      style: TextStyle(
                        color: FarmColors.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  ...jobs.skip(1).map(
                    (job) => _jobCard(
                      context,
                      job,
                    ),
                  ),
                ],
              ],

              const SizedBox(height: 6),

              // ------------------------------------------------
              // RECHECK STOCK HANDOFF
              // ------------------------------------------------
              FarmCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: FarmColors.primarySoft,
                        borderRadius:
                            BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.sync_alt_rounded,
                        color: FarmColors.green,
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Smart Stock Handoff',
                            style: TextStyle(
                              color: FarmColors.ink,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            data.waitingStock == 0
                                ? 'No wholesale orders are waiting for stock.'
                                : '${data.waitingStock} waiting '
                                    '${data.waitingStock == 1 ? 'order' : 'orders'}. '
                                    'HPJ rechecks automatically after receiving.',
                            style: const TextStyle(
                              color: FarmColors.mutedText,
                              fontSize: 10.5,
                              height: 1.3,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: _recheckingStock
                          ? null
                          : _recheckWaitingStock,
                      child: _recheckingStock
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Recheck'),
                    ),
                  ],
                ),
              ),

              if (widget.showNavigationCards) ...[
                const SizedBox(height: 17),
                const Text(
                  'Core Warehouse Tools',
                  style: TextStyle(
                    color: FarmColors.ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'The four tools staff will use most often.',
                  style: TextStyle(
                    color: FarmColors.mutedText,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 9),
                _coreTools(context),
                const SizedBox(height: 10),
                _moreTools(context),
              ],

              const SizedBox(height: 14),

              // ------------------------------------------------
              // SUPPLY COVERAGE — SECONDARY, NOT THE MAIN QUEUE
              // ------------------------------------------------
              FarmCard(
                padding: EdgeInsets.zero,
                child: Theme(
                  data: Theme.of(context).copyWith(
                    dividerColor: Colors.transparent,
                  ),
                  child: ExpansionTile(
                    initiallyExpanded:
                        data.shortageLines > 0,
                    tilePadding:
                        const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 3,
                    ),
                    childrenPadding:
                        const EdgeInsets.fromLTRB(
                      12,
                      0,
                      12,
                      12,
                    ),
                    leading: Icon(
                      data.shortageLines > 0
                          ? Icons.warning_amber_rounded
                          : Icons.check_circle_outline,
                      color: data.shortageLines > 0
                          ? FarmColors.warning
                          : FarmColors.green,
                    ),
                    title: const Text(
                      'Supply Coverage',
                      style: TextStyle(
                        color: FarmColors.ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    subtitle: Text(
                      data.shortageLines > 0
                          ? '${data.shortageLines} shortage '
                              '${data.shortageLines == 1 ? 'line needs' : 'lines need'} sourcing'
                          : '${data.procurement.length} tracked lines • no current shortage',
                      style: const TextStyle(
                        color: FarmColors.mutedText,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    children: [
                      SingleChildScrollView(
                        scrollDirection:
                            Axis.horizontal,
                        child: Row(
                          children: [
                            ChoiceChip(
                              label:
                                  const Text('Shortage'),
                              selected:
                                  _coverageFilter ==
                                      'shortage',
                              onSelected: (_) =>
                                  setState(
                                () => _coverageFilter =
                                    'shortage',
                              ),
                            ),
                            const SizedBox(width: 7),
                            ChoiceChip(
                              label: const Text('All'),
                              selected:
                                  _coverageFilter == 'all',
                              onSelected: (_) =>
                                  setState(
                                () => _coverageFilter =
                                    'all',
                              ),
                            ),
                            const SizedBox(width: 7),
                            ChoiceChip(
                              label:
                                  const Text('Covered'),
                              selected:
                                  _coverageFilter ==
                                      'covered',
                              onSelected: (_) =>
                                  setState(
                                () => _coverageFilter =
                                    'covered',
                              ),
                            ),
                            const SizedBox(width: 7),
                            ChoiceChip(
                              label:
                                  const Text('Surplus'),
                              selected:
                                  _coverageFilter ==
                                      'surplus',
                              onSelected: (_) =>
                                  setState(
                                () => _coverageFilter =
                                    'surplus',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (filteredCoverage.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                          child: Text(
                            'No supply lines match this view.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color:
                                  FarmColors.mutedText,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        )
                      else
                        ...filteredCoverage.map(
                          _coverageCard,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProcurementValueChip extends StatelessWidget {
  final String label;
  final String value;

  const _ProcurementValueChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: FarmColors.cardSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: FarmColors.line,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: FarmColors.mutedText,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: FarmColors.ink,
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
