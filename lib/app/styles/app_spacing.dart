import 'package:flutter/material.dart';

/// Espaciados responsivos de la aplicación
/// Centraliza todos los paddings y margins responsivos para mantener consistencia
class AppSpacing {
  // ============================================
  // 📏 PADDINGS RESPONSIVOS
  // ============================================

  /// Padding estándar para pantallas (16/18/14)
  /// Usado en: Listas, páginas principales, containers grandes
  static EdgeInsets screenPadding(bool isLargePhone, bool isTablet) {
    return EdgeInsets.all(
      isLargePhone ? 16 : (isTablet ? 18 : 14),
    );
  }

  /// Padding para cards grandes (18/20/16)
  /// Usado en: CourseCard, cards principales
  static EdgeInsets cardPaddingLarge(bool isLargePhone, bool isTablet) {
    return EdgeInsets.all(
      isLargePhone ? 18 : (isTablet ? 20 : 16),
    );
  }

  /// Padding para cards medianos (16/20/14)
  /// Usado en: Cards estándar, headers
  static EdgeInsets cardPaddingMedium(bool isLargePhone, bool isTablet) {
    return EdgeInsets.all(
      isLargePhone ? 16 : (isTablet ? 20 : 14),
    );
  }

  /// Padding para cards pequeños (14/16/12)
  /// Usado en: BathroomTile, AttendanceHistoryCard, elementos compactos
  static EdgeInsets cardPaddingSmall(bool isLargePhone, bool isTablet) {
    return EdgeInsets.all(
      isLargePhone ? 14 : (isTablet ? 16 : 12),
    );
  }

  /// Padding para elementos muy pequeños (12/14/10)
  /// Usado en: Elementos compactos, badges, chips
  static EdgeInsets elementPaddingTiny(bool isLargePhone, bool isTablet) {
    return EdgeInsets.all(
      isLargePhone ? 12 : (isTablet ? 14 : 10),
    );
  }

  // ============================================
  // 📐 MARGINS RESPONSIVOS
  // ============================================

  /// Margin vertical estándar entre elementos (12/14/10)
  /// Usado en: Espaciado entre cards, elementos de lista
  static EdgeInsets verticalMarginStandard(bool isLargePhone, bool isTablet) {
    return EdgeInsets.only(
      bottom: isLargePhone ? 12 : (isTablet ? 14 : 10),
    );
  }

  /// Margin vertical pequeño entre elementos (8/10/6)
  /// Usado en: Espaciado entre elementos relacionados
  static EdgeInsets verticalMarginSmall(bool isLargePhone, bool isTablet) {
    return EdgeInsets.only(
      bottom: isLargePhone ? 8 : (isTablet ? 10 : 6),
    );
  }

  // ============================================
  // 📏 ESPACIADOS FIJOS (NO RESPONSIVOS)
  // ============================================

  /// Espaciado extra pequeño
  static const double spacingXS = 4.0;

  /// Espaciado pequeño
  static const double spacingS = 8.0;

  /// Espaciado medio
  static const double spacingM = 12.0;

  /// Espaciado grande
  static const double spacingL = 16.0;

  /// Espaciado extra grande
  static const double spacingXL = 24.0;
}

