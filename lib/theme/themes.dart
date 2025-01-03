/****************************************************************************************************
 *
 * @file:    themes.dart
 * @author:  Nolan Olhausen
 * @date: 2024-11-15
 *
 * @brief:
 *      This file contains the light and dark themes for the application.
 * 
 ****************************************************************************************************/

import 'package:flutter/material.dart';

ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  chipTheme: const ChipThemeData(
    selectedColor: Color.fromARGB(255, 255, 153, 7),
  ),
  inputDecorationTheme: InputDecorationTheme(
    focusedBorder: OutlineInputBorder(
      borderSide: const BorderSide(
          color: Color.fromARGB(255, 255, 153, 7)),
      borderRadius: BorderRadius.circular(8.0),
    ),
    floatingLabelStyle:
        const TextStyle(color: Color.fromARGB(255, 255, 153, 7)),
  ),
  textSelectionTheme: const TextSelectionThemeData(
    cursorColor: Color.fromARGB(255, 255, 153, 7),
  ),
  radioTheme: const RadioThemeData(
    fillColor: WidgetStatePropertyAll(Color.fromARGB(255, 255, 153, 7)),
  ),
);

ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  switchTheme: SwitchThemeData(
    thumbColor:
        MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
      if (states.contains(MaterialState.selected)) {
        return const Color.fromARGB(255, 130, 77, 4).withOpacity(.48);
      }
      return const Color.fromARGB(255, 255, 153, 7);
    }),
  ),
  chipTheme: const ChipThemeData(
    selectedColor: Color.fromARGB(255, 255, 153, 7),
  ),
  inputDecorationTheme: InputDecorationTheme(
    focusedBorder: OutlineInputBorder(
      borderSide: const BorderSide(
          color: Color.fromARGB(255, 255, 153, 7)),
      borderRadius: BorderRadius.circular(8.0),
    ),
    floatingLabelStyle:
        const TextStyle(color: Color.fromARGB(255, 255, 153, 7)),
  ),
  textSelectionTheme: const TextSelectionThemeData(
    cursorColor: Color.fromARGB(255, 255, 153, 7),
  ),
  radioTheme: const RadioThemeData(
    fillColor: WidgetStatePropertyAll(Color.fromARGB(255, 255, 153, 7)),
  ),
);
