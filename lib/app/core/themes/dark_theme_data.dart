import 'package:flutter/material.dart';
import 'app_colors.dart';

class DarkThemeData {
  static ThemeData get theme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.pureWhite,
      scaffoldBackgroundColor: AppColors.pureBlack,
      fontFamily: "Inter", // Clean, modern font for B&W theme

      // Color Scheme
      colorScheme: const ColorScheme.dark(
        primary: AppColors.pureWhite,
        secondary: AppColors.gray300,
        surface: AppColors.gray900,
        error: AppColors.gray300,
        onPrimary: AppColors.pureBlack,
        onSecondary: AppColors.pureBlack,
        onSurface: AppColors.pureWhite,
        onError: AppColors.pureBlack,
        surfaceContainerHighest: AppColors.gray800,
      ),

      // App Bar Theme
      appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.pureBlack,
          foregroundColor: AppColors.pureWhite,
          elevation: 0,
          iconTheme: IconThemeData(color: AppColors.pureWhite),
          titleTextStyle: TextStyle(
            color: AppColors.pureWhite,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          )
      ),

      // Text Themes
      textTheme: const TextTheme(
          displayLarge: TextStyle(
            color: AppColors.pureWhite,
            fontSize: 32,
            fontWeight: FontWeight.w900,
          ),
          displayMedium: TextStyle(
            color: AppColors.pureWhite,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
          displaySmall: TextStyle(
            color: AppColors.pureWhite,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
          headlineMedium: TextStyle(
            color: AppColors.pureWhite,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
          headlineSmall: TextStyle(
            color: AppColors.pureWhite,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
          titleLarge: TextStyle(
            color: AppColors.pureWhite,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: TextStyle(
            color: AppColors.gray300,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
          bodyMedium: TextStyle(
            color: AppColors.gray300,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          bodySmall: TextStyle(
            color: AppColors.gray500,
            fontSize: 12,
            fontWeight: FontWeight.w400,
          )
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.pureWhite,
            foregroundColor: AppColors.pureBlack,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600
            ),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)
            ),
            elevation: 0,
          )
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.gray700)
        ),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.gray700)
        ),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.pureWhite)
        ),
        filled: true,
        fillColor: AppColors.gray900,
        contentPadding: const EdgeInsets.all(16.0),
        hintStyle: const TextStyle(color: AppColors.gray500),
      ),

      // Card Theme
      cardTheme: CardThemeData(
          color: AppColors.gray900,
          elevation: 2,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)
          ),
          margin: EdgeInsets.zero
      ),
    );
  }
}