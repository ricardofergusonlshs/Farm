part of harvest_place_app;

void _syncKeyboardStateSafely() {
  if (!kIsWeb) return;
  try {
    HardwareKeyboard.instance.syncKeyboardState().catchError((_) {});
  } catch (_) {}
}

bool _isBrowserPreviewKeyboardAssertion(Object error, StackTrace? stack) {
  final errorText = error.toString();
  final stackText = stack?.toString() ?? '';

  return errorText.contains('hardware_keyboard.dart') ||
      stackText.contains('hardware_keyboard.dart') ||
      errorText.contains('_pressedKeys') ||
      errorText.contains('KeyDownEvent') ||
      errorText.contains('KeyUpEvent') ||
      errorText.contains('mouse_tracker.dart') ||
      stackText.contains('mouse_tracker.dart') ||
      errorText.contains('MouseTracker') ||
      stackText.contains('MouseTracker') ||
      errorText.contains('_dependents.isEmpty') ||
      stackText.contains('_dependents.isEmpty') ||
      errorText.contains('framework.dart') &&
          errorText.contains('Assertion failed') ||
      stackText.contains('framework.dart') &&
          errorText.contains('Assertion failed') ||
      errorText
          .contains('Tried to build dirty widget in the wrong build scope') ||
      errorText.contains('Unexpected null value');
}

void _installBrowserPreviewKeyboardWorkaround() {
  if (!kIsWeb) return;

  final previousErrorWidgetBuilder = ErrorWidget.builder;
  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (_isBrowserPreviewKeyboardAssertion(details.exception, details.stack)) {
      _syncKeyboardStateSafely();
      return const SizedBox.shrink();
    }
    return previousErrorWidgetBuilder(details);
  };

  final previousFlutterErrorHandler = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    if (_isBrowserPreviewKeyboardAssertion(details.exception, details.stack)) {
      _syncKeyboardStateSafely();
      return;
    }

    if (previousFlutterErrorHandler != null) {
      previousFlutterErrorHandler(details);
    } else {
      FlutterError.presentError(details);
    }
  };

  final previousPlatformErrorHandler = PlatformDispatcher.instance.onError;
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    if (_isBrowserPreviewKeyboardAssertion(error, stack)) {
      _syncKeyboardStateSafely();
      return true;
    }

    if (previousPlatformErrorHandler != null) {
      return previousPlatformErrorHandler(error, stack);
    }

    return false;
  };
}

const List<String> productCategoryOptions = [
  'Vegetables',
  'Fruits',
  'Ground Provisions',
  'Herbs',
  'Eggs',
  'Honey',
  'Dairy',
  'Drinks',
  'Prepared Foods',
  'Other',
];

String normalizeProductCategory(String? value) {
  final clean = (value ?? '').trim();
  if (clean.isEmpty) return productCategoryOptions.first;

  for (final option in productCategoryOptions) {
    if (option.toLowerCase() == clean.toLowerCase()) return option;
  }

  final lower = clean.toLowerCase();
  if (lower == 'others') return 'Other';

  return titleCaseWords(clean);
}

String titleCaseWords(String value) {
  return value
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .map((part) => part[0].toUpperCase() + part.substring(1).toLowerCase())
      .join(' ');
}

String shortIdLabel(String id, {int length = 6}) {
  final clean = id.trim();
  if (clean.length <= length) return clean.toUpperCase();
  return clean.substring(0, length).toUpperCase();
}

String formatJmd(double value) => 'J\$${value.toStringAsFixed(2)}';

double? parseNullableDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  final text = value.toString().trim();
  if (text.isEmpty) return null;
  return double.tryParse(text);
}

String friendlyLabel(String value) {
  final clean = value.trim();
  if (clean.isEmpty) return clean;
  return clean
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => part[0].toUpperCase() + part.substring(1).toLowerCase())
      .join(' ');
}

String formatPaymentStatus(String value) {
  final clean = value.trim().toLowerCase();
  if (clean.isEmpty) return 'Unpaid';
  if (clean == 'pending_verification') {
    return 'Awaiting bank transfer verification';
  }
  if (clean == 'pending') return 'Pending';
  return friendlyLabel(clean);
}

String formatPaymentStatusForMethod({
  required String paymentMethod,
  required String paymentStatus,
}) {
  final method = paymentMethod.trim().toLowerCase();
  final status = paymentStatus.trim().toLowerCase();

  if (method == 'bank_transfer' &&
      (status == 'unpaid' || status == 'pending')) {
    return 'Awaiting bank transfer verification';
  }

  return formatPaymentStatus(paymentStatus);
}

double moneyAmountFromText(String? text, String label) {
  final source = text ?? '';
  if (source.trim().isEmpty) return 0;

  final pattern = RegExp(
    '${RegExp.escape(label)}\\s*:\\s*-?J?\\\$?\\s*([0-9,]+(?:\\.[0-9]+)?)',
    caseSensitive: false,
  );
  final match = pattern.firstMatch(source);
  if (match == null) return 0;

  final raw = match.group(1)?.replaceAll(',', '').trim() ?? '';
  return double.tryParse(raw) ?? 0;
}

double resolvedDeliveryFeeForOrder({
  required String fulfillmentType,
  required double rawDeliveryFee,
  required String? notes,
}) {
  if (fulfillmentType.trim().toLowerCase() != 'delivery') return 0;
  if (rawDeliveryFee > 0) return rawDeliveryFee;
  return moneyAmountFromText(notes, 'Delivery fee');
}

double resolvedOrderTotal({
  required String fulfillmentType,
  required double rawTotal,
  required double subtotal,
  required double deliveryFee,
  required double discountAmount,
}) {
  final expected = (subtotal + deliveryFee - discountAmount)
      .clamp(0, double.infinity)
      .toDouble();

  if (fulfillmentType.trim().toLowerCase() == 'delivery' &&
      deliveryFee > 0 &&
      rawTotal < expected) {
    return expected;
  }

  if (rawTotal <= 0 && expected > 0) return expected;
  return rawTotal;
}

String formatPaymentMethod(String value) {
  switch (value.trim()) {
    case 'cash_on_pickup':
      return 'Pay when you collect';
    case 'cash_on_delivery':
      return 'Cash on Delivery';
    case 'bank_transfer':
      return 'Bank Transfer';
    case 'stripe_card':
      return 'Card';
    default:
      return 'Pay when you collect';
  }
}

String formatFulfillmentType(String value) {
  return value.trim() == 'delivery' ? 'Home Delivery' : 'Farm Pickup';
}

String formatScheduleText(String? scheduledDate, String? scheduledTime) {
  final date = scheduledDate?.trim() ?? '';
  final time = scheduledTime?.trim() ?? '';
  if (date.isEmpty && time.isEmpty) return 'Not scheduled';
  if (date.isEmpty) return time;
  if (time.isEmpty) return date;
  return '$date • $time';
}

String formatCustomerDateTime(DateTime? value) {
  if (value == null) return 'Just now';

  const months = [
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

  final local = value.toLocal();
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final meridiem = local.hour >= 12 ? 'PM' : 'AM';
  final month = months[local.month - 1];

  return '$month ${local.day}, ${local.year} • $hour:$minute $meridiem';
}

bool isValidHostedImageUrl(String? value) {
  final clean = value?.trim() ?? '';
  if (clean.isEmpty) return false;

  final lower = clean.toLowerCase();
  const blockedFragments = [
    'your-supabase-url',
    'image.network',
    'example.com',
    'placeholder',
    'null',
  ];

  if (blockedFragments.any(lower.contains)) return false;

  final uri = Uri.tryParse(clean);
  if (uri == null || uri.host.trim().isEmpty) return false;
  if (!(uri.scheme == 'http' || uri.scheme == 'https')) return false;

  return true;
}

String? cleanHostedImageUrl(String? value) {
  final clean = value?.trim();
  if (clean == null || clean.isEmpty) return null;
  return isValidHostedImageUrl(clean) ? clean : null;
}

const String productImageStorageBucket = 'product-images';

const List<String> _defaultHomeHeroImageUrls = [
  'https://images.unsplash.com/photo-1542838132-92c53300491e?auto=format&fit=crop&w=900&q=80',
  'https://images.unsplash.com/photo-1518843875459-f738682238a6?auto=format&fit=crop&w=900&q=80',
  'https://images.unsplash.com/photo-1523348837708-15d4a09cfac2?auto=format&fit=crop&w=900&q=80',
];

DateTime startOfCurrentHarvestWeek([DateTime? date]) {
  final now = date ?? DateTime.now();
  final localDateOnly = DateTime(now.year, now.month, now.day);

  // Monday is 1 in Dart. This makes Monday the beginning of the harvest week.
  return localDateOnly.subtract(Duration(days: localDateOnly.weekday - 1));
}

DateTime endOfCurrentHarvestWeek([DateTime? date]) {
  return startOfCurrentHarvestWeek(date).add(const Duration(days: 7));
}

String harvestWeekRangeLabel([DateTime? date]) {
  final start = startOfCurrentHarvestWeek(date);
  final endInclusive = endOfCurrentHarvestWeek(date).subtract(
    const Duration(days: 1),
  );

  String shortDate(DateTime value) {
    return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}';
  }

  return '${shortDate(start)} - ${shortDate(endInclusive)}';
}

DateTime? parseProductDate(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  if (text.isEmpty) return null;
  return DateTime.tryParse(text);
}

bool isDateInCurrentHarvestWeek(DateTime? date) {
  if (date == null) return false;

  final localDate = DateTime(date.year, date.month, date.day);
  final start = startOfCurrentHarvestWeek();
  final end = endOfCurrentHarvestWeek();

  return !localDate.isBefore(start) && localDate.isBefore(end);
}

bool isProductHarvestedThisWeek(Product product) {
  return isDateInCurrentHarvestWeek(product.harvestDate ?? product.createdAt);
}

String todayIsoDate() {
  final now = DateTime.now();
  return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

String todayIsoDateFrom(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

String shortProductDate(DateTime? date) {
  if (date == null) return 'No date';
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

int productFreshnessScore(Product product) {
  final date = product.harvestDate ?? product.createdAt;
  if (date == null) return 75;

  final now = DateTime.now();
  final productDate = DateTime(date.year, date.month, date.day);
  final today = DateTime(now.year, now.month, now.day);
  final ageDays = today.difference(productDate).inDays;

  if (ageDays <= 1) return 100;
  if (ageDays <= 3) return 94;
  if (ageDays <= 7) return 88;
  if (ageDays <= 14) return 76;
  if (ageDays <= 30) return 64;
  return 52;
}

String productFreshnessLabel(Product product) {
  final score = productFreshnessScore(product);
  if (score >= 85) return 'Fresh';
  if (score >= 70) return 'Good';
  return 'Pantry Stable';
}

String productFreshnessDescription(Product product) {
  final score = productFreshnessScore(product);
  if (score >= 85) return 'Fresh pick with strong freshness quality.';
  if (score >= 70) return 'Good quality item. Use soon for best flavor.';
  return 'Best used soon. Check freshness before adding delicate items.';
}

Color productFreshnessColor(Product product) {
  final score = productFreshnessScore(product);
  if (score >= 85) return FarmColors.success;
  if (score >= 70) return FarmColors.warning;
  return FarmColors.mutedText;
}

String browserNotificationTag({
  required String title,
  required String body,
  String? orderId,
  String? type,
}) {
  final cleanType = (type ?? 'farm').trim().toLowerCase();
  final cleanOrderId = orderId?.trim() ?? '';
  final cleanTitle = title.trim().toLowerCase();
  final cleanBody = body.trim().toLowerCase();

  // Order notifications can be emitted by both the immediate checkout flow and
  // the realtime notification listener. Use a stable tag that ignores small body
  // wording differences so the same order/title only alerts the customer once.
  final source = cleanOrderId.isNotEmpty
      ? [cleanType, cleanOrderId, cleanTitle].join('|')
      : [cleanType, cleanTitle, cleanBody].join('|');

  return 'harvest_${source.hashCode.abs()}';
}

bool isImportantBrowserNotification({
  required String title,
  required String message,
  required String type,
}) {
  final text = '${title.trim()} ${message.trim()} ${type.trim()}'.toLowerCase();

  if (text.contains('ready')) return true;
  if (text.contains('delivered')) return true;
  if (text.contains('delivery')) return true;
  if (text.contains('hold')) return true;
  if (text.contains('placed')) return true;
  if (text.contains('payment')) return true;
  if (text.contains('support')) return true;
  if (text.contains('review')) return true;
  if (text.contains('stock')) return true;
  if (type.trim().toLowerCase() == 'admin') return true;

  return false;
}

bool isVisibleCustomerProduct(Product product) {
  return product.isCustomerVisible;
}

List<Product> cleanRecentlyViewedProducts(List<Product> products) {
  return uniqueVisibleProducts(products, limit: 10);
}

final supabase = Supabase.instance.client;

bool isNotificationsPermissionError(Object error) {
  final text = error.toString().toLowerCase();
  return text.contains('permission denied for table notifications') ||
      (text.contains('notifications') && text.contains('42501'));
}

String friendlyAppError(Object error) {
  final text = error.toString();
  final lower = text.toLowerCase();
  if (lower.contains('over_email_send_rate_limit')) {
    return 'Too many reset emails were sent. Please wait a few minutes and try again.';
  }
  if (lower.contains('failed host lookup') ||
      lower.contains('socketexception') ||
      lower.contains('network')) {
    return 'Connection problem. Please check your internet and try again.';
  }
  if (lower.contains('jwt') ||
      lower.contains('auth') ||
      lower.contains('session')) {
    return 'Your session may have expired. Please sign in again.';
  }
  if (lower.contains('permission') ||
      lower.contains('policy') ||
      lower.contains('42501') ||
      lower.contains('row level security')) {
    return 'This action is not available for your account yet.';
  }
  if (lower.contains('rpc') ||
      lower.contains('postgrest') ||
      lower.contains('supabase') ||
      lower.contains('storage') ||
      lower.contains('bucket') ||
      lower.contains('null') ||
      lower.contains('exception') ||
      lower.contains('unsupported operation') ||
      lower.contains('not found')) {
    return 'Something went wrong. Please try again.';
  }

  final clean = text.replaceAll('Exception: ', '').trim();
  if (clean.isEmpty) return 'Something went wrong. Please try again.';
  if (clean.length > 140) return 'Something went wrong. Please try again.';
  return clean;
}

String friendlyAuthErrorMessage(
  AuthException error, {
  required bool isRegister,
}) {
  final message = error.message.trim();
  final lower = message.toLowerCase();

  if (lower.contains('invalid login credentials') ||
      lower.contains('invalid credentials') ||
      lower.contains('invalid email or password')) {
    return 'Email or password is incorrect. Use Forgot Password to reset this account, then try again.';
  }

  if (lower.contains('email not confirmed') ||
      lower.contains('confirm your email')) {
    return 'Please confirm this email address before signing in.';
  }

  if (lower.contains('rate limit') ||
      lower.contains('over_email_send_rate_limit') ||
      lower.contains('too many')) {
    return 'Too many attempts. Please wait a few minutes, then try again.';
  }

  if (lower.contains('network') ||
      lower.contains('failed host lookup') ||
      lower.contains('socketexception')) {
    return 'Connection problem. Please check your internet and try again.';
  }

  if (message.isNotEmpty &&
      message.length <= 120 &&
      !lower.contains('supabase') &&
      !lower.contains('postgrest') &&
      !lower.contains('exception')) {
    return isRegister
        ? 'Could not create account: $message'
        : 'Could not sign in: $message';
  }

  return isRegister
      ? 'Could not create account. Please check your details and try again.'
      : 'Could not sign in. Please check your email and password.';
}

bool get hasSupabaseSession =>
    supabase.auth.currentSession != null || supabase.auth.currentUser != null;

bool get isAnonymousSupabaseUser {
  final user = supabase.auth.currentUser;
  if (user == null) return false;

  final appMetadata = user.appMetadata;
  final userMetadata = user.userMetadata ?? const <String, dynamic>{};
  final provider =
      (appMetadata['provider'] ?? '').toString().trim().toLowerCase();
  final providersValue = appMetadata['providers'];

  final hasAnonymousProvider = providersValue is List
      ? providersValue
          .map((item) => item.toString().trim().toLowerCase())
          .contains('anonymous')
      : providersValue.toString().trim().toLowerCase().contains('anonymous');

  return provider == 'anonymous' ||
      hasAnonymousProvider ||
      _metadataValueIsTrue(appMetadata['is_anonymous']) ||
      _metadataValueIsTrue(appMetadata['isAnonymous']) ||
      _metadataValueIsTrue(userMetadata['is_anonymous']) ||
      _metadataValueIsTrue(userMetadata['isAnonymous']);
}

bool get isLoggedIn => hasSupabaseSession && !isAnonymousSupabaseUser;

Future<bool> isSubscribedToProductReadyAlert(Product product) async {
  final user = supabase.auth.currentUser;
  if (user == null) return false;
  try {
    final existing = await supabase
        .from('product_ready_subscriptions')
        .select('id')
        .eq('product_id', product.id)
        .eq('user_id', user.id)
        .eq('is_notified', false)
        .maybeSingle();
    return existing != null;
  } catch (_) {
    return false;
  }
}

String formatPlanDate(DateTime? value) {
  if (value == null) return 'To be confirmed';
  return formatCustomerDateTime(value).split(' • ').first;
}

bool get isSignedIn => isLoggedIn;

bool get isFarmerUser => currentUserRole == 'farmer';

Future<bool> isCurrentUserFarmerFromDatabase() async {
  final user = supabase.auth.currentUser;
  if (user == null) return false;

  try {
    final response = await supabase
        .from('farmer_profiles')
        .select('id, verification_status')
        .eq('user_id', user.id)
        .maybeSingle();

    if (response == null) return false;
    final status = (response['verification_status'] ?? '').toString();
    return status == 'approved' || status == 'pending';
  } catch (error) {
    farmDebugLog('Farmer role check failed: $error');
    return currentUserRole == 'farmer';
  }
}

String safeReviewDisplayName({
  String? profileName,
  String? reviewName,
  String? metadataName,
  String? email,
}) {
  for (final candidate in [profileName, reviewName, metadataName]) {
    final clean = _cleanReviewNameCandidate(candidate);
    if (clean.isNotEmpty) return clean;
  }

  // Email is intentionally not used as a fallback for reviews.
  return 'Verified customer';
}
