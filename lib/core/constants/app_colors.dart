import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFFC8F04A);
  static const Color primaryLight = Color(0xFFD8F56A);
  static const Color coral = Color(0xFFC8F04A);
  static const Color coralSoft = Color(0xFFF3F8D4);
  static const Color ink = Color(0xFF1C2118);

  static const Color accent = primary;
  static const Color success = Color(0xFF16C47F);
  static const Color warning = Color(0xFFF5C542);
  static const Color error = Color(0xFFE5484D);
  static const Color coin = Color(0xFFFFC107);
  static const Color onGold = Color(0xFF3B1408);
  static const Color onPrimary = Colors.white;

  static const Color background = Color(0xFFF6F5F0);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFF4F8FC);
  static const Color surfaceVariant = Color(0xFFE3EDF7);
  static const Color border = Color(0xFFD5E3F0);

  static const Color textPrimary = Color(0xFF1C2118);
  static const Color textSecondary = Color(0xFF5E655C);
  static const Color textMuted = Color(0xFF8B9388);

  static const Color darkBackground = Color(0xFF10182E);
  static const Color darkSurface = Color(0xFF1A2444);
  static const Color darkInk = Color(0xFFF4F7FF);
  static const Color darkTextSecondary = Color(0xFFC5D0EA);
  static const Color darkTextMuted = Color(0xFF8E9BB8);
  static const Color lightBackground = Color(0xFFF7F6F2);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF1C2118);
  static const Color onSurfaceVariant = Color(0xFF5C6B8A);

  static const List<Color> listPalette = [
    Color(0xFFFF2D8A),
    Color(0xFF16C47F),
    Color(0xFFF5C542),
    Color(0xFF7B5CFF),
    Color(0xFF1AA6C9),
    Color(0xFFFF7A45),
  ];

  static Color brand(BuildContext context) => Theme.of(context).colorScheme.primary;
  static Color primaryOf(BuildContext context) => Theme.of(context).colorScheme.primary;
  static Color onPrimaryOf(BuildContext context) => Theme.of(context).colorScheme.onPrimary;
  static Color primaryLightOf(BuildContext context) => Theme.of(context).colorScheme.secondary;
  static Color canvasOf(BuildContext context) => Theme.of(context).scaffoldBackgroundColor;
  static Color surfaceOf(BuildContext context) => Theme.of(context).colorScheme.surface;
  static Color borderOf(BuildContext context) => Theme.of(context).colorScheme.outline;
  static Color inkOf(BuildContext context) => Theme.of(context).colorScheme.onSurface;

  static Color secondaryInk(BuildContext context) => Theme.of(context).colorScheme.onSurfaceVariant;

  static Color mutedInk(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkTextMuted : textMuted;

  static Color primarySoftOf(BuildContext context) =>
      Color.lerp(primaryOf(context), surfaceOf(context), 0.78) ?? primaryLightOf(context);

  static Color listColor(int index) => listPalette[index % listPalette.length];

  static List<BoxShadow> softShadow({double opacity = 0.10}) => [
        BoxShadow(
          color: const Color(0xFF111111).withValues(alpha: opacity),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ];

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD8F56A), Color(0xFFC8F04A)],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD8F56A), Color(0xFFC8F04A)],
  );

  static const LinearGradient gameGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFC8F04A), Color(0xFFD8F56A)],
  );
}
