import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Centralized ThemeData builder for the SPDMS application.
///
/// Usage in main.dart:
///   MaterialApp(
///     theme: AppTheme.light(),
///     ...
///   )
abstract final class AppTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: false,

      // ── Brand color ───────────────────────────────────────────────────────
      // Admin/Activity red is the system-level primary; each feature portal
      // overrides its own AppBar backgroundColor individually.
      primaryColor: AppColors.adminPrimary,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.adminPrimary,
        primary: AppColors.adminPrimary,
        surface: AppColors.lightBg,
      ),

      // ── Scaffold ──────────────────────────────────────────────────────────
      scaffoldBackgroundColor: AppColors.lightBg,

      // ── AppBar ────────────────────────────────────────────────────────────
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkSlate,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
          color: Colors.white,
        ),
      ),

      // ── Card ─────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.only(bottom: 8),
      ),

      // ── ElevatedButton ────────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.adminPrimary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),

      // ── OutlinedButton ────────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        ),
      ),

      // ── InputDecoration ───────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),

      // ── Divider ───────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.borderLight,
        thickness: 1,
      ),
    );
  }
}
