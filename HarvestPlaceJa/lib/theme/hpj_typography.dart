part of harvest_place_app;

/// Shared HPJ typography system.
///
/// The goal is to improve readability on phones without turning the interface
/// into a large-text redesign. The mobile text scaler raises only the smallest
/// type sizes aggressively; headings receive little or no extra scaling.
class HpjTypography {
  HpjTypography._();

  static const double pageTitle = 26;
  static const double appBarTitle = 24;
  static const double sectionTitle = 20;
  static const double cardTitle = 17;
  static const double bodyLarge = 15.5;
  static const double body = 15;
  static const double button = 15.5;
  static const double input = 15.5;
  static const double label = 14;
  static const double helper = 13;
  static const double compact = 12.5;

  static const TextTheme textTheme = TextTheme(
    displayLarge: TextStyle(
      fontSize: 32,
      height: 1.12,
      fontWeight: FontWeight.w900,
      color: FarmColors.ink,
    ),
    displayMedium: TextStyle(
      fontSize: 28,
      height: 1.14,
      fontWeight: FontWeight.w900,
      color: FarmColors.ink,
    ),
    displaySmall: TextStyle(
      fontSize: pageTitle,
      height: 1.16,
      fontWeight: FontWeight.w900,
      color: FarmColors.ink,
    ),
    headlineLarge: TextStyle(
      fontSize: 24,
      height: 1.18,
      fontWeight: FontWeight.w900,
      color: FarmColors.ink,
    ),
    headlineMedium: TextStyle(
      fontSize: 22,
      height: 1.2,
      fontWeight: FontWeight.w900,
      color: FarmColors.ink,
    ),
    headlineSmall: TextStyle(
      fontSize: sectionTitle,
      height: 1.22,
      fontWeight: FontWeight.w900,
      color: FarmColors.ink,
    ),
    titleLarge: TextStyle(
      fontSize: 18,
      height: 1.25,
      fontWeight: FontWeight.w900,
      color: FarmColors.ink,
    ),
    titleMedium: TextStyle(
      fontSize: cardTitle,
      height: 1.28,
      fontWeight: FontWeight.w800,
      color: FarmColors.ink,
    ),
    titleSmall: TextStyle(
      fontSize: 15.5,
      height: 1.3,
      fontWeight: FontWeight.w800,
      color: FarmColors.ink,
    ),
    bodyLarge: TextStyle(
      fontSize: bodyLarge,
      height: 1.42,
      fontWeight: FontWeight.w500,
      color: FarmColors.ink,
    ),
    bodyMedium: TextStyle(
      fontSize: body,
      height: 1.4,
      fontWeight: FontWeight.w500,
      color: FarmColors.ink,
    ),
    bodySmall: TextStyle(
      fontSize: helper,
      height: 1.4,
      fontWeight: FontWeight.w500,
      color: FarmColors.muted,
    ),
    labelLarge: TextStyle(
      fontSize: button,
      height: 1.2,
      fontWeight: FontWeight.w800,
      color: FarmColors.ink,
    ),
    labelMedium: TextStyle(
      fontSize: label,
      height: 1.25,
      fontWeight: FontWeight.w700,
      color: FarmColors.ink,
    ),
    labelSmall: TextStyle(
      fontSize: compact,
      height: 1.3,
      fontWeight: FontWeight.w700,
      color: FarmColors.muted,
    ),
  );

  /// Applies a gentle, non-linear readability lift on mobile.
  ///
  /// Tiny text receives the most help, normal body text receives a small lift,
  /// and large headings are intentionally left almost unchanged. The user's
  /// platform accessibility scaler is applied afterwards, so Android text-size
  /// preferences continue to work.
  static TextScaler mobileTextScaler(TextScaler platformScaler) {
    return _HpjReadableTextScaler(platformScaler);
  }

  static double _readableBaseSize(double fontSize) {
    if (!fontSize.isFinite || fontSize <= 0) return fontSize;

    // Very small sizes are usually badges, dense data, or secondary metadata.
    // Keep them compact, but prevent them from becoming illegible on phones.
    if (fontSize <= 7.5) return 10.0;
    if (fontSize <= 8.5) return 10.5;
    if (fontSize <= 9.5) return 11.0;
    if (fontSize <= 10.5) return 11.7;
    if (fontSize <= 11.5) return 12.3;
    if (fontSize <= 12.5) return 13.2;
    if (fontSize <= 13.5) return 14.0;
    if (fontSize <= 14.5) return 14.8;
    if (fontSize <= 16.0) return fontSize + 0.4;
    if (fontSize <= 18.0) return fontSize + 0.35;
    if (fontSize <= 20.0) return fontSize + 0.2;

    return fontSize;
  }
}

@immutable
class _HpjReadableTextScaler extends TextScaler {
  final TextScaler platformScaler;

  const _HpjReadableTextScaler(this.platformScaler);

  @override
  double scale(double fontSize) {
    return platformScaler.scale(HpjTypography._readableBaseSize(fontSize));
  }

  @override
  double get textScaleFactor => platformScaler.textScaleFactor;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is _HpjReadableTextScaler &&
            other.platformScaler == platformScaler;
  }

  @override
  int get hashCode => platformScaler.hashCode;
}
