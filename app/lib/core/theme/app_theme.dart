import 'package:flutter/material.dart';
import 'tokens.dart';

/// Builds the Viele [ThemeData]. Light-only at v1 (see `docs/design.md` §9).
/// Type uses San Francisco via [AppFonts]; the scale mirrors `docs/design.md` §3.
ThemeData buildVieleTheme() {
  const scheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.ink,
    onPrimary: AppColors.onInk,
    secondary: AppColors.match,
    onSecondary: AppColors.onInk,
    surface: AppColors.canvas,
    onSurface: AppColors.ink,
    error: Color(0xFFB3261E),
    onError: Colors.white,
  );

  TextStyle disp(double size, FontWeight w, double tracking) => TextStyle(
        fontFamily: AppFonts.display,
        fontSize: size,
        fontWeight: w,
        letterSpacing: tracking,
        color: AppColors.ink,
        height: 1.05,
      );

  TextStyle txt(double size, FontWeight w, {double tracking = 0, Color? color}) =>
      TextStyle(
        fontFamily: AppFonts.text,
        fontSize: size,
        fontWeight: w,
        letterSpacing: tracking,
        color: color ?? AppColors.ink,
      );

  final textTheme = TextTheme(
    displayLarge: disp(32, FontWeight.w800, -0.8), // large title / wordmark
    titleLarge: disp(24, FontWeight.w700, -0.6), // section headline
    headlineSmall: disp(18, FontWeight.w800, -0.4), // profile name / sheet title
    bodyLarge: txt(15, FontWeight.w400), // body
    labelLarge: txt(14, FontWeight.w600), // callout / buttons
    bodyMedium: txt(13, FontWeight.w500, color: AppColors.ink2), // subhead
    bodySmall: txt(12, FontWeight.w500, color: AppColors.ink2), // footnote
    labelSmall: txt(11, FontWeight.w700, tracking: 1.8, color: AppColors.ink2), // caps label
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.canvas,
    textTheme: textTheme,
    fontFamily: AppFonts.text,
    splashFactory: InkRipple.splashFactory,
    dividerColor: AppColors.line,
    iconTheme: const IconThemeData(color: AppColors.ink),
  );
}
