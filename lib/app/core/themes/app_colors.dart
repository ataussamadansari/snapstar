import 'package:flutter/material.dart';

class AppColors {
  // Pure Black & White Colors
  static const Color pureBlack = Color(0xFF000000);
  static const Color pureWhite = Color(0xFFFFFFFF);

  // Gray Scale Colors
  static const Color gray900 = Color(0xFF111111);
  static const Color gray800 = Color(0xFF222222);
  static const Color gray700 = Color(0xFF333333);
  static const Color gray600 = Color(0xFF444444);
  static const Color gray500 = Color(0xFF666666);
  static const Color gray400 = Color(0xFF888888);
  static const Color gray300 = Color(0xFFAAAAAA);
  static const Color gray200 = Color(0xFFCCCCCC);
  static const Color gray100 = Color(0xFFEEEEEE);
  static const Color gray50 = Color(0xFFF8F8F8);

  // Primary Colors (Monochromatic)
  static const Color primary = pureBlack;
  static const Color primaryDark = pureBlack;
  static const Color primaryLight = gray700;
  static const Color secondary = gray600;
  static const Color secondaryDark = gray700;
  static const Color secondaryLight = gray400;

  // Neutral Colors
  static const Color white = pureWhite;
  static const Color black = pureBlack;
  static const Color grey = gray500;
  static const Color greyLight = gray200;
  static const Color greyDark = gray700;

  // Light Mode Colors
  static const Color backgroundLight = pureWhite;
  static const Color surfaceLight = pureWhite;
  static const Color textPrimaryLight = pureBlack;
  static const Color textSecondaryLight = gray600;
  static const Color textDisabledLight = gray400;
  static const Color borderLight = gray200;
  static const Color errorLight = gray700;

  // Dark Mode Colors
  static const Color backgroundDark = pureBlack;
  static const Color surfaceDark = gray900;
  static const Color textPrimaryDark = pureWhite;
  static const Color textSecondaryDark = gray300;
  static const Color textDisabledDark = gray500;
  static const Color borderDark = gray700;
  static const Color errorDark = gray300;

  // Semantic Colors (Monochromatic)
  static const Color success = gray600;
  static const Color warning = gray500;
  static const Color error = gray700;
  static const Color info = gray600;

  // Background Colors
  static const Color background = pureWhite;
  static const Color surface = pureWhite;
  static const Color onBackground = pureBlack;

  // Text Colors
  static const Color textPrimary = pureBlack;
  static const Color textSecondary = gray600;
  static const Color textDisabled = gray400;

  // Border Colors
  static const Color border = gray200;
  static const Color borderFocus = pureBlack;

  // Shadow Colors
  static const Color shadow = Color(0x1A000000);

  // Gradient Colors (Monochromatic)
  static const Gradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [pureBlack, gray700],
  );

  static const Gradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gray700, gray400],
  );

  static const lightCard100 = Color(0x40F0F0F0);
  static const darkCard100 = Color(0x40202020);
}