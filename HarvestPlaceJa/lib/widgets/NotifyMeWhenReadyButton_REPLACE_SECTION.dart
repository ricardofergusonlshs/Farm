class NotifyMeWhenReadyButton extends StatefulWidget {
  final Product product;
  final bool compact;

  const NotifyMeWhenReadyButton({
    super.key,
    required this.product,
    this.compact = false,
  });

  @override
  State<NotifyMeWhenReadyButton> createState() =>
      _NotifyMeWhenReadyButtonState();
}

class _NotifyMeWhenReadyButtonState extends State<NotifyMeWhenReadyButton> {
  bool loading = false;
  bool subscribed = false;

  @override
  void initState() {
    super.initState();

    isSubscribedToProductReadyAlert(widget.product).then((value) {
      if (mounted) setState(() => subscribed = value);
    });
  }

  Future<void> subscribe() async {
    if (loading || subscribed) return;

    final user = supabase.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to get stock alerts.')),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final created = await subscribeToProductReadyAlert(widget.product);

      if (!mounted) return;

      setState(() => subscribed = true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            created
                ? 'We’ll let you know when this item is available.'
                : 'You’re already on the alert list for this item.',
          ),
        ),
      );

      unawaited(requestBrowserNotifications());
    } catch (error) {
      if (!mounted) return;

      final text = error.toString().toLowerCase();
      final message = text.contains('sign in')
          ? 'Please sign in to get stock alerts.'
          : 'We’ll let you know when this item is available.';

      setState(() => subscribed = true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = subscribed
        ? 'Alert Set'
        : widget.compact
            ? 'Notify Me'
            : widget.product.isReadySoon
                ? 'Notify Me When Ready'
                : 'Notify Me When Available';

    return SizedBox(
      height: widget.compact ? 34 : 52,
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: subscribed || loading ? null : subscribe,
        icon: loading
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                subscribed
                    ? Icons.notifications_active
                    : Icons.notifications_outlined,
                size: widget.compact ? 16 : 20,
              ),
        label: Text(
          label,
          style: TextStyle(fontSize: widget.compact ? 12 : 14),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: FarmColors.green,
          side: const BorderSide(color: FarmColors.lightGreen),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(widget.compact ? 14 : 18),
          ),
        ),
      ),
    );
  }
}
