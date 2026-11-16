import 'package:flutter/material.dart';

/// Hệ thống Design Tokens chuẩn hóa cho SmartStay (Indigo / Slate).
class SmartStayColors {
  SmartStayColors._();

  static const Color primary = Color(0xFF4F46E5);
  static const Color primaryDark = Color(0xFF3730A3);
  static const Color primaryLight = Color(0xFFEEF2FF);
  static const Color accent = Color(0xFF0EA5E9);

  static const Color success = Color(0xFF10B981);
  static const Color successSoft = Color(0xFFECFDF5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningSoft = Color(0xFFFFFBEB);
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerSoft = Color(0xFFFEF2F2);
  static const Color info = Color(0xFF2563EB);
  static const Color infoSoft = Color(0xFFEFF6FF);

  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);

  static const Color bgDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color borderDark = Color(0xFF334155);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
}

class SmartStaySpacing {
  SmartStaySpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;

  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;
}

class SmartStayTheme {
  SmartStayTheme._();

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: SmartStayColors.primary,
      primary: SmartStayColors.primary,
      secondary: SmartStayColors.accent,
      surface: SmartStayColors.surfaceLight,
      error: SmartStayColors.danger,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: SmartStayColors.bgLight,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        surfaceTintColor: Colors.transparent,
        backgroundColor: SmartStayColors.surfaceLight,
        foregroundColor: SmartStayColors.textPrimaryLight,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: SmartStayColors.surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SmartStaySpacing.radiusLg),
          side: const BorderSide(color: SmartStayColors.borderLight),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SmartStaySpacing.radiusMd),
        ),
      ),
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: SmartStayColors.primary,
      primary: const Color(0xFF6366F1),
      secondary: SmartStayColors.accent,
      surface: SmartStayColors.surfaceDark,
      error: SmartStayColors.danger,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: SmartStayColors.bgDark,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        surfaceTintColor: Colors.transparent,
        backgroundColor: SmartStayColors.surfaceDark,
        foregroundColor: SmartStayColors.textPrimaryDark,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: SmartStayColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SmartStaySpacing.radiusLg),
          side: const BorderSide(color: SmartStayColors.borderDark),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SmartStaySpacing.radiusMd),
        ),
      ),
    );
  }
}

/// Bộ quản lý chế độ Sáng/Tối toàn ứng dụng.
class ThemeController extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.light;
  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark;

  void toggle() {
    _mode = isDark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  void setMode(ThemeMode mode) {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
  }
}
