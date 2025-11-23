import 'package:flutter/material.dart';
import '../../../app/styles/text_styles.dart';

/// Badge de estado con color e icono dinámico
class StatusBadge extends StatelessWidget {
  /// Texto del badge
  final String label;
  
  /// Color del badge
  final Color color;
  
  /// Icono del badge (opcional)
  final IconData? icon;
  
  /// Tamaño del icono
  final double? iconSize;
  
  /// Padding interno
  final EdgeInsets? padding;
  
  /// Opacidad del fondo
  final double backgroundOpacity;
  
  /// Ancho del borde
  final double borderWidth;
  
  /// Radio de borde
  final double borderRadius;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.iconSize,
    this.padding,
    this.backgroundOpacity = 0.15,
    this.borderWidth = 1.5,
    this.borderRadius = 10,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLargePhone = screenSize.width >= 400 && !isTablet;

    return Container(
      padding: padding ??
          EdgeInsets.symmetric(
            horizontal: isLargePhone ? 10 : (isTablet ? 12 : 8),
            vertical: isLargePhone ? 6 : (isTablet ? 7 : 5),
          ),
      decoration: BoxDecoration(
        color: color.withOpacity(backgroundOpacity),
        border: Border.all(
          color: color,
          width: borderWidth,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: iconSize ??
                  (isLargePhone ? 16 : (isTablet ? 17 : 15)),
              color: color,
            ),
            SizedBox(
              width: isLargePhone ? 6 : (isTablet ? 7 : 5),
            ),
          ],
          Text(
            label,
            style: AppTextStyles.textWithColor(
              isLargePhone,
              isTablet,
              color,
            ),
          ),
        ],
      ),
    );
  }
}

