import 'package:flutter/material.dart';

/// App-wide colour palette, ported from the iOS `UIColor+AppTheme` extension.
/// Windows are blue, floor spaces orange, and quote/total accents purple.
class AppColors {
  AppColors._();

  static const Color quoteTint = Color(0xFF6A4CB8); // purple
  static const Color windowTint = Color(0xFF2D7DF6); // blue
  static const Color floorTint = Color(0xFFF2740C); // orange
  static const Color teal = Color(0xFF14B8C4); // duplicate action
}

/// Builds the global [ThemeData] for the app.
ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.quoteTint,
    primary: AppColors.quoteTint,
  );
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.quoteTint,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
      isDense: true,
    ),
  );
}

