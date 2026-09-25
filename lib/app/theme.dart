import 'package:flutter/material.dart';

/// Colours sampled from the JournyOG Figma frames.
class AppColors {
  AppColors._();

  static const navy = Color(0xFF002D60);
  static const panel = Color(0xFFE6F2FF);
  static const splash = Color(0xFFFFFCFA);
  static const blue = Color(0xFF0373F3);
  static const cardBorder = Color(0xFF94C4FB);
  static const inputBorder = Color(0xFF9AC6FA);
  static const text = Color(0xFF1B1B1B);
  static const textMuted = Color(0xFF6B6B6B);
  static const hint = Color(0xFFB0B0B0);
  static const placeholder = Color(0xFFD9D9D9);

  // Trip status badges
  static const statusOngoing = Color(0xFFBB0F23);
  static const statusPlanned = Color(0xFFF6B303);
  static const statusDone = Color(0xFF0FBB48);

  // Action buttons
  static const cancelBg = Color(0xFFFFE1E1);
  static const cancelBorder = Color(0xFFF19A9A);
  static const saveBg = Color(0xFFB0F4C1);
  static const saveBorder = Color(0xFF5FCB7C);
  static const addPlaceBg = Color(0xFFB0CEF4);
  static const addPlaceBorder = Color(0xFF6FA8F0);

  static const edit = Color(0xFF2DB84C);
  static const delete = Color(0xFFD5424F);

  // Plan side cards
  static const weatherBorder = Color(0xFFA8DBFF);
  static const weatherInner = Color(0xFFEFF7FF);
  static const budgetBorder = Color(0xFF6FD08C);
  static const rateBorder = Color(0xFFE28A93);
  static const progressTrack = Color(0xFFE3E3E3);

  static const dateBadge = Color(0xFFF7B502);

  /// Time badge colours on activity cards, cycled by order in the day.
  static const timeBadges = [
    Color(0xFFAF03F3),
    Color(0xFF7303F3),
    Color(0xFF3B03F3),
    Color(0xFF035FF3),
  ];
}

class AppTheme {
  AppTheme._();

  static const fontFamily = 'Poppins';
  static const fontFallback = ['Kanit'];

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      fontFamilyFallback: fontFallback,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.blue,
        primary: AppColors.blue,
      ),
      scaffoldBackgroundColor: AppColors.navy,
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.text,
        displayColor: AppColors.text,
        fontFamily: fontFamily,
      ),
      datePickerTheme: const DatePickerThemeData(
        headerBackgroundColor: AppColors.navy,
        headerForegroundColor: Colors.white,
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }
}
