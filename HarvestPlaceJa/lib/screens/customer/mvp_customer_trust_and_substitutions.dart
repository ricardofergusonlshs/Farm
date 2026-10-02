part of harvest_place_app;

// ============================================================================
// HPJ CUSTOMER TRUST + FRESH-PRODUCE SUBSTITUTION MVP
// ============================================================================

class HpjOrderTrustCard extends StatelessWidget {
  const HpjOrderTrustCard({super.key});

  Widget _item(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F7EF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFDCE8D8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: FarmColors.green),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: FarmColors.deepGreen,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FarmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.verified_user_outlined, color: FarmColors.green, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'HPJ Order Protection',
                  style: TextStyle(
                    color: FarmColors.ink,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Your order stays private, is tracked through fulfillment, and can include packing photo proof before collection or delivery.',
            style: TextStyle(
              color: FarmColors.mutedText,
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 11),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              _item(Icons.lock_outline_rounded, 'Private order'),
              _item(Icons.agriculture_outlined, 'Jamaican farmer supply'),
              _item(Icons.photo_camera_outlined, 'Box Photo Proof'),
              _item(Icons.route_outlined, 'Order tracking'),
              _item(Icons.support_agent_outlined, 'HPJ support'),
            ],
          ),
        ],
      ),
    );
  }
}

class HpjCustomerSubstitutionCard extends StatefulWidget {
  final String orderId;
  final Future<void> Function()? onChanged;

  const HpjCustomerSubstitutionCard({
    super.key,
    required this.orderId,
    this.onChanged,
  });

  @override
  State<HpjCustomerSubstitutionCard> createState() => _HpjCustomerSubstitutionCardState();
}

class _HpjCustomerSubstitutionCardState extends State<HpjCustomerSubstitutionCard> {
  late Future<List<HpjOrderSubstitution>> _future;
  String _workingId = '';

  @override
  void initState() {
    super.initState();
    _future = fetchHpjCustomerOrderSubstitutions(widget.orderId);
  }

  void _reload() {
    if (!mounted) return;
    setState(() {
      _future = fetchHpjCustomerOrderSubstitutions(widget.orderId);
    });
  }

  Future<void> _respond(HpjOrderSubstitution item, bool accept) async {
    if (_workingId.isNotEmpty) return;
    setState(() => _workingId = item.id);
    try {
      await hpjCustomerRespondToSubstitution(substitution: item, accept: accept);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            accept
                ? 'Replacement accepted. Your order has been updated.'
                : 'Replacement rejected. HPJ has been notified.',
          ),
        ),
      );
      _reload();
      await widget.onChanged?.call();
    } catch (error, stackTrace) {
      unawaited(HpjReliability.recordNonFatal(
        error,
        stackTrace: stackTrace,
        area: 'substitution',
        eventKey: 'customer_response_failed',
        metadata: {'order_id': widget.orderId},
      ));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyAppError(error))),
      );
    } finally {
      if (mounted) setState(() => _workingId = '');
    }
  }

  Widget _statusChip(HpjOrderSubstitution item) {
    final awaiting = item.awaitingCustomer;
    final accepted = item.accepted;
    final color = awaiting
        ? FarmColors.warning
        : accepted
            ? FarmColors.green
            : FarmColors.mutedText;
    final background = awaiting
        ? FarmColors.warningSoft
        : accepted
            ? FarmColors.lightGreen
            : FarmColors.cardSoft;
    final label = awaiting
        ? 'Your approval'
        : accepted
            ? 'Accepted'
            : item.rejected
                ? 'Rejected'
                : friendlyLabel(item.status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _substitution(HpjOrderSubstitution item) {
    final working = _workingId == item.id;
    final more = item.priceDifference > 0.009;
    final less = item.priceDifference < -0.009;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: item.awaitingCustomer ? const Color(0xFFFFFBF0) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: item.awaitingCustomer ? const Color(0xFFE8D59A) : FarmColors.line,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Fresh item replacement',
                  style: const TextStyle(
                    color: FarmColors.ink,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _statusChip(item),
            ],
          ),
          const SizedBox(height: 11),
          Text(
            '${item.originalProductName}  →  ${item.replacementProductName}',
            style: const TextStyle(
              color: FarmColors.deepGreen,
              fontSize: 13,
              height: 1.3,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            '${item.quantity} × ${formatJmd(item.replacementUnitPrice)} • Replacement line ${formatJmd(item.replacementLineTotal)}',
            style: const TextStyle(
              color: FarmColors.mutedText,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (more || less) ...[
            const SizedBox(height: 5),
            Text(
              more
                  ? 'This replacement is ${formatJmd(item.priceDifference)} more for this line.'
                  : 'This replacement is ${formatJmd(item.priceDifference.abs())} less for this line.',
              style: TextStyle(
                color: more ? FarmColors.warning : FarmColors.green,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          if (item.adminNote.trim().isNotEmpty) ...[
            const SizedBox(height: 7),
            Text(
              item.adminNote.trim(),
              style: const TextStyle(
                color: FarmColors.ink,
                fontSize: 11.5,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (item.awaitingCustomer) ...[
            const SizedBox(height: 12),
            const Text(
              'HPJ will only change this item after you approve it.',
              style: TextStyle(
                color: FarmColors.mutedText,
                fontSize: 11.2,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: working ? null : () => _respond(item, false),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: working ? null : () => _respond(item, true),
                    icon: working
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_rounded),
                    label: Text(working ? 'Updating...' : 'Accept'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<HpjOrderSubstitution>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }
        final items = snapshot.data ?? const <HpjOrderSubstitution>[];
        if (items.isEmpty) return const SizedBox.shrink();

        return FarmCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.swap_horiz_rounded, color: FarmColors.green, size: 21),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Fresh Produce Replacement',
                      style: TextStyle(
                        color: FarmColors.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'If a fresh item changes after ordering, HPJ can propose a replacement here instead of changing your order without your approval.',
                style: TextStyle(
                  color: FarmColors.mutedText,
                  fontSize: 12,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              for (var i = 0; i < items.length; i++) ...[
                _substitution(items[i]),
                if (i != items.length - 1) const SizedBox(height: 9),
              ],
            ],
          ),
        );
      },
    );
  }
}
