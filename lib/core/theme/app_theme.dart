import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  static ThemeData light() {
    const family = 'Vazirmatn';
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: family,
      scaffoldBackgroundColor: AppColors.voidBg,
      colorScheme: const ColorScheme.light(
        surface: AppColors.surface,
        primary: AppColors.primary,
        secondary: AppColors.teal,
        onSurface: AppColors.cream,
        onPrimary: AppColors.onPrimary,
        error: AppColors.danger,
      ),
    );

    const bodyStyle = TextStyle(fontFamily: family, color: AppColors.cream, height: 1.7);
    const titleStyle = TextStyle(fontFamily: family, color: AppColors.cream, fontWeight: FontWeight.w700);

    return base.copyWith(
      textTheme: base.textTheme.apply(
        fontFamily: family,
        bodyColor: AppColors.cream,
        displayColor: AppColors.cream,
      ).copyWith(
        bodySmall: bodyStyle.copyWith(fontSize: 12),
        bodyMedium: bodyStyle.copyWith(fontSize: 14),
        bodyLarge: bodyStyle.copyWith(fontSize: 16),
        labelSmall: bodyStyle.copyWith(fontSize: 11, color: AppColors.muted),
        labelMedium: bodyStyle.copyWith(fontSize: 13),
        labelLarge: bodyStyle.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
        titleSmall: titleStyle.copyWith(fontSize: 14),
        titleMedium: titleStyle.copyWith(fontSize: 16),
        titleLarge: titleStyle.copyWith(fontSize: 20),
        headlineSmall: titleStyle.copyWith(fontSize: 22),
        headlineMedium: titleStyle.copyWith(fontSize: 26),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        foregroundColor: AppColors.cream,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          fontFamily: family,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.cream,
        ),
      ),
      listTileTheme: const ListTileThemeData(
        titleTextStyle: TextStyle(
          fontFamily: family,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.cream,
        ),
        subtitleTextStyle: TextStyle(
          fontFamily: family,
          fontSize: 13,
          color: AppColors.muted,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        hintStyle: const TextStyle(color: AppColors.muted, fontFamily: family, fontSize: 15),
        labelStyle: const TextStyle(color: AppColors.muted, fontFamily: family, fontSize: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          disabledBackgroundColor: AppColors.line,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(
            fontFamily: family,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? AppColors.primary : AppColors.muted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.primarySoft
              : AppColors.line.withValues(alpha: 0.8),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primarySoft,
        height: 80,
        iconTheme: const WidgetStatePropertyAll(IconThemeData(size: 26)),
        labelTextStyle: const WidgetStatePropertyAll(
          TextStyle(fontFamily: family, fontSize: 13, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  /// سازگاری با کد قبلی
  static ThemeData dark() => light();
}
