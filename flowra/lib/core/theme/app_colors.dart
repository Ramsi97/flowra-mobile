import 'package:flutter/material.dart';

class AppColors {
  // Backgrounds
  static const Color background = Color(0xFF0F0F1A);
  static const Color surface = Color(0xFF1E1E2C);
  
  // Accents
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
  
  // Text
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFA1A1AA);
  static const Color textMuted = Color(0xFF71717A);
}
