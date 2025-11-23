import 'package:flutter/material.dart';
import '../../../../../app/styles/app_styles.dart';
import '../../../../../app/styles/text_styles.dart';
import '../../../../core/widgets/app_bar/index.dart';

/// Pantalla de navegación en tiempo real (placeholder para implementación futura)
class MapNavigatorPage extends StatelessWidget {
  /// ID del salón objetivo (ej: "salon-A-201" o "A-201")
  final String objetivoSalonId;
  
  /// Piso del mapa a mostrar
  final int piso;
  
  /// Nombre del salón (para mostrar en UI)
  final String? salonNombre;

  const MapNavigatorPage({
    super.key,
    required this.objetivoSalonId,
    required this.piso,
    this.salonNombre,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLargePhone = screenSize.width >= 400 && !isTablet;

    return Scaffold(
      backgroundColor: AppStyles.surfaceColor,
      appBar: AppBarWithTitle(
        title: salonNombre ?? 'Navegación al Salón',
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(isLargePhone ? 24 : (isTablet ? 32 : 20)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.navigation,
                size: isLargePhone ? 80 : (isTablet ? 96 : 64),
                color: AppStyles.primaryColor,
              ),
              SizedBox(height: isLargePhone ? 24 : (isTablet ? 32 : 20)),
              Text(
                'Navegación en Tiempo Real',
                style: AppTextStyles.titleLarge(
                  isLargePhone,
                  isTablet,
                  AppStyles.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isLargePhone ? 12 : (isTablet ? 16 : 10)),
              Text(
                'Próximamente',
                style: AppTextStyles.bodyMedium(
                  isLargePhone,
                  isTablet,
                  AppStyles.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isLargePhone ? 32 : (isTablet ? 40 : 24)),
              if (salonNombre != null || objetivoSalonId.isNotEmpty) ...[
                Container(
                  padding: EdgeInsets.all(isLargePhone ? 16 : (isTablet ? 20 : 14)),
                  decoration: BoxDecoration(
                    color: AppStyles.lightGrayBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.location_on,
                            color: AppStyles.primaryColor,
                            size: isLargePhone ? 20 : (isTablet ? 22 : 18),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              salonNombre ?? objetivoSalonId,
                              style: AppTextStyles.bodySmall(
                                isLargePhone,
                                isTablet,
                                AppStyles.textPrimary,
                              ).copyWith(fontWeight: FontWeight.w600),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                      if (piso > 0) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Piso $piso',
                          style: AppTextStyles.bodySmall(
                            isLargePhone,
                            isTablet,
                            AppStyles.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
