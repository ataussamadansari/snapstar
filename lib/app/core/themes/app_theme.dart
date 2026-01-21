
import 'package:flutter/material.dart';

import 'dark_theme_data.dart';
import 'light_theme_data.dart';

class AppTheme {
  static ThemeData get light => LightThemeData.theme;
  static ThemeData get dark => DarkThemeData.theme;
}