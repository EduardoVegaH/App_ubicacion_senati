import 'package:flutter/material.dart';
import '../widgets/tower_map_viewer.dart';

/// Pantalla de navegación a pantalla completa
/// Muestra el mapa de las torres con navegación interactiva
class NavigationMapScreen extends StatelessWidget {
  final String? locationName;
  final String? locationDetail;
  final String? initialView; // 'exterior' o 'interior'

  const NavigationMapScreen({
    super.key,
    this.locationName,
    this.locationDetail,
    this.initialView,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;
    final isLargePhone = screenSize.width >= 400 && !isTablet;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Barra superior con información y botón de cerrar
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: isLargePhone ? 16 : (isTablet ? 20 : 14),
                vertical: isLargePhone ? 12 : (isTablet ? 14 : 10),
              ),
              decoration: const BoxDecoration(
                color: Color(0xFF1B38E3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Botón de cerrar
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 24,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  // Información de ubicación
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (locationDetail != null)
                          Text(
                            locationDetail!,
                            style: TextStyle(
                              fontSize: isLargePhone ? 16 : (isTablet ? 17 : 15),
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (locationName != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            locationName!,
                            style: TextStyle(
                              fontSize: isLargePhone ? 13 : (isTablet ? 14 : 12),
                              color: Colors.white.withOpacity(0.9),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Icono de navegación
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.navigation,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),

            // Mapa a pantalla completa
            Expanded(
              child: Container(
                color: Colors.white,
                child: TowerMapViewer(
                  height: null, // Usará todo el espacio disponible
                  showControls: true,
                  initialView: initialView,
                ),
              ),
            ),

            // Barra inferior con instrucciones
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: isLargePhone ? 16 : (isTablet ? 20 : 14),
                vertical: isLargePhone ? 12 : (isTablet ? 14 : 10),
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                border: Border(
                  top: BorderSide(
                    color: Colors.grey[300]!,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: isLargePhone ? 18 : (isTablet ? 20 : 16),
                    color: const Color(0xFF757575),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Usa gestos para navegar: pellizca para hacer zoom, arrastra para mover el mapa',
                      style: TextStyle(
                        fontSize: isLargePhone ? 12 : (isTablet ? 13 : 11),
                        color: const Color(0xFF757575),
                      ),
                    ),
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

