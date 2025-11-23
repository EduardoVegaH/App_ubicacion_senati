import 'package:flutter/material.dart';
import '../../../app/styles/app_shadows.dart';

/// Botón flotante circular para eliminar
class DeleteButton extends StatelessWidget {
  /// Función a ejecutar al presionar
  final VoidCallback onTap;
  
  /// Tamaño del icono
  final double? iconSize;
  
  /// Color del icono
  final Color? iconColor;
  
  /// Tamaño del botón
  final double? buttonSize;
  
  /// Padding del icono
  final EdgeInsets? iconPadding;
  
  /// Color de fondo
  final Color? backgroundColor;
  
  /// Offset de la sombra
  final Offset? shadowOffset;
  
  /// Opacidad de la sombra
  final double? shadowOpacity;

  const DeleteButton({
    super.key,
    required this.onTap,
    this.iconSize,
    this.iconColor,
    this.buttonSize,
    this.iconPadding,
    this.backgroundColor,
    this.shadowOffset,
    this.shadowOpacity,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLargePhone = screenSize.width >= 400 && !isTablet;

    final finalIconSize = iconSize ??
        (isLargePhone ? 20 : (isTablet ? 22 : 18));
    final finalButtonSize = buttonSize ?? 40.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: finalButtonSize,
          height: finalButtonSize,
          padding: iconPadding ?? const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.white,
            shape: BoxShape.circle,
            boxShadow: shadowOpacity != null || shadowOffset != null
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(shadowOpacity ?? 0.1),
                      blurRadius: 4,
                      offset: shadowOffset ?? const Offset(0, 2),
                    ),
                  ]
                : AppShadows.cardShadow,
          ),
          child: Icon(
            Icons.delete_outline,
            color: iconColor ?? const Color(0xFF0D47A1),
            size: finalIconSize,
          ),
        ),
      ),
    );
  }
}

