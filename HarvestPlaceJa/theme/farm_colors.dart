part of harvest_place_app;

class FarmColors {
  // Soft premium farm-market palette.
  // The background is only a very light mint so white cards stay dominant.
  static const background = Color(0xFFF4F9F2);
  static const card = Color(0xFFFFFFFF);
  static const cardSoft = Color(0xFFFFFEFC);
  static const primary = Color(0xFF2D6741);
  static const primaryDark = Color(0xFF183B28);
  static const primarySoft = Color(0xFFEAF5E7);
  static const olive = Color(0xFF5F7651);
  static const accent = Color(0xFFDFA75A);
  static const accentSoft = Color(0xFFFFF3D9);
  static const text = Color(0xFF1E2A21);
  static const mutedText = Color(0xFF5F6A62);
  static const border = Color(0xFFD8E5D4);
  static const chipBackground = Color(0xFFEAF5E7);
  static const success = Color(0xFF4F8A5B);
  static const successSoft = Color(0xFFEAF5E7);
  static const warning = Color(0xFF966012);
  static const warningSoft = Color(0xFFFFF1D2);
  static const danger = Color(0xFFB44A3A);
  static const dangerSoft = Color(0xFFFFECE8);
  static const shadow = Color(0xFF1B2A1D);

  // Backward-compatible aliases used throughout the existing single-file app.
  static const cream = background;
  static const green = primary;
  static const deepGreen = primaryDark;
  static const lightGreen = primarySoft;
  static const gold = accent;
  static const ink = text;
  static const muted = mutedText;
  static const line = border;
  static const error = danger;
  static const surface = card;
}
