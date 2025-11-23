import 'package:flutter/material.dart';
import '../../../../app/styles/text_styles.dart';

/// Widget para mostrar estado vacío (sin datos)
class EmptyState extends StatelessWidget {
  /// Icono a mostrar
  final IconData icon;
  
  /// Mensaje principal
  final String message;
  
  /// Mensaje secundario (opcional)
  final String? secondaryMessage;
  
  /// Tamaño del icono
  final double? iconSize;
  
  /// Color del icono
  final Color? iconColor;
  
  /// Padding del contenedor
  final EdgeInsets? padding;

  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.secondaryMessage,
    this.iconSize = 64,
    this.iconColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLargePhone = screenSize.width >= 400 && !isTablet;

    return Padding(
      padding: padding ??
          EdgeInsets.all(isLargePhone ? 24 : (isTablet ? 28 : 20)), // Padding especial para empty state
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: iconSize,
              color: iconColor ?? Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: AppTextStyles.emptyMessageResponsive(isLargePhone, isTablet),
              textAlign: TextAlign.center,
            ),
            if (secondaryMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                secondaryMessage!,
                style: AppTextStyles.secondaryText(isLargePhone, isTablet),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

