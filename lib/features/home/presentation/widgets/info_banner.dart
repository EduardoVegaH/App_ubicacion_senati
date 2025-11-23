import 'package:flutter/material.dart';
import '../../../../../app/styles/app_styles.dart';
import '../../../../../app/styles/app_spacing.dart';
import '../../../../../app/styles/text_styles.dart';

/// Banner informativo con icono y texto
class InfoBanner extends StatelessWidget {
  /// Icono del banner
  final IconData icon;
  
  /// Texto del banner
  final String message;
  
  /// Color del icono
  final Color? iconColor;
  
  /// Color de fondo
  final Color? backgroundColor;
  
  /// Color del borde
  final Color? borderColor;
  
  /// Padding interno
  final EdgeInsets? padding;
  
  /// Estilo de texto personalizado (opcional)
  final TextStyle? textStyle;

  const InfoBanner({
    super.key,
    required this.icon,
    required this.message,
    this.iconColor,
    this.backgroundColor,
    this.borderColor,
    this.padding,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLargePhone = screenSize.width >= 400 && !isTablet;

    return Container(
      padding: padding ??
          AppSpacing.cardPaddingLarge(isLargePhone, isTablet),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppStyles.lightGrayBackground,
        borderRadius: BorderRadius.circular(12),
        border: borderColor != null
            ? Border.all(color: borderColor!, width: 1)
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: iconColor ?? AppStyles.primaryColor,
            size: isLargePhone ? 21 : (isTablet ? 22 : 20),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: textStyle ?? AppTextStyles.bodySmall(isLargePhone, isTablet),
            ),
          ),
        ],
      ),
    );
  }
}

