import 'package:flutter/material.dart';

/// Colours taken from the CardioGuard Figma prototype.
class AppColors {
  static const primary = Color(0xFF1547E6); // buttons, links, logo
  static const background = Color(0xFFF0F5F9); // page background
  static const surface = Colors.white; // cards
  static const field = Color(0xFFF7F9FB); // text field fill
  static const fieldBorder = Color(0xFFE2E7EE);
  static const cardBorder = Color(0xFFE8ECF1);
  static const textPrimary = Color(0xFF0F172A); // titles
  static const textLabel = Color(0xFF1E293B); // field labels
  static const textMuted = Color(0xFF64748B); // subtitles
  static const textFaint = Color(0xFF94A3B8); // hints, disclaimers
  static const danger = Color(0xFFDC2626);

  // Status colours (dashboard, alerts)
  static const success = Color(0xFF16A34A); // "Normal", "Connected"
  static const successBg = Color(0xFFE8F7EE);
  static const warning = Color(0xFFF59E0B); // fall check
  static const emergency = Color(0xFFE00012); // SOS, emergency alert
  static const emergencyBg = Color(0xFFFDECEC);
  static const cream = Color(0xFFFDF9EA); // fall / no-response background
  static const infoBg = Color(0xFFEAF0FE); // light blue icon tile
}

/// One theme for the whole app, so every screen matches the prototype.
ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    primary: AppColors.primary,
    surface: AppColors.surface,
    error: AppColors.danger,
  );

  OutlineInputBorder border(Color color, [double width = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: AppColors.field,
      hintStyle: const TextStyle(color: AppColors.textFaint),
      helperStyle: const TextStyle(color: AppColors.textFaint, fontSize: 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: border(AppColors.fieldBorder),
      enabledBorder: border(AppColors.fieldBorder),
      focusedBorder: border(AppColors.primary, 1.5),
      errorBorder: border(AppColors.danger),
      focusedErrorBorder: border(AppColors.danger, 1.5),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
        disabledForegroundColor: Colors.white,
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: AppColors.infoBg,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w400,
          color: states.contains(WidgetState.selected) ? AppColors.primary : AppColors.textMuted,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected) ? AppColors.primary : AppColors.textMuted,
        ),
      ),
    ),
  );
}
