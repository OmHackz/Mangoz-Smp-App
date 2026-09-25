import 'package:flutter/material.dart';
import 'package:oreui_flutter/oreui_flutter.dart';

/// Builds Material [ThemeData] that harmonizes with Ore UI colors so both
/// systems look coherent. Ore widgets remain the primary controls.
class AppTheme {
  AppTheme._();

  static ThemeData _base(Brightness brightness) {
    final ore = OreThemeData.fromBrightness(brightness);
    final c = ore.colors;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.accent,
      onPrimary: c.textInverse,
      secondary: c.info,
      onSecondary: c.textInverse,
      error: c.danger,
      onError: c.textInverse,
      surface: c.surface,
      onSurface: c.textPrimary,
      surfaceContainerHighest: c.surfaceDark,
      onSurfaceVariant: c.textMuted,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.background,
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        foregroundColor: c.textPrimary,
        elevation: 0,
      ),
      extensions: [ore],
      textTheme: TextTheme(
        titleLarge: ore.typography.title,
        bodyMedium: ore.typography.body,
        bodySmall: ore.typography.caption,
        labelLarge: ore.typography.label,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.surfaceDark,
        contentTextStyle: ore.typography.body,
      ),
    );
  }

  static ThemeData get light => _base(Brightness.light);
  static ThemeData get dark => _base(Brightness.dark);
}
