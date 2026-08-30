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
      unallocatedConfirmedSupply: amount(data['unallocated_confirmed_supply']),
      requiredQuantity: amount(data['required_quantity']),
      trustedSupply: amount(data['trusted_supply']),
      balanceQuantity: amount(data['balance_quantity']),
      coverageStatus: (data['coverage_status'] ?? 'covered')
          .toString()
          .trim()
          .toLowerCase(),
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

class ProcurementCommandCenterScreen extends StatelessWidget {
  const ProcurementCommandCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: FarmColors.background,
      appBar: _WarehouseAppBar(title: 'Procurement Command Center'),
      body: SafeArea(
        child: WarehouseOperationsPanel(
          showNavigationCards: false,
        ),
      ),
    );
  }
}

class _WarehouseAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const _WarehouseAppBar({required this.title});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
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

class _WarehouseOperationsPanelState extends State<WarehouseOperationsPanel> {
  late Future<List<WarehouseProcurementRow>> _future;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _future = fetchWarehouseProcurementSummary();
  }

  Future<void> _refresh() async {
    final next = fetchWarehouseProcurementSummary();
    setState(() => _future = next);
    await next;
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }

  Color _coverageColor(WarehouseProcurementRow row) {
    if (row.isShortage) return FarmColors.danger;
    if (row.isSurplus) return FarmColors.warning;
    return FarmColors.success;
  }

  String _coverageLabel(WarehouseProcurementRow row) {
    if (row.isShortage) return 'SHORTAGE';
    if (row.isSurplus) return 'SURPLUS';
    return 'COVERED';
  }

  Widget _metric({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      width: 132,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FarmColors.cardSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: FarmColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: FarmColors.primary),
          const SizedBox(height: 8),
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
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _navigationCards(BuildContext context) {
    Widget navButton({
      required IconData icon,
      required String label,
      required Widget screen,
    }) {
      return Expanded(
        child: OutlinedButton.icon(
          onPressed: () => _open(context, screen),
          icon: Icon(icon),
          label: Text(label),
        ),
      );
    }

    return FarmCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Warehouse Operations',
            style: TextStyle(
              color: FarmColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Move from farmer sourcing and procurement intelligence through inventory health, expiry/waste control, collection, warehouse execution, delivery, proof, returns and traceability without duplicating the wholesale fulfilment workflow.',
            style: TextStyle(
              color: FarmColors.mutedText,
              fontSize: 10.5,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              navButton(
                icon: Icons.agriculture_outlined,
                label: 'Suppliers',
                screen: const WarehouseSupplierPerformanceScreen(),
              ),
              const SizedBox(width: 8),
              navButton(
                icon: Icons.insights_outlined,
                label: 'Sourcing Intel',
                screen: const WarehouseProcurementIntelligenceScreen(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              navButton(
                icon: Icons.route_outlined,
                label: 'Collections',
                screen: const CollectionPlanningScreen(),
              ),
              const SizedBox(width: 8),
              navButton(
                icon: Icons.inventory_2_outlined,
                label: 'Inventory',
                screen: const WarehouseInventoryScreen(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              navButton(
                icon: Icons.analytics_outlined,
                label: 'Inventory Intel',
                screen: const WarehouseInventoryIntelligenceScreen(),
              ),
              const SizedBox(width: 8),
              navButton(
                icon: Icons.health_and_safety_outlined,
                label: 'Expiry / Waste',
                screen: const WarehouseExpiryWasteControlScreen(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _open(
                context,
                const WarehouseStockoutForecastScreen(),
              ),
              icon: const Icon(Icons.trending_up_outlined),
              label: const Text('Stock Risk / Replenishment'),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              navButton(
                icon: Icons.query_stats_outlined,
                label: 'Demand Forecast',
                screen: const WarehouseDemandForecastScreen(),
              ),
              const SizedBox(width: 8),
              navButton(
                icon: Icons.balance_outlined,
                label: 'Supply Gap',
                screen: const WarehouseSupplyGapForecastScreen(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _open(
                context,
                const WarehouseProcurementSuggestionsScreen(),
              ),
              icon: const Icon(Icons.inventory_2_outlined),
              label: const Text('Automated Procurement Suggestions'),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              navButton(
                icon: Icons.playlist_add_check_circle_outlined,
                label: 'Pick Queue',
                screen: const WarehousePickingScreen(),
              ),
              const SizedBox(width: 8),
              navButton(
                icon: Icons.view_week_outlined,
                label: 'Packing Waves',
                screen: const WarehousePackingWavesScreen(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              navButton(
                icon: Icons.move_to_inbox_outlined,
                label: 'Dispatch Staging',
                screen: const WarehouseDispatchStagingScreen(),
              ),
              const SizedBox(width: 8),
              navButton(
                icon: Icons.warning_amber_rounded,
                label: 'Exceptions',
                screen: const WarehouseExceptionsScreen(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              navButton(
                icon: Icons.local_shipping_outlined,
                label: 'Dispatch Center',
                screen: const WarehouseDispatchCommandCenterScreen(),
              ),
              const SizedBox(width: 8),
              navButton(
                icon: Icons.route_outlined,
                label: 'Delivery Runs',
                screen: const WarehouseDeliveryRunsScreen(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              navButton(
                icon: Icons.verified_user_outlined,
                label: 'Delivery Proof',
                screen: const WarehouseDeliveryProofScreen(),
              ),
              const SizedBox(width: 8),
              navButton(
                icon: Icons.assignment_return_outlined,
                label: 'Returns',
                screen: const WarehouseReturnsScreen(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              navButton(
                icon: Icons.account_tree_outlined,
                label: 'Traceability',
                screen: const WarehouseTraceabilityScreen(),
              ),
              const SizedBox(width: 8),
              navButton(
                icon: Icons.fact_check_outlined,
                label: 'Cycle Counts',
                screen: const WarehouseCycleCountsScreen(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _open(
                context,
                const WarehouseStorageLocationsScreen(),
              ),
              icon: const Icon(Icons.grid_view_outlined),
              label: const Text('Storage / Put-Away'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<WarehouseProcurementRow>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            snapshot.data == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError && snapshot.data == null) {
          farmDebugLog('HPJ WAREHOUSE LOAD ERROR: ${snapshot.error}');
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
                    friendlyAppError(snapshot.error!),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          );
        }

        final rows = snapshot.data ?? const <WarehouseProcurementRow>[];
        final shortages = rows.where((row) => row.isShortage).length;
        final surplus = rows.where((row) => row.isSurplus).length;
        final covered = rows.where((row) => row.isCovered).length;

        final filtered = rows.where((row) {
          switch (_filter) {
            case 'shortage':
              return row.isShortage;
            case 'surplus':
              return row.isSurplus;
            case 'covered':
              return row.isCovered;
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
                      Icons.hub_outlined,
                      color: FarmColors.primary,
                      size: 30,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Procurement Command Center',
                            style: TextStyle(
                              color: FarmColors.ink,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Trusted supply versus committed wholesale demand. Product quantities are never mixed across different units.',
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
              if (widget.showNavigationCards) ...[
                const SizedBox(height: 12),
                _navigationCards(context),
              ],
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _metric(
                      label: 'Shortages',
                      value: '$shortages',
                      icon: Icons.warning_amber_rounded,
                    ),
                    const SizedBox(width: 8),
                    _metric(
                      label: 'Covered',
                      value: '$covered',
                      icon: Icons.check_circle_outline,
                    ),
                    const SizedBox(width: 8),
                    _metric(
                      label: 'Surplus',
                      value: '$surplus',
                      icon: Icons.trending_up_rounded,
                    ),
                    const SizedBox(width: 8),
                    _metric(
                      label: 'Tracked Lines',
                      value: '${rows.length}',
                      icon: Icons.list_alt_outlined,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('All'),
                      selected: _filter == 'all',
                      onSelected: (_) => setState(() => _filter = 'all'),
                    ),
                    const SizedBox(width: 7),
                    ChoiceChip(
                      label: const Text('Shortage'),
                      selected: _filter == 'shortage',
                      onSelected: (_) => setState(() => _filter = 'shortage'),
                    ),
                    const SizedBox(width: 7),
                    ChoiceChip(
                      label: const Text('Covered'),
                      selected: _filter == 'covered',
                      onSelected: (_) => setState(() => _filter = 'covered'),
                    ),
                    const SizedBox(width: 7),
                    ChoiceChip(
                      label: const Text('Surplus'),
                      selected: _filter == 'surplus',
                      onSelected: (_) => setState(() => _filter = 'surplus'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (filtered.isEmpty)
                const FarmEmptyState(
                  icon: Icons.inventory_2_outlined,
                  title: 'No procurement lines yet',
                  message:
                      'Supply, demand and warehouse inventory will appear here as the wholesale operation becomes active.',
                )
              else
                ...filtered.map((row) {
                  final color = _coverageColor(row);
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
                                  row.productName,
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
                                  color: color.withOpacity(0.10),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  _coverageLabel(row),
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Unit: ${row.unit} • ${row.balanceLabel}',
                            style: TextStyle(
                              color: color,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 7,
                            runSpacing: 7,
                            children: [
                              _ProcurementValueChip(
                                label: 'Approved orders',
                                value: row.quantity(row.approvedOrderDemand),
                              ),
                              _ProcurementValueChip(
                                label: 'Reserved future',
                                value: row.quantity(row.reservedDemand),
                              ),
                              _ProcurementValueChip(
                                label: 'Warehouse available',
                                value: row.quantity(row.warehouseAvailable),
                              ),
                              _ProcurementValueChip(
                                label: 'Unallocated confirmed farm',
                                value: row
                                    .quantity(row.unallocatedConfirmedSupply),
                              ),
                            ],
                          ),
                          if (row.planningDemand > 0) ...[
                            const SizedBox(height: 9),
                            Text(
                              'Planning signal: ${row.quantity(row.planningDemand)}. This is visible for forecasting but is not treated as committed demand.',
                              style: const TextStyle(
                                color: FarmColors.mutedText,
                                fontSize: 10,
                                height: 1.35,
                                fontWeight: FontWeight.w600,
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
