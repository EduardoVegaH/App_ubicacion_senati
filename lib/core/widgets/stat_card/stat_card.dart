import 'package:flutter/material.dart';
import '../../../app/styles/text_styles.dart';

/// Tarjeta de estadística reutilizable (valor grande + etiqueta)
class StatCard extends StatelessWidget {
  /// Etiqueta de la estadística
  final String label;
  
  /// Valor de la estadística
  final String value;
  
  /// Color de fondo
  final Color backgroundColor;
  
  /// Color del texto
  final Color textColor;
  
  /// Callback cuando se presiona (opcional, si es null no es clicable)
  final VoidCallback? onTap;
  
  /// Si está seleccionado (cambia la opacidad del fondo)
  final bool isSelected;
  
  /// Padding horizontal
  final double? horizontalPadding;
  
  /// Padding vertical
  final double? verticalPadding;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.backgroundColor,
    required this.textColor,
    this.onTap,
    this.isSelected = false,
    this.horizontalPadding,
    this.verticalPadding,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLargePhone = screenSize.width >= 400 && !isTablet;

    final card = Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding ?? (isLargePhone ? 8 : (isTablet ? 10 : 6)),
        vertical: verticalPadding ?? (isLargePhone ? 10 : (isTablet ? 12 : 8)),
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: AppTextStyles.textWithColorLarge(isLargePhone, isTablet, textColor),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.courseHistoryStatLabel(isLargePhone, isTablet),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: card,
      );
    }

    return card;
  }
}

