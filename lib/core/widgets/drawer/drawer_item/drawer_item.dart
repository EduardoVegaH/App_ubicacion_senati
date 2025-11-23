import 'package:flutter/material.dart';
import '../../../../app/styles/app_styles.dart';
import '../../../../app/styles/text_styles.dart';

/// Item reutilizable para drawer/menú lateral
class DrawerItem extends StatelessWidget {
  /// Icono del item
  final IconData icon;
  
  /// Título del item
  final String title;
  
  /// Función a ejecutar al presionar
  final VoidCallback onTap;
  
  /// Si es el item de logout (cambia el color a blanco)
  final bool isLogout;
  
  /// Si es un teléfono grande
  final bool isLargePhone;
  
  /// Si es una tablet
  final bool isTablet;

  const DrawerItem({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.isLogout = false,
    required this.isLargePhone,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = isLogout ? Colors.white : AppStyles.textOnDark;
    final textColor = isLogout ? Colors.white : AppStyles.textOnDark;
    final chevronColor = isLogout 
        ? Colors.white 
        : AppStyles.textOnDark.withOpacity(0.7);
    
    final iconSize = isLargePhone ? 24.0 : (isTablet ? 26.0 : 22.0);
    final chevronSize = isLargePhone ? 20.0 : (isTablet ? 22.0 : 18.0);
    
    final padding = EdgeInsets.symmetric(
      horizontal: isLargePhone ? 16.0 : (isTablet ? 20.0 : 14.0),
      vertical: isLargePhone ? 18.0 : (isTablet ? 20.0 : 16.0),
    );

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: padding,
        child: Row(
          children: [
            Icon(
              icon,
              color: iconColor,
              size: iconSize,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.bodySmall(
                  isLargePhone,
                  isTablet,
                  textColor,
                ).copyWith(fontWeight: FontWeight.w500),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: chevronColor,
              size: chevronSize,
            ),
          ],
        ),
      ),
    );
  }
}

