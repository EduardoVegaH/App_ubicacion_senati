import 'package:flutter/material.dart';
import '../styles/app_styles.dart';

/// Tema de la aplicación (usa AppStyles para colores y estilos)
class AppTheme {
  /// Tema claro
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppStyles.primaryColor,
        primary: AppStyles.primaryColor,
        secondary: AppStyles.secondaryColor,
        surface: AppStyles.surfaceColor,
      ),
      scaffoldBackgroundColor: AppStyles.lightBackgroundColor,
      appBarTheme: AppStyles.appBarTheme,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: AppStyles.elevatedButtonStyle,
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: AppStyles.outlinedButtonStyle,
      ),
      textButtonTheme: TextButtonThemeData(
        style: AppStyles.textButtonStyle,
      ),
    );
  }
  
  /// Tema oscuro
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppStyles.primaryColor,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: AppStyles.backgroundColor,
    );
  }
}

