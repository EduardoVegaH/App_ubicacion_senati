import 'package:flutter/material.dart';

/// Estilos globales de la aplicación (equivalente a globals.css)
/// Contiene todos los colores, estilos de texto, espaciados, etc.
class AppStyles {
  // ============================================
  // 🎨 COLORES PRINCIPALES
  // ============================================
  
  /// Color primario de la aplicación
  static const Color primaryColor = Color(0xFF1B38E3);
  
  /// Color secundario
  static const Color secondaryColor = Color(0xFF87CEEB);
  
  /// Color de fondo oscuro
  static const Color backgroundColor = Color(0xFF2C2C2C);
  
  /// Color de superficie (blanco)
  static const Color surfaceColor = Colors.white;
  
  /// Color de fondo claro
  static const Color lightBackgroundColor = Colors.white;
  
  // ============================================
  // 🎨 COLORES DE ESTADO
  // ============================================
  
  /// Color de éxito (azul celeste para presente/completado)
  static const Color successColor = Color(0xFF3D79FF);
  
  /// Color de advertencia (naranja)
  static const Color warningColor = Colors.orange;
  
  /// Color de error (rojo oscuro)
  static const Color errorColor = Color(0xFF622222);
  
  /// Color para tardanza (azul oscuro)
  static const Color lateColor = Color(0xFF4864A2);
  
  /// Color verde (presente/dentro)
  static const Color greenStatus = Colors.green;
  
  /// Color rojo (ausente/fuera)
  static const Color redStatus = Colors.red;
  
  /// Color naranja (próximo)
  static const Color orangeStatus = Colors.orange;
  
  /// Color azul (próximo)
  static const Color blueStatus = Colors.blue;
  
  // ============================================
  // 🎨 COLORES GRISES (Neutrales)
  // ============================================
  
  /// Gris claro (300) - Usado en: Bordes, separadores
  static const Color greyLight = Color(0xFFE0E0E0);
  
  /// Gris medio (400) - Usado en: Iconos secundarios, estados vacíos
  static const Color greyMedium = Color(0xFFBDBDBD);
  
  /// Gris oscuro (600) - Usado en: Textos secundarios, placeholders
  static const Color greyDark = Color(0xFF757575);
  
  /// Color gris (finalizado/deshabilitado)
  static const Color greyStatus = Colors.grey;
  
  // ============================================
  // 🎨 COLORES DE TEXTO
  // ============================================
  
  /// Color de texto principal (gris oscuro)
  static const Color textPrimary = Color(0xFF2C2C2C);
  
  /// Color de texto secundario (gris medio)
  static const Color textSecondary = Color(0xFF757575);
  
  /// Color de borde (gris claro)
  static const Color borderColor = Color(0xFFE0E0E0);
  
  /// Color de fondo gris claro
  static const Color lightGrayBackground = Color(0xFFF5F5F5);
  
  /// Color de texto en fondos oscuros
  static const Color textOnDark = Colors.white;
  
  /// Color de texto deshabilitado
  static const Color textDisabled = Color(0xFFBDBDBD);
  
  // ============================================
  // 🎨 COLORES CON OPACIDAD
  // ============================================
  
  /// Overlay blanco muy ligero (10% opacidad)
  /// Usado en: Fondos de input, elementos sutiles
  static Color get whiteOverlayVeryLight => Colors.white.withOpacity(0.1);
  
  /// Overlay blanco ligero (20% opacidad)
  /// Usado en: Avatares, elementos con fondo sutil
  static Color get whiteOverlayLight => Colors.white.withOpacity(0.2);
  
  /// Overlay blanco medio (25% opacidad)
  /// Usado en: Filtros no seleccionados, fondos sutiles
  static Color get whiteOverlayMedium => Colors.white.withOpacity(0.25);
  
  /// Overlay blanco medio-alto (30% opacidad)
  /// Usado en: Indicadores de carga, elementos semi-transparentes
  static Color get whiteOverlayMediumHigh => Colors.white.withOpacity(0.3);
  
  /// Overlay blanco fuerte (40% opacidad)
  /// Usado en: Filtros seleccionados, elementos activos
  static Color get whiteOverlayStrong => Colors.white.withOpacity(0.4);
  
  /// Overlay blanco muy fuerte (80% opacidad)
  /// Usado en: Campos de input, fondos casi opacos
  static Color get whiteOverlayVeryStrong => Colors.white.withOpacity(0.8);
  
  /// Overlay negro para backdrops (30% opacidad)
  /// Usado en: Modales, popups, overlays
  static Color get blackOverlayBackdrop => Colors.black.withOpacity(0.3);
  
  /// Overlay negro ligero (10% opacidad)
  /// Usado en: Sombras sutiles, elementos flotantes
  static Color get blackOverlayLight => Colors.black.withOpacity(0.1);
  
  /// Overlay negro medio (20% opacidad)
  /// Usado en: Sombras de popups, elementos elevados
  static Color get blackOverlayMedium => Colors.black.withOpacity(0.2);
  
  /// Overlay negro medio-alto (30% opacidad)
  /// Usado en: Bordes de input, elementos semi-transparentes
  static Color get blackOverlayMediumHigh => Colors.black.withOpacity(0.3);
  
  /// Overlay negro alto (50% opacidad)
  /// Usado en: Placeholders, textos secundarios
  static Color get blackOverlayHigh => Colors.black.withOpacity(0.5);
  
  /// Overlay negro muy ligero (5% opacidad)
  /// Usado en: Headers, elementos con sombra muy sutil
  static Color get blackOverlayVeryLight => Colors.black.withOpacity(0.05);
  
  /// Overlay de color primario fuerte (90% opacidad)
  /// Usado en: Headers de chat, elementos con fondo primario
  static Color get primaryColorOverlayStrong => primaryColor.withOpacity(0.9);
  
  /// Overlay de color primario medio (40% opacidad)
  /// Usado en: Sombras de botones flotantes, elementos con acento
  static Color get primaryColorOverlayMedium => primaryColor.withOpacity(0.4);
  
  // ============================================
  // 📏 ESPACIADOS (Padding/Margin)
  // ============================================
  
  /// Espaciado extra pequeño
  static const double spacingXS = 4.0;
  
  /// Espaciado pequeño
  static const double spacingS = 8.0;
  
  /// Espaciado medio
  static const double spacingM = 16.0;
  
  /// Espaciado grande
  static const double spacingL = 24.0;
  
  /// Espaciado extra grande
  static const double spacingXL = 32.0;
  
  /// Espaciado extra extra grande
  static const double spacingXXL = 40.0;
  
  // ============================================
  // 📐 BORDES Y RADIOS
  // ============================================
  
  /// Radio de borde pequeño
  static const double borderRadiusS = 8.0;
  
  /// Radio de borde medio
  static const double borderRadiusM = 12.0;
  
  /// Radio de borde grande
  static const double borderRadiusL = 20.0;
  
  /// Radio de borde circular
  static const double borderRadiusCircular = 999.0;
  
  // ============================================
  // 📝 ESTILOS DE TEXTO
  // ============================================
  
  /// Título grande (H1)
  static TextStyle get textH1 => const TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    height: 1.2,
  );
  
  /// Título medio (H2)
  static TextStyle get textH2 => const TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    height: 1.2,
  );
  
  /// Título pequeño (H3)
  static TextStyle get textH3 => const TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: textPrimary,
    height: 1.2,
  );
  
  /// Subtítulo
  static TextStyle get textSubtitle => const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.3,
  );
  
  /// Texto del cuerpo (body)
  static TextStyle get textBody => const TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: textPrimary,
    height: 1.5,
  );
  
  /// Texto pequeño
  static TextStyle get textSmall => const TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: textSecondary,
    height: 1.4,
  );
  
  /// Texto muy pequeño
  static TextStyle get textTiny => const TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.normal,
    color: textSecondary,
    height: 1.3,
  );
  
  /// Texto en botones
  static TextStyle get textButton => const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: textOnDark,
  );
  
  // ============================================
  // 🎯 ESTILOS DE WIDGETS COMUNES
  // ============================================
  
  /// Estilo de AppBar
  static AppBarTheme get appBarTheme => const AppBarTheme(
    backgroundColor: primaryColor,
    foregroundColor: textOnDark,
    elevation: 0,
    centerTitle: false,
  );
  
  /// Estilo de ElevatedButton
  static ButtonStyle get elevatedButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: textOnDark,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadiusM),
    ),
    padding: const EdgeInsets.symmetric(
      horizontal: spacingL,
      vertical: spacingM,
    ),
  );
  
  /// Estilo de OutlinedButton
  static ButtonStyle get outlinedButtonStyle => OutlinedButton.styleFrom(
    foregroundColor: primaryColor,
    side: const BorderSide(color: primaryColor, width: 2),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadiusM),
    ),
    padding: const EdgeInsets.symmetric(
      horizontal: spacingL,
      vertical: spacingM,
    ),
  );
  
  /// Estilo de TextButton
  static ButtonStyle get textButtonStyle => TextButton.styleFrom(
    foregroundColor: primaryColor,
    padding: const EdgeInsets.symmetric(
      horizontal: spacingM,
      vertical: spacingS,
    ),
  );
  
  /// Estilo de Card
  /// Nota: Para sombras específicas, usar AppShadows
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: surfaceColor,
    borderRadius: BorderRadius.circular(borderRadiusM),
    boxShadow: [
      BoxShadow(
        color: blackOverlayLight,
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ],
  );
  
  // ============================================
  // 📱 ESPACIADOS RESPONSIVE
  // ============================================
  
  /// Padding horizontal estándar
  static EdgeInsets get paddingHorizontal => const EdgeInsets.symmetric(
    horizontal: spacingM,
  );
  
  /// Padding vertical estándar
  static EdgeInsets get paddingVertical => const EdgeInsets.symmetric(
    vertical: spacingM,
  );
  
  /// Padding estándar
  static EdgeInsets get paddingStandard => const EdgeInsets.all(spacingM);
  
  /// Padding grande
  static EdgeInsets get paddingLarge => const EdgeInsets.all(spacingL);
  
  /// Margin horizontal estándar
  static EdgeInsets get marginHorizontal => const EdgeInsets.symmetric(
    horizontal: spacingM,
  );
  
  /// Margin vertical estándar
  static EdgeInsets get marginVertical => const EdgeInsets.symmetric(
    vertical: spacingM,
  );
}

