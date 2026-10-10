import 'package:flutter/material.dart';

/// Push a photo viewer onto the current route, rather than replacing Orders.
Future<void> hpjOpenOrderPhotos(
  BuildContext context, {
  required Widget photoScreen,
}) async {
  await Navigator.of(context).push<void>(
    MaterialPageRoute<void>(builder: (_) => photoScreen),
  );
  // Photo screen's close/back action should call Navigator.pop(context).
}

/// A reusable app bar back button that respects the navigation stack.
Widget hpjContextBackButton(BuildContext context) => IconButton(
  tooltip: 'Back',
  icon: const Icon(Icons.arrow_back),
  onPressed: () async {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      // Do not silently redirect to Admin Home; caller can supply a root action.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You are already at the first screen.')),
      );
    }
  },
);

/// Use a local state update for search/filter; do not navigate to Home.
class HpjShopFilterController extends ChangeNotifier {
  String query = '';
  String category = '';
  String nutrient = '';
  double? maximumPrice;

  void update({
    String? query,
    String? category,
    String? nutrient,
    double? maximumPrice,
    bool clearMaximumPrice = false,
  }) {
    if (query != null) this.query = query.trim();
    if (category != null) this.category = category.trim();
    if (nutrient != null) this.nutrient = nutrient.trim();
    if (clearMaximumPrice) {
      this.maximumPrice = null;
    } else if (maximumPrice != null) {
      this.maximumPrice = maximumPrice;
    }
    notifyListeners();
  }

  bool matches({
    required String name,
    required String category,
    required Iterable<String> nutrients,
    required double price,
  }) {
    final q = query.toLowerCase();
    return (q.isEmpty || name.toLowerCase().contains(q)) &&
        (this.category.isEmpty ||
            category.toLowerCase() == this.category.toLowerCase()) &&
        (nutrient.isEmpty ||
            nutrients.any((n) => n.toLowerCase() == nutrient.toLowerCase())) &&
        (maximumPrice == null || price <= maximumPrice!);
  }
}
