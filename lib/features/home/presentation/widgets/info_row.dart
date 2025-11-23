import 'package:flutter/material.dart';
import '../../../../../app/styles/text_styles.dart';

/// Fila de información con label y valor
class InfoRow extends StatelessWidget {
  /// Label de la información
  final String label;
  
  /// Valor de la información
  final String value;
  
  /// Proporción del label (flex)
  final int labelFlex;
  
  /// Proporción del valor (flex)
  final int valueFlex;
  
  /// Espaciado inferior
  final double? bottomSpacing;

  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.labelFlex = 2,
    this.valueFlex = 3,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: labelFlex,
              child: Text(
                label,
                style: AppTextStyles.bodySmall(isLargePhone, isTablet),
              ),
            ),
            Expanded(
              flex: valueFlex,
              child: Text(
                value,
                style: AppTextStyles.bodyMedium(isLargePhone, isTablet)
                    .copyWith(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        if (bottomSpacing != null)
          SizedBox(height: bottomSpacing!),
      ],
    );
  }
}

