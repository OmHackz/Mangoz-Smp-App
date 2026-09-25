import 'package:flutter/material.dart';
import 'package:oreui_flutter/oreui_flutter.dart';

/// Material 3 theme (mango-leaf seed) with the Ore theme attached as an
/// extension for the few remaining Ore-styled surfaces (chat, Minesweeper).
class AppTheme {
  AppTheme._();

  static const Color seed = Color(0xFF4C9A2A);

  static ThemeData _base(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      extensions: [OreThemeData.fromBrightness(brightness)],
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  static ThemeData get light => _base(Brightness.light);
  static ThemeData get dark => _base(Brightness.dark);
}
