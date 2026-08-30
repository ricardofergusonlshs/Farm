part of harvest_place_app;

// ================================================================
// THE HARVEST PLACE JA
// PHASE 4A — WHOLESALE FINANCE / RECEIVABLES COMMAND CENTER
//
// Existing wholesale_invoices + wholesale_invoice_payments remain the
// accounting source of truth. This file adds finance visibility only.
// ================================================================

class WholesaleFinanceSummary {
  final int issuedInvoiceCount;
  final int openInvoiceCount;
  final int overdueInvoiceCount;
  final double issuedRevenue;
  final double confirmedReceipts;
  final double outstandingBalance;
  final double overdueBalance;
  final double currentBalance;
  final double days1To30;
  final double days31To60;
  final double days61Plus;

  const WholesaleFinanceSummary({
    required this.issuedInvoiceCount,
    required this.openInvoiceCount,
    required this.overdueInvoiceCount,
    required this.issuedRevenue,
    required this.confirmedReceipts,
    required this.outstandingBalance,
    required this.overdueBalance,
    required this.currentBalance,
    required this.days1To30,
    required this.days31To60,
    required this.days61Plus,
  });

  factory WholesaleFinanceSummary.fromSupabase(Map<String, dynamic> data) {
    double n(dynamic value) => value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '') ?? 0;
    int i(dynamic value) => value is num
        ? value.toInt()
        : int.tryParse(value?.toString() ?? '') ?? 0;
    return WholesaleFinanceSummary(
      issuedInvoiceCount: i(data['issued_invoice_count']),
      openInvoiceCount: i(data['open_invoice_count']),
      overdueInvoiceCount: i(data['overdue_invoice_count']),
      issuedRevenue: n(data['issued_revenue']),
      confirmedReceipts: n(data['confirmed_receipts']),
      outstandingBalance: n(data['outstanding_balance']),
      overdueBalance: n(data['overdue_balance']),
      currentBalance: n(data['current_balance']),
      days1To30: n(data['days_1_30']),
      days31To60: n(data['days_31_60']),
      days61Plus: n(data['days_61_plus']),
    );
  }
}

class WholesaleReceivableRow {
  final String invoiceId;
  final String invoiceNumber;
  final String businessAccountId;
  final String businessName;
  final String contactName;
  final String contactPhone;
  final String invoiceStatus;
  final String paymentStatus;
  final double totalAmount;
  final double paidAmount;
  final double amountDue;
  final DateTime? issueDate;
  final DateTime? dueDate;
  final int daysOverdue;
  final String agingBucket;

  const WholesaleReceivableRow({
    required this.invoiceId,
    required this.invoiceNumber,
    required this.businessAccountId,
    required this.businessName,
    required this.contactName,
    required this.contactPhone,
    required this.invoiceStatus,
    required this.paymentStatus,
    required this.totalAmount,
    required this.paidAmount,
    required this.amountDue,
    this.issueDate,
    this.dueDate,
    required this.daysOverdue,
    required this.agingBucket,
  });

  factory WholesaleReceivableRow.fromSupabase(Map<String, dynamic> data) {
    double n(dynamic value) => value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '') ?? 0;
    int i(dynamic value) => value is num
        ? value.toInt()
        : int.tryParse(value?.toString() ?? '') ?? 0;
    return WholesaleReceivableRow(
      invoiceId: (data['invoice_id'] ?? '').toString(),
      invoiceNumber: (data['invoice_number'] ?? '').toString().trim(),
      businessAccountId: (data['business_account_id'] ?? '').toString(),
      businessName:
          (data['business_name'] ?? 'Wholesale business').toString().trim(),
      contactName: (data['contact_name'] ?? '').toString().trim(),
      contactPhone: (data['contact_phone'] ?? '').toString().trim(),
      invoiceStatus:
          (data['invoice_status'] ?? 'draft').toString().trim().toLowerCase(),
      paymentStatus:
          (data['payment_status'] ?? 'unpaid').toString().trim().toLowerCase(),
      totalAmount: n(data['total_amount']),
      paidAmount: n(data['paid_amount']),
      amountDue: n(data['amount_due']),
      issueDate: DateTime.tryParse((data['issue_date'] ?? '').toString()),
      dueDate: DateTime.tryParse((data['due_date'] ?? '').toString()),
      daysOverdue: i(data['days_overdue']),
      agingBucket: (data['aging_bucket'] ?? 'Current').toString().trim(),
    );
  }

  bool get isOverdue => daysOverdue > 0 && amountDue > 0.005;
}

Future<WholesaleFinanceSummary> fetchWholesaleFinanceSummary() async {
  await requireAdminAccess();
  final response = await supabase.rpc('admin_wholesale_finance_summary');
  if (response is List && response.isNotEmpty) {
    return WholesaleFinanceSummary.fromSupabase(
      Map<String, dynamic>.from(response.first as Map),
    );
  }
  if (response is Map) {
    return WholesaleFinanceSummary.fromSupabase(
      Map<String, dynamic>.from(response),
    );
  }
  throw Exception('Wholesale finance summary could not be loaded.');
}

Future<List<WholesaleReceivableRow>> fetchWholesaleReceivables({
  String status = 'open',
  String search = '',
}) async {
  await requireAdminAccess();
  final response = await supabase.rpc(
    'admin_list_wholesale_receivables',
    params: {
      'p_search': search.trim(),
      'p_status': status.trim().toLowerCase(),
      'p_limit': 250,
    },
  );
  return (response as List)
      .map((row) => WholesaleReceivableRow.fromSupabase(
            Map<String, dynamic>.from(row as Map),
          ))
      .toList();
}

class WholesaleFinanceScreen extends StatefulWidget {
  const WholesaleFinanceScreen({super.key});
  @override
  State<WholesaleFinanceScreen> createState() => _WholesaleFinanceScreenState();
}

class _WholesaleFinanceScreenState extends State<WholesaleFinanceScreen> {
  String _status = 'open';
  String _search = '';
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<dynamic>> _load() async {
    return Future.wait<dynamic>([
      fetchWholesaleFinanceSummary(),
      fetchWholesaleReceivables(status: _status, search: _search),
    ]);
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() => _future = next);
    await next;
  }

  void _applyStatus(String value) {
    setState(() {
      _status = value;
      _future = _load();
    });
  }

  Widget _metric(String label, double value, IconData icon) {
    return Container(
      width: 145,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FarmColors.cardSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: FarmColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: FarmColors.primary, size: 18),
          const SizedBox(height: 7),
          Text(formatJmd(value),
              style:
                  const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
          Text(label,
              style: const TextStyle(
                  color: FarmColors.mutedText,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
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
        if (data.length < 2) return const SizedBox.shrink();
        final summary = data[0] as WholesaleFinanceSummary;
        final rows = data[1] as List<WholesaleReceivableRow>;

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
            children: [
              FarmCard(
                padding: const EdgeInsets.all(16),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.account_balance_wallet_outlined,
                        color: FarmColors.primary, size: 30),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Wholesale Finance',
                              style: TextStyle(
                                  color: FarmColors.ink,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900)),
                          SizedBox(height: 4),
                          Text(
                              'Invoices and confirmed payments remain the source of truth. This command center adds receivables, credits, refunds, supplier claims, settlements, cash-flow planning, bank reconciliation, profitability intelligence, pricing control, margin recommendations, integrity checks, end-to-end reconciliation and audit controls without creating a second accounting ledger.',
                              style: TextStyle(
                                  color: FarmColors.mutedText,
                                  fontSize: 10.5,
                                  height: 1.35,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                              builder: (_) =>
                                  const WholesaleCreditNotesScreen())),
                      icon: const Icon(Icons.note_alt_outlined),
                      label: const Text('Credit Notes'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                              builder: (_) =>
                                  const WholesaleReturnFinanceScreen())),
                      icon: const Icon(Icons.assignment_return_outlined),
                      label: const Text('Return Finance'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                              builder: (_) => const SupplierClaimsScreen())),
                      icon: const Icon(Icons.agriculture_outlined),
                      label: const Text('Supplier Claims'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                              builder: (_) => const FarmerSettlementsScreen())),
                      icon: const Icon(Icons.account_balance_wallet_outlined),
                      label: const Text('Settlements'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                              builder: (_) => const WholesaleCashFlowScreen())),
                      icon: const Icon(Icons.account_balance_outlined),
                      label: const Text('Cash Flow'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                              builder: (_) =>
                                  const FarmerPayoutScheduleScreen())),
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: const Text('Payout Schedule'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                              builder: (_) =>
                                  const BankReconciliationScreen())),
                      icon: const Icon(Icons.link_outlined),
                      label: const Text('Bank Reconcile'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                              builder: (_) =>
                                  const WholesaleMarginControlScreen())),
                      icon: const Icon(Icons.analytics_outlined),
                      label: const Text('Margin Control'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                              builder: (_) =>
                                  const WholesaleProfitabilityIntelligenceScreen())),
                      icon: const Icon(Icons.analytics_outlined),
                      label: const Text('Profitability'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                              builder: (_) =>
                                  const WholesalePricingControlScreen())),
                      icon: const Icon(Icons.payments_outlined),
                      label: const Text('Pricing Control'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute<
                          void>(
                      builder: (_) =>
                          const WholesaleCommercialRecommendationsScreen())),
                  icon: const Icon(Icons.lightbulb_outline),
                  label: const Text('Commercial Recommendations'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                          builder: (_) =>
                              const FinanceAuditControlCenterScreen())),
                  icon: const Icon(Icons.fact_check_outlined),
                  label: const Text('Finance Health & Audit Center'),
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _metric('Issued revenue', summary.issuedRevenue,
                        Icons.receipt_long_outlined),
                    const SizedBox(width: 8),
                    _metric('Receipts', summary.confirmedReceipts,
                        Icons.payments_outlined),
                    const SizedBox(width: 8),
                    _metric('Outstanding', summary.outstandingBalance,
                        Icons.account_balance_outlined),
                    const SizedBox(width: 8),
                    _metric('Overdue', summary.overdueBalance,
                        Icons.warning_amber_rounded),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              FarmCard(
                padding: const EdgeInsets.all(14),
                child: Wrap(
                  spacing: 14,
                  runSpacing: 8,
                  children: [
                    Text('Current ${formatJmd(summary.currentBalance)}',
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    Text('1–30 ${formatJmd(summary.days1To30)}',
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    Text('31–60 ${formatJmd(summary.days31To60)}',
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    Text('61+ ${formatJmd(summary.days61Plus)}',
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    Text('${summary.overdueInvoiceCount} overdue invoice(s)',
                        style: const TextStyle(
                            color: FarmColors.warning,
                            fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search business or invoice'),
                onSubmitted: (value) {
                  _search = value.trim();
                  _refresh();
                },
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children:
                      ['open', 'overdue', 'paid', 'draft', 'all'].map((value) {
                    final label = value == 'open'
                        ? 'Open'
                        : value == 'overdue'
                            ? 'Overdue'
                            : value == 'paid'
                                ? 'Paid'
                                : value == 'draft'
                                    ? 'Draft'
                                    : 'All';
                    return Padding(
                      padding: const EdgeInsets.only(right: 7),
                      child: ChoiceChip(
                          label: Text(label),
                          selected: _status == value,
                          onSelected: (_) => _applyStatus(value)),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 14),
              if (rows.isEmpty)
                const FarmEmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No invoices in this view',
                    message:
                        'Wholesale receivables will appear here as invoices are issued.')
              else
                ...rows.map((row) {
                  final color = row.isOverdue
                      ? FarmColors.danger
                      : row.amountDue > 0.005
                          ? FarmColors.warning
                          : FarmColors.success;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: FarmCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Expanded(
                                child: Text(
                                    '${row.invoiceNumber} • ${row.businessName}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14))),
                            Text(row.agingBucket,
                                style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 10)),
                          ]),
                          const SizedBox(height: 6),
                          Text(
                              '${formatJmd(row.amountDue)} due • ${formatJmd(row.paidAmount)} paid • Total ${formatJmd(row.totalAmount)}',
                              style: const TextStyle(
                                  color: FarmColors.mutedText,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10.5)),
                          if (row.dueDate != null) ...[
                            const SizedBox(height: 4),
                            Text(
                                row.isOverdue
                                    ? '${row.daysOverdue} day(s) overdue'
                                    : 'Due ${row.dueDate!.toLocal().day}/${row.dueDate!.toLocal().month}/${row.dueDate!.toLocal().year}',
                                style: TextStyle(
                                    color: color,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800)),
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
