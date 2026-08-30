part of harvest_place_app;

// ================================================================
// THE HARVEST PLACE JA
// PHASE 4C — WHOLESALE MARGIN CONTROL
//
// Procurement cost is traced from issued warehouse lots back to receiving
// farmer_unit_cost. Packing/delivery/other actual costs are invoice-level.
// ================================================================

class WholesaleMarginRow {
  final String invoiceId;
  final String invoiceNumber;
  final String businessName;
  final DateTime? issueDate;
  final double revenue;
  final double automaticProcurementCost;
  final double procurementCost;
  final String procurementCostSource;
  final double packingCost;
  final double deliveryCost;
  final double otherCost;
  final double contributionMargin;
  final double contributionMarginPercent;
  final String marginStatus;
  final String costNotes;

  const WholesaleMarginRow({required this.invoiceId, required this.invoiceNumber, required this.businessName, this.issueDate, required this.revenue, required this.automaticProcurementCost, required this.procurementCost, required this.procurementCostSource, required this.packingCost, required this.deliveryCost, required this.otherCost, required this.contributionMargin, required this.contributionMarginPercent, required this.marginStatus, required this.costNotes});

  factory WholesaleMarginRow.fromSupabase(Map<String, dynamic> data) {
    double n(dynamic value) => value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '') ?? 0;
    return WholesaleMarginRow(
      invoiceId: (data['invoice_id'] ?? '').toString(),
      invoiceNumber: (data['invoice_number'] ?? '').toString(),
      businessName: (data['business_name'] ?? 'Wholesale business').toString().trim(),
      issueDate: DateTime.tryParse((data['issue_date'] ?? '').toString()),
      revenue: n(data['revenue']),
      automaticProcurementCost: n(data['automatic_procurement_cost']),
      procurementCost: n(data['procurement_cost']),
      procurementCostSource: (data['procurement_cost_source'] ?? 'lot_cost').toString(),
      packingCost: n(data['packing_cost']),
      deliveryCost: n(data['delivery_cost']),
      otherCost: n(data['other_cost']),
      contributionMargin: n(data['contribution_margin']),
      contributionMarginPercent: n(data['contribution_margin_percent']),
      marginStatus: (data['margin_status'] ?? 'healthy').toString().trim().toLowerCase(),
      costNotes: (data['cost_notes'] ?? '').toString().trim(),
    );
  }
}

class WholesaleProductMarginRow {
  final String productName;
  final String unit;
  final double quantitySold;
  final double revenue;
  final double procurementCost;
  final double grossMargin;
  final double grossMarginPercent;

  const WholesaleProductMarginRow({required this.productName, required this.unit, required this.quantitySold, required this.revenue, required this.procurementCost, required this.grossMargin, required this.grossMarginPercent});
  factory WholesaleProductMarginRow.fromSupabase(Map<String, dynamic> data) {
    double n(dynamic value) => value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '') ?? 0;
    return WholesaleProductMarginRow(productName: (data['product_name'] ?? 'Produce').toString().trim(), unit: (data['unit'] ?? 'unit').toString().trim(), quantitySold: n(data['quantity_sold']), revenue: n(data['revenue']), procurementCost: n(data['procurement_cost']), grossMargin: n(data['gross_margin']), grossMarginPercent: n(data['gross_margin_percent']));
  }
}

Future<List<WholesaleMarginRow>> fetchWholesaleMarginRows({String search = ''}) async {
  await requireAdminAccess();
  final response = await supabase.rpc('admin_wholesale_margin_summary', params: {'p_search': search.trim(), 'p_limit': 250});
  return (response as List).map((row) => WholesaleMarginRow.fromSupabase(Map<String, dynamic>.from(row as Map))).toList();
}

Future<List<WholesaleProductMarginRow>> fetchWholesaleProductMargins() async {
  await requireAdminAccess();
  final response = await supabase.rpc('admin_wholesale_product_margin_summary', params: {'p_limit': 100});
  return (response as List).map((row) => WholesaleProductMarginRow.fromSupabase(Map<String, dynamic>.from(row as Map))).toList();
}

Future<void> updateWholesaleInvoiceActualCosts({required WholesaleMarginRow row, double? procurementOverride, required double packingCost, required double deliveryCost, required double otherCost, String notes = ''}) async {
  await requireAdminAccess();
  await supabase.rpc('admin_update_wholesale_invoice_costs', params: {
    'p_invoice_id': row.invoiceId,
    'p_procurement_cost_override': procurementOverride,
    'p_packing_cost': packingCost,
    'p_delivery_cost': deliveryCost,
    'p_other_cost': otherCost,
    'p_notes': notes.trim(),
  });
}

class WholesaleMarginControlScreen extends StatefulWidget {
  const WholesaleMarginControlScreen({super.key});
  @override
  State<WholesaleMarginControlScreen> createState() => _WholesaleMarginControlScreenState();
}

class _WholesaleMarginControlScreenState extends State<WholesaleMarginControlScreen> {
  late Future<List<dynamic>> _future;
  String _search = '';
  @override
  void initState() { super.initState(); _future = _load(); }
  Future<List<dynamic>> _load() => Future.wait<dynamic>([fetchWholesaleMarginRows(search: _search), fetchWholesaleProductMargins()]);
  Future<void> _refresh() async { final next = _load(); setState(() => _future = next); await next; }

  Color _statusColor(String status) {
    if (status == 'loss') return FarmColors.danger;
    if (status == 'low') return FarmColors.warning;
    return FarmColors.success;
  }

  Future<void> _editCosts(WholesaleMarginRow row) async {
    final procurement = TextEditingController(text: row.procurementCostSource == 'override' ? row.procurementCost.toStringAsFixed(2) : '');
    final packing = TextEditingController(text: row.packingCost.toStringAsFixed(2));
    final delivery = TextEditingController(text: row.deliveryCost.toStringAsFixed(2));
    final other = TextEditingController(text: row.otherCost.toStringAsFixed(2));
    final notes = TextEditingController(text: row.costNotes);
    final ok = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
      title: Text('Actual costs • ${row.invoiceNumber}'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Automatic procurement cost: ${formatJmd(row.automaticProcurementCost)}', style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        TextField(controller: procurement, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Procurement override (blank = lot cost)')),
        const SizedBox(height: 8),
        TextField(controller: packing, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Packing cost')),
        const SizedBox(height: 8),
        TextField(controller: delivery, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Delivery / logistics cost')),
        const SizedBox(height: 8),
        TextField(controller: other, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Other direct cost')),
        const SizedBox(height: 8),
        TextField(controller: notes, maxLines: 2, decoration: const InputDecoration(labelText: 'Cost note')),
      ])),
      actions: [TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')), ElevatedButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Save Costs'))],
    ));
    if (ok == true) {
      double amount(TextEditingController c) => double.tryParse(c.text.trim().replaceAll(',', '')) ?? 0;
      final overrideText = procurement.text.trim();
      try {
        await updateWholesaleInvoiceActualCosts(row: row, procurementOverride: overrideText.isEmpty ? null : amount(procurement), packingCost: amount(packing), deliveryCost: amount(delivery), otherCost: amount(other), notes: notes.text);
        await _refresh();
      } catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyAppError(error)))); }
    }
    procurement.dispose(); packing.dispose(); delivery.dispose(); other.dispose(); notes.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FarmColors.background,
      appBar: AppBar(title: const Text('Margin Control')),
      body: FutureBuilder<List<dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && snapshot.data == null) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError && snapshot.data == null) return Center(child: Text(friendlyAppError(snapshot.error!)));
          final data = snapshot.data ?? const <dynamic>[];
          final rows = data.isNotEmpty ? data[0] as List<WholesaleMarginRow> : <WholesaleMarginRow>[];
          final products = data.length > 1 ? data[1] as List<WholesaleProductMarginRow> : <WholesaleProductMarginRow>[];
          final revenue = rows.fold<double>(0, (sum, row) => sum + row.revenue);
          final contribution = rows.fold<double>(0, (sum, row) => sum + row.contributionMargin);
          final avgPct = revenue <= 0 ? 0 : contribution / revenue * 100;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
              children: [
                FarmCard(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Wholesale Contribution Margin', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  const Text('Revenue is compared with traceable farmer procurement cost from issued lots plus actual packing, logistics and other direct costs. Finalized customer credits reduce revenue and recovered supplier claims reduce effective procurement cost.', style: TextStyle(color: FarmColors.mutedText, fontSize: 10.5, height: 1.35, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Text('${formatJmd(contribution)} contribution • ${avgPct.toStringAsFixed(1)}% overall', style: TextStyle(color: contribution < 0 ? FarmColors.danger : FarmColors.primary, fontWeight: FontWeight.w900)),
                ])),
                const SizedBox(height: 12),
                TextField(decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search invoice or business'), onSubmitted: (value) { _search = value.trim(); _refresh(); }),
                const SizedBox(height: 14),
                const Text('Invoice Margins', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                if (rows.isEmpty)
                  const FarmEmptyState(icon: Icons.analytics_outlined, title: 'No margin rows yet', message: 'Issued wholesale invoices will appear when finance data is available.')
                else
                  ...rows.map((row) {
                    final color = _statusColor(row.marginStatus);
                    return Padding(padding: const EdgeInsets.only(bottom: 10), child: FarmCard(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [Expanded(child: Text('${row.invoiceNumber} • ${row.businessName}', style: const TextStyle(fontWeight: FontWeight.w900))), Text('${row.contributionMarginPercent.toStringAsFixed(1)}%', style: TextStyle(color: color, fontWeight: FontWeight.w900))]),
                      const SizedBox(height: 6),
                      Wrap(spacing: 10, runSpacing: 6, children: [
                        Text('Revenue ${formatJmd(row.revenue)}', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800)),
                        Text('Produce ${formatJmd(row.procurementCost)}', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800)),
                        Text('Pack ${formatJmd(row.packingCost)}', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800)),
                        Text('Logistics ${formatJmd(row.deliveryCost)}', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800)),
                      ]),
                      const SizedBox(height: 5),
                      Text('Contribution ${formatJmd(row.contributionMargin)} • ${row.procurementCostSource.contains('override') ? (row.procurementCostSource.contains('recovery') ? 'override • net supplier recovery' : 'procurement override') : (row.procurementCostSource.contains('recovery') ? 'lot cost • net supplier recovery' : 'lot-traced procurement')}', style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(onPressed: () => _editCosts(row), icon: const Icon(Icons.edit_outlined, size: 16), label: const Text('Actual Costs')),
                    ])));
                  }),
                const SizedBox(height: 18),
                const Text('Product Gross Margin', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                const Text('Before invoice-level packing and delivery overhead.', style: TextStyle(color: FarmColors.mutedText, fontSize: 10.5, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                if (products.isEmpty)
                  const FarmCard(child: Text('No product margin history yet.'))
                else
                  ...products.take(30).map((item) => Padding(padding: const EdgeInsets.only(bottom: 8), child: FarmCard(padding: const EdgeInsets.all(12), child: Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w900)), Text('${item.quantitySold.toStringAsFixed(1)} ${item.unit} • Revenue ${formatJmd(item.revenue)} • Cost ${formatJmd(item.procurementCost)}', style: const TextStyle(color: FarmColors.mutedText, fontSize: 9.8, fontWeight: FontWeight.w700))])),
                    Text('${item.grossMarginPercent.toStringAsFixed(1)}%', style: TextStyle(color: item.grossMargin < 0 ? FarmColors.danger : item.grossMarginPercent < 15 ? FarmColors.warning : FarmColors.success, fontWeight: FontWeight.w900)),
                  ])))),
              ],
            ),
          );
        },
      ),
    );
  }
}
