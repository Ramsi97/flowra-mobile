import 'package:flutter/material.dart';

/// Central colour tokens for Flowra.
///
/// Values are grouped into a layered neutral ramp (background → surface →
/// elevated surface → border) for each brightness so cards and sheets read with
/// real depth, plus a small brand palette. Always prefer the `getX(context)`
/// helpers in widgets so both themes stay correct; the bare `static` aliases at
/// the bottom exist only for a handful of brand-on-gradient cases.
class AppColors {
  // ─── Dark neutrals ──────────────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF0B0B12);
  static const Color darkSurface = Color(0xFF15151F);
  static const Color darkSurfaceElevated = Color(0xFF1E1E2B);
  static const Color darkBorder = Color(0x14FFFFFF); // white @ ~8%
  static const Color darkTextPrimary = Color(0xFFF5F6FA);
  static const Color darkTextSecondary = Color(0xFFA2A3B4);
  static const Color darkTextMuted = Color(0xFF6E6F82);

  // ─── Light neutrals ─────────────────────────────────────────────────────
  static const Color lightBackground = Color(0xFFF5F6FB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFEAECF2);
  static const Color lightTextPrimary = Color(0xFF12131A);
  static const Color lightTextSecondary = Color(0xFF5B5D6B);
  static const Color lightTextMuted = Color(0xFF9497A4);

  // ─── Brand ──────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF6366F1); // Indigo
  static const Color primaryDark = Color(0xFF4F46E5);
  static const Color secondary = Color(0xFF22D3EE); // Cyan
  static const Color accent = Color(0xFFA855F7); // Purple

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Richer, slower gradient for large hero surfaces (active focus session,
  /// profile header).
  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFF22D3EE)],
    stops: [0.0, 0.55, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── Status ─────────────────────────────────────────────────────────────
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // ─── Context-aware helpers ────────────────────────────────────────────────
  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color getBackground(BuildContext context) =>
      _isDark(context) ? darkBackground : lightBackground;

  static Color getSurface(BuildContext context) =>
      _isDark(context) ? darkSurface : lightSurface;

  static Color getSurfaceElevated(BuildContext context) =>
      _isDark(context) ? darkSurfaceElevated : lightSurfaceElevated;

  static Color getBorder(BuildContext context) =>
      _isDark(context) ? darkBorder : lightBorder;

  static Color getTextPrimary(BuildContext context) =>
      _isDark(context) ? darkTextPrimary : lightTextPrimary;

  static Color getTextSecondary(BuildContext context) =>
      _isDark(context) ? darkTextSecondary : lightTextSecondary;

  static Color getTextMuted(BuildContext context) =>
      _isDark(context) ? darkTextMuted : lightTextMuted;

  /// Priority → colour, shared by every task/schedule surface.
  static Color priorityColor(int priority) {
    switch (priority) {
      case 1:
        return error;
      case 2:
        return warning;
      default:
        return secondary;
    }
  }

  // ─── Legacy static aliases (dark-flavoured) ───────────────────────────────
  // Kept only for brand-on-dark contexts; new code should use the getters.
  static const Color background = darkBackground;
  static const Color surface = darkSurface;
  static const Color textPrimary = darkTextPrimary;
  static const Color textSecondary = darkTextSecondary;
  static const Color textMuted = darkTextMuted;
}
