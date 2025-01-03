/****************************************************************************************************
 *
 * @file:    theme_manager.dart
 * @author:  Nolan Olhausen
 * @date: 2024-11-15
 *
 * @brief:
 *      Manages the theme mode and system theme settings for the app.
 * 
 ****************************************************************************************************/

import 'package:flutter/material.dart';

class ThemeManager with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  bool _useSystemTheme = true;
  ThemeMode _prevTheme = ThemeMode.light;

  get themeMode => _useSystemTheme ? ThemeMode.system : _themeMode;
  get useSystemTheme => _useSystemTheme;

  toggleTheme(bool isDark) {
    if (!_useSystemTheme) {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
      _prevTheme = _themeMode;
    } else {
      _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  toggleSystemTheme(bool useSystem) {
    _useSystemTheme = useSystem;
    if (!useSystem) {
      _themeMode = _prevTheme;
    } else {
      _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  String getSVGIconPath(String iconName, BuildContext context) {
    // use system theme logic
    if (_useSystemTheme) {
      return MediaQuery.of(context).platformBrightness == Brightness.dark
          ? 'assets/icons/${iconName}_dark.svg'
          : 'assets/icons/${iconName}_light.svg';
    }
    return _themeMode == ThemeMode.dark
        ? 'assets/icons/${iconName}_dark.svg'
        : 'assets/icons/${iconName}_light.svg';
  }
}
