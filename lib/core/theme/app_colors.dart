import 'package:flutter/material.dart';

class AppColors {
  // Primary colors
  static const Color primary = Color(0xFF1F2A7C);
  static const Color secondary = Color(0xFF2F3A8F);

  // Background colors
  static const Color lightBackground = Color(0xFFF6F7FB);

  // Text colors (WCAG AA sobre fondo blanco)
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF4A4A4A);
  static const Color textTertiary = Color(0xFF6B6B6B);
  static const Color textDisabled = Color(0xFF9E9E9E);

  // Border / divider
  static const Color borderLight = Color(0xFFE0E0E0);

  // Status colors
  static const Color success = Colors.green;
  static const Color error = Colors.red;
  static const Color warning = Colors.orange;
  static const Color info = Colors.blue;

  // Private constructor to prevent instantiation
  AppColors._();
}
