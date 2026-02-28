import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: 'Pretendard',

    colorScheme: const ColorScheme.dark(
      primary:      AppColors.primary,
      secondary:    AppColors.accent,
      surface:      AppColors.surfaceDark,
      onPrimary:    Colors.white,
      onSurface:    AppColors.textPrimaryDark,
    ),

    scaffoldBackgroundColor: AppColors.backgroundDark,

    appBarTheme: const AppBarTheme(
      backgroundColor:  AppColors.backgroundDark,
      foregroundColor:  AppColors.textPrimaryDark,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: 'Pretendard',
        fontSize:   18,
        fontWeight: FontWeight.w600,
        color:      AppColors.textPrimaryDark,
      ),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor:     AppColors.surfaceDark,
      selectedItemColor:   AppColors.primary,
      unselectedItemColor: AppColors.textSecondaryDark,
      type: BottomNavigationBarType.fixed,
      showUnselectedLabels: true,
    ),

    cardTheme: CardThemeData(
      color:        AppColors.surfaceDark,
      shape:        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation:    0,
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled:      true,
      fillColor:   AppColors.surface2Dark,
      border:      OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      hintStyle: const TextStyle(color: AppColors.textSecondaryDark),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: const TextStyle(
          fontFamily: 'Pretendard',
          fontSize:   16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    chipTheme: ChipThemeData(
      backgroundColor:        AppColors.surface2Dark,
      selectedColor:          AppColors.primary.withValues(alpha: 0.2),
      labelStyle: const TextStyle(
        fontFamily: 'Pretendard',
        fontSize: 13,
        color: AppColors.textSecondaryDark,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide.none,
    ),

    dividerTheme: const DividerThemeData(
      color:     AppColors.dividerDark,
      thickness: 1,
      space:     1,
    ),

    textTheme: const TextTheme(
      displayLarge:  TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.textPrimaryDark),
      displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimaryDark),
      headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimaryDark),
      headlineMedium:TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimaryDark),
      titleLarge:    TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimaryDark),
      titleMedium:   TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textPrimaryDark),
      titleSmall:    TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimaryDark),
      bodyLarge:     TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textPrimaryDark),
      bodyMedium:    TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textPrimaryDark),
      bodySmall:     TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textSecondaryDark),
      labelLarge:    TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimaryDark),
      labelMedium:   TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondaryDark),
      labelSmall:    TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.textSecondaryDark),
    ),
  );
}
