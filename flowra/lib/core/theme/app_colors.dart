import 'package:flutter/material.dart';

class AppColors {
  // --- Dark Theme ---
  static const Color darkBackground = Color(0xFF0F0F1A);
  static const Color darkSurface = Color(0xFF1E1E2C);
  static const Color darkTextPrimary = Colors.white;
  static const Color darkTextSecondary = Color(0xFFA1A1AA);
  static const Color darkTextMuted = Color(0xFF71717A);

  // --- Light Theme ---
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Colors.white;
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color lightTextMuted = Color(0xFF94A3B8);

  // --- Shared Accents ---
  static const Color primary = Color(0xFF6366F1); // Indigo
  static const Color secondary = Color(0xFF06B6D4); // Cyan
  static const Color accent = Color(0xFFA855F7); // Purple
  
  // Gradients
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
  
  // Status
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);

  // Helper methods to get colors based on context
  static Color getBackground(BuildContext context) => 
      Theme.of(context).brightness == Brightness.dark ? darkBackground : lightBackground;
      
  static Color getSurface(BuildContext context) => 
      Theme.of(context).brightness == Brightness.dark ? darkSurface : lightSurface;

  static Color getTextPrimary(BuildContext context) => 
      Theme.of(context).brightness == Brightness.dark ? darkTextPrimary : lightTextPrimary;

  static Color getTextSecondary(BuildContext context) => 
      Theme.of(context).brightness == Brightness.dark ? darkTextSecondary : lightTextSecondary;

  // For backward compatibility while refactoring, or for specific static needs
  static const Color background = darkBackground;
  static const Color surface = darkSurface;
  static const Color textPrimary = darkTextPrimary;
  static const Color textSecondary = darkTextSecondary;
  static const Color textMuted = darkTextMuted;
}

