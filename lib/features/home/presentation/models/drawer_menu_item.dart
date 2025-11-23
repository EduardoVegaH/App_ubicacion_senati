import 'package:flutter/material.dart';

/// Modelo de datos para items del menú del drawer
class DrawerMenuItem {
  /// Icono del item
  final IconData icon;
  
  /// Título del item
  final String title;
  
  /// Función a ejecutar al presionar
  final VoidCallback onTap;
  
  /// Si muestra un separador después de este item
  final bool showSeparator;
  
  /// Si es el item de logout (cambia el color a blanco)
  final bool isLogout;

  const DrawerMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.showSeparator = true,
    this.isLogout = false,
  });
}

