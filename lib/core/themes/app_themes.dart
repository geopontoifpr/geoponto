import 'package:flutter/material.dart';

class AppThemes {
  // Cores globais do projeto
  static const Color primaryColor = Colors.blueAccent;
  static const Color backgroundColorLight = Color(0xFFF5F5F5); // Cinza claro
  static const Color backgroundColorDark = Color(0xFF121212); // Quase preto
  static const Color inputColorLight = Colors.white;
  static const Color inputColorDark = Color(0xFF1E1E1E);

  static const Color errorColor = Colors.redAccent;
  static const Color warningColor = Colors.orange;
  static const Color infoColor = Colors.blue;

  // Tema Claro
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColorLight,
    cardColor: inputColorLight, // Usado para o fundo dos inputs
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
    ),
    useMaterial3: true,
  );

  // Tema Escuro
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColorDark,
    cardColor: inputColorDark,
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
    ),
    useMaterial3: true,
  );
}