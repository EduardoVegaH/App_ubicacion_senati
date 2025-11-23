import 'package:flutter/material.dart';
import '../../../../app/styles/app_styles.dart';
import '../../../../app/styles/text_styles.dart';
import '../../../../app/styles/app_spacing.dart';

/// Header reutilizable para drawer/menú lateral
class CustomDrawerHeader extends StatelessWidget {
  /// Título del header
  final String title;
  
  /// Función a ejecutar al presionar el botón de cerrar
  final VoidCallback onClose;
  
  /// Si es un teléfono grande
  final bool isLargePhone;
  
  /// Si es una tablet
  final bool isTablet;

  const CustomDrawerHeader({
    super.key,
    required this.title,
    required this.onClose,
    required this.isLargePhone,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.screenPadding(isLargePhone, isTablet),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.titleLarge(
                isLargePhone,
                isTablet,
                AppStyles.textOnDark,
              ),
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: Icon(
              Icons.close,
              color: AppStyles.textOnDark,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}

