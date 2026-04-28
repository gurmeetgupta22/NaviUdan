import 'package:flutter/material.dart';

/// Indian tricolour-inspired palette on a clean white base (saffron · white · green + Ashoka navy).
class AppColors {
  // Tricolour accents (Indian flag reference)
  static const Color saffron = Color(0xFFFF8C42);
  static const Color indiaGreen = Color(0xFF138808);
  /// Pure white band in tricolour gradients / surfaces.
  static const Color tricolorWhite = Color(0xFFFFFFFF);
  /// Ashoka / chakra navy — use for centre stripe on white (e.g. logo “U”).
  static const Color navyAshoka = Color(0xFF000080);

  // Legacy name: on light UI this is off-white for subtle fills, not body text.
  static const Color indiaWhite = Color(0xFFF0F2F5);

  // Primary UI: saffron-led; secondary: green
  static const Color primary = saffron;
  static const Color primaryLight = Color(0xFFFFA64D);
  static const Color primaryDark = Color(0xFFE07020);

  static const Color secondaryGreen = indiaGreen;
  static const Color accent = Color(0xFFFF6B6B);
  static const Color accentGreen = indiaGreen;
  static const Color accentAmber = Color(0xFFFFB340);

  // Backgrounds — white app shell
  static const Color background = tricolorWhite;
  static const Color surface = Color(0xFFF4F6F9);
  static const Color surfaceCard = tricolorWhite;
  static const Color surfaceLight = Color(0xFFE2E6EE);

  static const Color textPrimary = Color(0xFF121826);
  static const Color textSecondary = Color(0xFF5A6478);
  static const Color textHint = Color(0xFF8892A4);

  static const Color success = indiaGreen;
  static const Color warning = accentAmber;
  static const Color error = Color(0xFFE53935);
  static const Color info = Color(0xFF0288D1);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFFF8C42), navyAshoka],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient tricolorGradient = LinearGradient(
    colors: [saffron, tricolorWhite, indiaGreen],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF7F9FC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient greenGradient = LinearGradient(
    colors: [Color(0xFF138808), Color(0xFF0D5C06)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient amberGradient = LinearGradient(
    colors: [Color(0xFFFFB340), Color(0xFFFF8C42)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
