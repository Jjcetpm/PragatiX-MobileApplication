import 'package:flutter/material.dart';

/// Central color palette for the SPDMS application.
///
/// Usage:
///   - Import this file and reference AppColors.name
///   - Feature files may keep their local static const Color _primary until
///     they are individually refactored.
abstract final class AppColors {
  // ── Neutrals ──────────────────────────────────────────────────────────────
  /// Dark slate — used for AppBar backgrounds, dark headings.
  static const Color darkSlate = Color(0xFF1E293B);

  /// Light page background (Slate-100).
  static const Color lightBg = Color(0xFFF1F5F9);

  /// Primary text color.
  static const Color textPrimary = Color(0xFF1E293B);

  /// Secondary / muted text color.
  static const Color textSecondary = Color(0xFF64748B);

  /// Subtle divider / border color.
  static const Color borderLight = Color(0xFFE2E8F0);

  // ── Role brand colors ──────────────────────────────────────────────────────
  /// Admin feature primary — Google-red.
  static const Color adminPrimary = Color(0xFFEA4335);

  /// Teacher feature primary — teal-green.
  static const Color teacherPrimary = Color(0xFF11998e);

  /// Student & Login feature primary — indigo.
  static const Color studentPrimary = Color(0xFF4F46E5);

  /// Captain feature primary — shares indigo with student.
  static const Color captainPrimary = Color(0xFF4F46E5);

  // ── Semantic ───────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF22C55E);
  static const Color danger = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);

  // ── Leaderboard podium ────────────────────────────────────────────────────
  static const Color rankGold = Color(0xFFFBBF24); // #1
  static const Color rankSilver = Color(0xFF94A3B8); // #2
  static const Color rankBronze = Color(0xFFF97316); // #3
}
