import 'package:flutter/material.dart';

/// One set of app colours. There are two: [light] (from the Figma
/// prototype) and [dark].
class AppPalette {
  final Brightness brightness;
  final Color primary; // buttons, links, logo
  final Color background; // page background
  final Color surface; // cards, sheets, bottom bar
  final Color field; // text field fill
  final Color fieldBorder;
  final Color cardBorder;
  final Color textPrimary; // titles
  final Color textLabel; // field labels, body text
  final Color textMuted; // subtitles
  final Color textFaint; // hints, disclaimers
  final Color danger;
  final Color success; // "Normal", "Connected"
  final Color successBg;
  final Color warning; // fall check
  final Color warningBorder;
  final Color warningTrack; // fall countdown bar background
  final Color emergency; // SOS, emergency alert
  final Color emergencyBg;
  final Color emergencyText; // red headings on light/dark backgrounds
  final Color cream; // fall / no-response background
  final Color infoBg; // light blue icon tile, selected tab
  final Color track; // empty part of progress bars
  final Color segmentBg; // Daily/Weekly switch background
  final Color chartGrid;
  final Color chartGridFaint;

  const AppPalette({
    required this.brightness,
    required this.primary,
    required this.background,
    required this.surface,
    required this.field,
    required this.fieldBorder,
    required this.cardBorder,
    required this.textPrimary,
    required this.textLabel,
    required this.textMuted,
    required this.textFaint,
    required this.danger,
    required this.success,
    required this.successBg,
    required this.warning,
    required this.warningBorder,
    required this.warningTrack,
    required this.emergency,
    required this.emergencyBg,
    required this.emergencyText,
    required this.cream,
    required this.infoBg,
    required this.track,
    required this.segmentBg,
    required this.chartGrid,
    required this.chartGridFaint,
  });

  /// Colours from the CardioGuard Figma prototype.
  static const light = AppPalette(
    brightness: Brightness.light,
    primary: Color(0xFF1547E6),
    background: Color(0xFFF0F5F9),
    surface: Color(0xFFFFFFFF),
    field: Color(0xFFF7F9FB),
    fieldBorder: Color(0xFFE2E7EE),
    cardBorder: Color(0xFFE8ECF1),
    textPrimary: Color(0xFF0F172A),
    textLabel: Color(0xFF1E293B),
    textMuted: Color(0xFF64748B),
    textFaint: Color(0xFF94A3B8),
    danger: Color(0xFFDC2626),
    success: Color(0xFF16A34A),
    successBg: Color(0xFFE8F7EE),
    warning: Color(0xFFF59E0B),
    warningBorder: Color(0xFFF3E3B5),
    warningTrack: Color(0xFFFDE68A),
    emergency: Color(0xFFE00012),
    emergencyBg: Color(0xFFFDECEC),
    emergencyText: Color(0xFFB91C1C),
    cream: Color(0xFFFDF9EA),
    infoBg: Color(0xFFEAF0FE),
    track: Color(0xFFEFF2F6),
    segmentBg: Color(0xFFE6EBF1),
    chartGrid: Color(0xFFEDF0F4),
    chartGridFaint: Color(0xFFF3F5F8),
  );

  /// Dark mode: deep navy backgrounds, lighter text, slightly brighter
  /// accents so they stay readable. The emergency red stays the same.
  static const dark = AppPalette(
    brightness: Brightness.dark,
    primary: Color(0xFF5B83FF),
    background: Color(0xFF0B1220),
    surface: Color(0xFF151E2E),
    field: Color(0xFF1C2638),
    fieldBorder: Color(0xFF2A3548),
    cardBorder: Color(0xFF233046),
    textPrimary: Color(0xFFF1F5F9),
    textLabel: Color(0xFFE2E8F0),
    textMuted: Color(0xFF94A3B8),
    textFaint: Color(0xFF64748B),
    danger: Color(0xFFF87171),
    success: Color(0xFF22C55E),
    successBg: Color(0xFF0F2A1C),
    warning: Color(0xFFF59E0B),
    warningBorder: Color(0xFF4A3A12),
    warningTrack: Color(0xFF4A3A12),
    emergency: Color(0xFFE00012),
    emergencyBg: Color(0xFF3A1214),
    emergencyText: Color(0xFFF87171),
    cream: Color(0xFF1A160C),
    infoBg: Color(0xFF1B2A4A),
    track: Color(0xFF263043),
    segmentBg: Color(0xFF1C2638),
    chartGrid: Color(0xFF233046),
    chartGridFaint: Color(0xFF1C2638),
  );
}

/// The colours screens use, e.g. `AppColors.textPrimary`.
///
/// They follow the current theme (light or dark). Every screen and widget
/// calls [watch] at the top of build(): that reads the active theme and makes
/// the widget redraw when the user switches between light and dark.
class AppColors {
  AppColors._();

  static AppPalette _p = AppPalette.light;

  static bool get isDark => _p.brightness == Brightness.dark;

  /// Call first thing in every build() method.
  static void watch(BuildContext context) {
    _p = Theme.of(context).brightness == Brightness.dark ? AppPalette.dark : AppPalette.light;
  }

  static Color get primary => _p.primary;
  static Color get background => _p.background;
  static Color get surface => _p.surface;
  static Color get field => _p.field;
  static Color get fieldBorder => _p.fieldBorder;
  static Color get cardBorder => _p.cardBorder;
  static Color get textPrimary => _p.textPrimary;
  static Color get textLabel => _p.textLabel;
  static Color get textMuted => _p.textMuted;
  static Color get textFaint => _p.textFaint;
  static Color get danger => _p.danger;
  static Color get success => _p.success;
  static Color get successBg => _p.successBg;
  static Color get warning => _p.warning;
  static Color get warningBorder => _p.warningBorder;
  static Color get warningTrack => _p.warningTrack;
  static Color get emergency => _p.emergency;
  static Color get emergencyBg => _p.emergencyBg;
  static Color get emergencyText => _p.emergencyText;
  static Color get cream => _p.cream;
  static Color get infoBg => _p.infoBg;
  static Color get track => _p.track;
  static Color get segmentBg => _p.segmentBg;
  static Color get chartGrid => _p.chartGrid;
  static Color get chartGridFaint => _p.chartGridFaint;
}

/// Builds the app theme for one palette (light or dark).
ThemeData buildAppTheme(AppPalette p) {
  final scheme = ColorScheme.fromSeed(
    seedColor: p.primary,
    brightness: p.brightness,
    primary: p.primary,
    surface: p.surface,
    error: p.danger,
  );

  OutlineInputBorder border(Color color, [double width = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );

  return ThemeData(
    useMaterial3: true,
    brightness: p.brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: p.background,
    dividerColor: p.cardBorder,
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: p.field,
      hintStyle: TextStyle(color: p.textFaint),
      helperStyle: TextStyle(color: p.textFaint, fontSize: 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: border(p.fieldBorder),
      enabledBorder: border(p.fieldBorder),
      focusedBorder: border(p.primary, 1.5),
      errorBorder: border(p.danger),
      focusedErrorBorder: border(p.danger, 1.5),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: p.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: p.primary.withValues(alpha: 0.6),
        disabledForegroundColor: Colors.white,
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: p.primary,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),
    dialogTheme: DialogThemeData(backgroundColor: p.surface),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: p.surface),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: p.surface,
      indicatorColor: p.infoBg,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontSize: 12,
          fontWeight: states.contains(WidgetState.selected) ? FontWeight.w600 : FontWeight.w400,
          color: states.contains(WidgetState.selected) ? p.primary : p.textMuted,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected) ? p.primary : p.textMuted,
        ),
      ),
    ),
  );
}
