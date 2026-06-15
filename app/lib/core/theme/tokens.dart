import 'package:flutter/widgets.dart';

/// Viele design tokens — the single source of truth for color, radius, spacing,
/// and elevation. Mirrors `docs/design.md` §2/§4. Never hard-code hex in widgets;
/// reference these.
abstract final class AppColors {
  static const canvas = Color(0xFFF6F1E8); // warm cream — app background
  static const paper = Color(0xFFFCF8F1); // raised surfaces
  static const sand = Color(0xFFEFE7D8); // dividers / secondary fills
  static const taupe = Color(0xFFD9CDBA); // deeper neutral fill
  static const ink = Color(0xFF1E1A14); // primary text / dark buttons / + button
  static const ink2 = Color(0xFF766C5C); // secondary text
  static const ink3 = Color(0xFFA89C88); // meta / placeholder
  static const line = Color(0xFFE6DCCB); // hairline borders
  static const match = Color(0xFF2FA565); // the single match accent
  static const matchDark = Color(0xFF1F7D4A); // match text on light / success
  static const ring = Color(0xFFE9C9B6); // avatar ring
  static const onInk = Color(0xFFF6F1E8); // text/icons on dark surfaces
}

/// Spacing scale (pt). Screen horizontal margin = [s20].
abstract final class AppSpacing {
  static const s4 = 4.0;
  static const s8 = 8.0;
  static const s12 = 12.0;
  static const s16 = 16.0;
  static const s20 = 20.0; // screen margin
  static const s24 = 24.0;
  static const s32 = 32.0;
}

abstract final class AppRadii {
  static const card = 20.0;
  static const sheet = 26.0;
  static const field = 12.0;
  static const chip = 14.0;
  static const pill = 999.0;
}

abstract final class AppShadows {
  static const card = [
    BoxShadow(
      color: Color(0x66281C0E), // rgba(40,28,14,.40)
      blurRadius: 30,
      offset: Offset(0, 14),
      spreadRadius: -16,
    ),
  ];
  static const soft = [
    BoxShadow(
      color: Color(0x2E211C16), // rgba(33,28,22,.18)
      blurRadius: 14,
      offset: Offset(0, 4),
      spreadRadius: -6,
    ),
  ];
}

/// iOS system font families. The leading-dot names resolve to San Francisco on
/// iOS (our primary target); other platforms fall back to the system default.
/// See `docs/design.md` §3 — UI must read as native Apple type, never a serif.
abstract final class AppFonts {
  static const display = '.SF Pro Display';
  static const text = '.SF Pro Text';
}
