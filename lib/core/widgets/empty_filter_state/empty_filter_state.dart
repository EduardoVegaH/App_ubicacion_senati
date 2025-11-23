import 'package:flutter/material.dart';
import '../../../app/styles/text_styles.dart';

/// Estado vacío cuando un filtro no tiene resultados
class EmptyFilterState extends StatelessWidget {
  /// Mensaje principal
  final String message;
  
  /// Mensaje de ayuda/hint (opcional)
  final String? hint;
  
  /// Icono a mostrar (opcional)
  final IconData? icon;
  
  /// Color del icono
  final Color? iconColor;

  const EmptyFilterState({
    super.key,
    required this.message,
    this.hint,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLargePhone = screenSize.width >= 400 && !isTablet;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(isLargePhone ? 32 : (isTablet ? 40 : 24)), // Padding especial para empty state
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon ?? Icons.filter_alt_off,
              size: 64,
              color: iconColor ?? Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: AppTextStyles.emptyMessageResponsive(isLargePhone, isTablet),
              textAlign: TextAlign.center,
            ),
            if (hint != null) ...[
              const SizedBox(height: 8),
              Text(
                hint!,
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

