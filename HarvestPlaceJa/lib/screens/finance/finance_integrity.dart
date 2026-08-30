part of harvest_place_app;

// ================================================================
// PHASE 4M — FINANCIAL INTEGRITY CHECKS
// Live diagnostics only; review status never rewrites source records.
// ================================================================

class FinanceIntegritySummary {
  final double healthScore;
  final int totalRecords,
      attention,
      critical,
      high,
      medium,
      low,
      invoices,
      settlements,
      banks,
      claims,
      missingCost;
  const FinanceIntegritySummary(
      {required this.healthScore,
      required this.totalRecords,
      required this.attention,
      required this.critical,
      required this.high,
      required this.medium,
      required this.low,
      required this.invoices,
      required this.settlements,
      required this.banks,
      required this.claims,
      required this.missingCost});
  factory FinanceIntegritySummary.fromSupabase(Map<String, dynamic> d) {
    double n(v) => v is num ? v.toDouble() : double.tryParse('${v ?? ''}') ?? 0;
    int i(v) => v is num ? v.toInt() : int.tryParse('${v ?? ''}') ?? 0;
    return FinanceIntegritySummary(
        healthScore: n(d['health_score']),
        totalRecords: i(d['total_records_checked']),
        attention: i(d['attention_issue_count']),
        critical: i(d['critical_issue_count']),
        high: i(d['high_issue_count']),
        medium: i(d['medium_issue_count']),
        low: i(d['low_issue_count']),
        invoices: i(d['invoices_checked']),
        settlements: i(d['settlements_checked']),
        banks: i(d['bank_transactions_checked']),
        claims: i(d['supplier_claims_checked']),
        missingCost: i(d['missing_cost_invoice_count']));
  }
}

class FinanceIntegrityIssue {
  final String key,
      category,
      severity,
      type,
      entityType,
      entityId,
      label,
      detail,
      action,
      status,
      note;
  final double? expected, actual, variance;
  const FinanceIntegrityIssue(
      {required this.key,
      required this.category,
      required this.severity,
      required this.type,
      required this.entityType,
      required this.entityId,
      required this.label,
      required this.expected,
      required this.actual,
      required this.variance,
      required this.detail,
      required this.action,
      required this.status,
      required this.note});
  factory FinanceIntegrityIssue.fromSupabase(Map<String, dynamic> d) {
    double? q(v) =>
        v == null ? null : (v is num ? v.toDouble() : double.tryParse('$v'));
    return FinanceIntegrityIssue(
        key: '${d['issue_key'] ?? ''}',
        category: '${d['category'] ?? ''}',
        severity: '${d['severity'] ?? 'low'}',
        type: '${d['issue_type'] ?? ''}',
        entityType: '${d['entity_type'] ?? ''}',
        entityId: '${d['entity_id'] ?? ''}',
        label: '${d['entity_label'] ?? ''}',
        expected: q(d['expected_value']),
        actual: q(d['actual_value']),
        variance: q(d['variance']),
        detail: '${d['detail'] ?? ''}',
        action: '${d['suggested_action'] ?? ''}',
        status: '${d['review_status'] ?? 'open'}',
        note: '${d['review_note'] ?? ''}');
  }
}

Future<FinanceIntegritySummary> fetchFinanceIntegritySummary() async {
  await requireAdminAccess();
  final r = await supabase.rpc('admin_finance_integrity_summary');
  final m = r is List && r.isNotEmpty ? r.first : r;
  if (m is Map)
    return FinanceIntegritySummary.fromSupabase(Map<String, dynamic>.from(m));
  throw Exception('Finance integrity summary could not be loaded.');
}

Future<List<FinanceIntegrityIssue>> fetchFinanceIntegrityIssues(
    {String status = 'attention',
    String severity = 'all',
    String category = 'all'}) async {
  await requireAdminAccess();
  final r = await supabase.rpc('admin_list_finance_integrity_issues', params: {
    'p_status': status,
    'p_severity': severity,
    'p_category': category,
    'p_limit': 250
  });
  return (r as List)
      .map((e) => FinanceIntegrityIssue.fromSupabase(
          Map<String, dynamic>.from(e as Map)))
      .toList();
}

Future<void> updateFinanceIntegrityReview(
    FinanceIntegrityIssue issue, String status, String note) async {
  await requireAdminAccess();
  await supabase.rpc('admin_update_finance_integrity_review', params: {
    'p_issue_key': issue.key,
    'p_status': status,
    'p_note': note.trim()
  });
}

class FinanceIntegrityScreen extends StatefulWidget {
  const FinanceIntegrityScreen({super.key});
  @override
  State<FinanceIntegrityScreen> createState() => _FinanceIntegrityScreenState();
}

class _FinanceIntegrityScreenState extends State<FinanceIntegrityScreen> {
  String _status = 'attention', _severity = 'all', _category = 'all';
  late Future<List<dynamic>> _future;
  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<dynamic>> _load() => Future.wait([
        fetchFinanceIntegritySummary(),
        fetchFinanceIntegrityIssues(
            status: _status, severity: _severity, category: _category)
      ]);
  Future<void> _refresh() async {
    final n = _load();
    setState(() => _future = n);
    await n;
  }

  Color _c(String s) => s == 'critical'
      ? FarmColors.danger
      : s == 'high'
          ? FarmColors.warning
          : s == 'medium'
              ? FarmColors.primary
              : FarmColors.mutedText;
  Future<void> _review(FinanceIntegrityIssue x, String status) async {
    final c = TextEditingController(text: x.note);
    final ok = await showDialog<bool>(
        context: context,
        builder: (d) => AlertDialog(
                title: Text(
                    '${status[0].toUpperCase()}${status.substring(1)} issue'),
                content: TextField(
                    controller: c,
                    maxLines: 3,
                    decoration: const InputDecoration(
                        labelText: 'Review note (optional)')),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.of(d).pop(false),
                      child: const Text('Cancel')),
                  ElevatedButton(
                      onPressed: () => Navigator.of(d).pop(true),
                      child: const Text('Save'))
                ]));
    if (ok == true) {
      try {
        await updateFinanceIntegrityReview(x, status, c.text);
        await _refresh();
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(friendlyAppError(e))));
      }
    }
    c.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: FarmColors.background,
      appBar: AppBar(title: const Text('Finance Integrity')),
      body: FutureBuilder<List<dynamic>>(
          future: _future,
          builder: (context, s) {
            if (s.connectionState == ConnectionState.waiting && s.data == null)
              return const Center(child: CircularProgressIndicator());
            if (s.hasError && s.data == null)
              return Center(child: Text(friendlyAppError(s.error!)));
            final d = s.data ?? const [];
            final sum = d.isNotEmpty ? d[0] as FinanceIntegritySummary : null;
            final rows = d.length > 1
                ? d[1] as List<FinanceIntegrityIssue>
                : <FinanceIntegrityIssue>[];
            return RefreshIndicator(
                onRefresh: _refresh,
                child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                    children: [
                      FarmCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(children: [
                                  Icon(Icons.verified_user_outlined,
                                      color: FarmColors.primary, size: 28),
                                  SizedBox(width: 10),
                                  Expanded(
                                      child: Text('Financial Integrity Checks',
                                          style: TextStyle(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 17)))
                                ]),
                                const SizedBox(height: 5),
                                const Text(
                                    'HPJ checks invoice maths, payment totals, credits/refunds, farmer settlements, supplier claims, bank matching and missing procurement cost. Reviews never rewrite historical finance records.',
                                    style: TextStyle(
                                        color: FarmColors.mutedText,
                                        fontSize: 10.5,
                                        height: 1.35,
                                        fontWeight: FontWeight.w600)),
                                if (sum != null) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                      '${sum.healthScore.toStringAsFixed(1)}% finance health • ${sum.attention} item(s) need attention',
                                      style: TextStyle(
                                          color: sum.critical > 0
                                              ? FarmColors.danger
                                              : FarmColors.primary,
                                          fontWeight: FontWeight.w900)),
                                  Text(
                                      '${sum.critical} critical • ${sum.high} high • ${sum.medium} medium • ${sum.missingCost} missing-cost invoice(s)',
                                      style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700))
                                ]
                              ])),
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                              children: [
                            'attention',
                            'open',
                            'acknowledged',
                            'resolved',
                            'ignored',
                            'all'
                          ]
                                  .map((x) => Padding(
                                      padding: const EdgeInsets.only(right: 6),
                                      child: ChoiceChip(
                                          label: Text(x == 'attention'
                                              ? 'Attention'
                                              : x[0].toUpperCase() +
                                                  x.substring(1)),
                                          selected: _status == x,
                                          onSelected: (_) {
                                            setState(() {
                                              _status = x;
                                              _future = _load();
                                            });
                                          })))
                                  .toList())),
                      const SizedBox(height: 7),
                      SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                              children: [
                            'all',
                            'critical',
                            'high',
                            'medium',
                            'low'
                          ]
                                  .map((x) => Padding(
                                      padding: const EdgeInsets.only(right: 6),
                                      child: ChoiceChip(
                                          label: Text(x == 'all'
                                              ? 'All severity'
                                              : x[0].toUpperCase() +
                                                  x.substring(1)),
                                          selected: _severity == x,
                                          onSelected: (_) {
                                            setState(() {
                                              _severity = x;
                                              _future = _load();
                                            });
                                          })))
                                  .toList())),
                      const SizedBox(height: 7),
                      DropdownButtonFormField<String>(
                          value: _category,
                          decoration:
                              const InputDecoration(labelText: 'Category'),
                          items: [
                            'all',
                            'invoice',
                            'credit_refund',
                            'farmer_settlement',
                            'supplier_claim',
                            'bank',
                            'cost'
                          ]
                              .map((x) => DropdownMenuItem(
                                  value: x,
                                  child: Text(x == 'all'
                                      ? 'All categories'
                                      : x.replaceAll('_', ' '))))
                              .toList(),
                          onChanged: (v) {
                            if (v != null)
                              setState(() {
                                _category = v;
                                _future = _load();
                              });
                          }),
                      const SizedBox(height: 12),
                      if (rows.isEmpty)
                        const FarmEmptyState(
                            icon: Icons.check_circle_outline,
                            title: 'No integrity issues in this view',
                            message:
                                'The selected finance checks currently have no matching exceptions.')
                      else
                        ...rows.map((x) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: FarmCard(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(children: [
                                        Expanded(
                                            child: Text(x.label,
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.w900))),
                                        Text(x.severity.toUpperCase(),
                                            style: TextStyle(
                                                color: _c(x.severity),
                                                fontSize: 9,
                                                fontWeight: FontWeight.w900))
                                      ]),
                                      const SizedBox(height: 3),
                                      Text(x.type.replaceAll('_', ' '),
                                          style: const TextStyle(
                                              color: FarmColors.primary,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800)),
                                      const SizedBox(height: 6),
                                      Text(x.detail,
                                          style: const TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w700)),
                                      if (x.expected != null ||
                                          x.actual != null) ...[
                                        const SizedBox(height: 5),
                                        Text(
                                            'Expected ${x.expected == null ? '—' : formatJmd(x.expected!)} • Actual ${x.actual == null ? '—' : formatJmd(x.actual!)}',
                                            style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700))
                                      ],
                                      const SizedBox(height: 5),
                                      Text(x.action,
                                          style: const TextStyle(
                                              color: FarmColors.mutedText,
                                              fontSize: 10,
                                              height: 1.3,
                                              fontWeight: FontWeight.w600)),
                                      if (x.note.trim().isNotEmpty) ...[
                                        const SizedBox(height: 5),
                                        Text('Review: ${x.note}',
                                            style: const TextStyle(
                                                fontStyle: FontStyle.italic,
                                                fontSize: 10))
                                      ],
                                      if (x.status == 'open' ||
                                          x.status == 'acknowledged') ...[
                                        const SizedBox(height: 8),
                                        Wrap(spacing: 6, children: [
                                          if (x.status == 'open')
                                            OutlinedButton(
                                                onPressed: () =>
                                                    _review(x, 'acknowledged'),
                                                child:
                                                    const Text('Acknowledge')),
                                          OutlinedButton(
                                              onPressed: () =>
                                                  _review(x, 'resolved'),
                                              child: const Text('Resolve')),
                                          TextButton(
                                              onPressed: () =>
                                                  _review(x, 'ignored'),
                                              child: const Text('Ignore'))
                                        ])
                                      ]
                                    ]))))
                    ]));
          }));
}
