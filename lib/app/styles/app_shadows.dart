import 'package:flutter/material.dart';

/// Sombras globales de la aplicación
/// Centraliza todas las definiciones de BoxShadow para mantener consistencia
class AppShadows {
  // ============================================
  // 🌑 SOMBRAS PRINCIPALES
  // ============================================

  /// Sombra sutil para headers y elementos elevados
  /// Usada en: CourseHistoryHeader, headers, banners
  static List<BoxShadow> get headerShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ];

  /// Sombra estándar para cards
  /// Usada en: CourseCard, StatCard, cards generales
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];

  /// Sombra para elementos flotantes (popups, modales)
  /// Usada en: Popups, modales, bottom sheets
  static List<BoxShadow> get popupShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 10,
          offset: const Offset(0, -2),
        ),
      ];

  /// Sombra para elementos de mensajería (chat bubbles)
  /// Usada en: Chat bubbles, mensajes
  static List<BoxShadow> get messageShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];

  /// Sombra para overlays (fondos semitransparentes)
  /// Usada en: Overlays, backdrops
  static Color get overlayBackdrop => Colors.black.withOpacity(0.3);

  /// Sombra para elementos de navegación
  /// Usada en: AppBars, navigation bars
  static List<BoxShadow> get navigationShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];

  /// Sombra para botones flotantes (FAB)
  /// Usada en: Botones flotantes, elementos destacados
  static List<BoxShadow> floatingButtonShadow(Color color) => [
        BoxShadow(
          color: color.withOpacity(0.4),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];
}

