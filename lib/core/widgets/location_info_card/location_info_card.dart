import 'package:flutter/material.dart';
import '../../../app/styles/text_styles.dart';
import '../../../app/styles/app_spacing.dart';

/// Card que muestra información de ubicación (lat/lon)
class LocationInfoCard extends StatelessWidget {
  /// Nombre de la ubicación
  final String name;
  
  /// Latitud
  final double latitude;
  
  /// Longitud
  final double longitude;
  
  /// Número de decimales para mostrar coordenadas
  final int decimalPlaces;
  
  /// Color del icono
  final Color? iconColor;
  
  /// Padding interno
  final EdgeInsets? padding;
  
  /// Color de fondo
  final Color? backgroundColor;
  
  /// Color del borde
  final Color? borderColor;

  const LocationInfoCard({
    super.key,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.decimalPlaces = 6,
    this.iconColor,
    this.padding,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLargePhone = screenSize.width >= 400 && !isTablet;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: borderColor ?? const Color(0xFFE0E0E0),
        ),
        borderRadius: BorderRadius.circular(12),
        color: backgroundColor ?? const Color(0xFFF5F5F5),
      ),
      child: Padding(
        padding: padding ??
            AppSpacing.elementPaddingTiny(isLargePhone, isTablet),
        child: Row(
          children: [
            Icon(
              Icons.location_on,
              size: isLargePhone ? 20 : (isTablet ? 22 : 18),
              color: iconColor ?? const Color(0xFF2C2C2C),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppTextStyles.bodyBoldMedium(
                      isLargePhone,
                      isTablet,
                    ),
                  ),
                  Text(
                    'Lat: ${latitude.toStringAsFixed(decimalPlaces)}, Lon: ${longitude.toStringAsFixed(decimalPlaces)}',
                    style: AppTextStyles.bodyTiny(isLargePhone, isTablet),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

