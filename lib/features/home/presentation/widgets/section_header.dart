import 'package:flutter/material.dart';
import '../../../../../app/styles/app_styles.dart';
import '../../../../../app/styles/text_styles.dart';

/// Encabezado de sección con icono y título
class SectionHeader extends StatelessWidget {
  /// Icono de la sección
  final IconData icon;
  
  /// Título de la sección
  final String title;
  
  /// Color del icono
  final Color? iconColor;
  
  /// Tamaño del icono
  final double? iconSize;
  
  /// Espaciado entre icono y título
  final double spacing;
  
  /// Espaciado inferior
  final double? bottomSpacing;

  const SectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.iconColor,
    this.iconSize,
    this.spacing = 8,
    this.bottomSpacing,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLargePhone = screenSize.width >= 400 && !isTablet;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: iconColor ?? AppStyles.primaryColor,
              size: iconSize ??
                  (isLargePhone ? 26 : (isTablet ? 28 : 24)),
            ),
            SizedBox(width: spacing),
            Text(
              title,
              style: AppTextStyles.titleLarge(isLargePhone, isTablet),
            ),
          ],
        ),
        if (bottomSpacing != null)
          SizedBox(height: bottomSpacing!),
      ],
    );
  }
}

