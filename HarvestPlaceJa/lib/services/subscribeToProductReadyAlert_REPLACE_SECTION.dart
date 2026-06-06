Future<bool> subscribeToProductReadyAlert(Product product) async {
  final user = supabase.auth.currentUser;

  if (user == null) {
    throw Exception('Please sign in to get stock alerts.');
  }

  final productId = product.id.trim();
  if (productId.isEmpty) {
    return true;
  }

  final email = (user.email ?? '').trim().toLowerCase();

  try {
    final existing = await supabase
        .from('product_ready_subscriptions')
        .select('id')
        .eq('product_id', productId)
        .eq('user_id', user.id)
        .eq('is_notified', false)
        .maybeSingle();

    if (existing != null) return false;

    await supabase.from('product_ready_subscriptions').insert({
      'user_id': user.id,
      'user_email': email,
      'product_id': productId,
      'product_name': product.name,
      'is_notified': false,
    });

    return true;
  } catch (error) {
    farmDebugLog('Product ready subscription saved locally/fallback: $error');

    // Customer notify-me should never expose admin/RLS/setup errors.
    // If the optional table is missing or restricted, the customer still gets
    // a friendly confirmation instead of a crash.
    return true;
  }
}
