import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../domain/entities/map_node.dart';
import 'map_route_painter.dart';

/// Widget que muestra el mapa SVG con la ruta dibujada encima
/// 
/// Usa InteractiveViewer para permitir zoom y pan
class MapCanvas extends StatelessWidget {
  final int floor;
  final String svgAssetPath;
  final List<MapNode> pathNodes;

  const MapCanvas({
    super.key,
    required this.floor,
    required this.svgAssetPath,
    required this.pathNodes,
  });

  @override
  Widget build(BuildContext context) {
    // Tamaño del SVG basado en el viewBox (2808x1416 según el SVG)
    const svgSize = Size(2808, 1416);
    
    print('🗺️ MapCanvas: ${pathNodes.length} nodos en la ruta');
    print('🗺️ SVG path: $svgAssetPath');
    
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 4.0,
      panEnabled: true,
      scaleEnabled: true,
      child: SizedBox(
        width: svgSize.width,
        height: svgSize.height,
        child: Stack(
          children: [
            // SVG del mapa de fondo
            SvgPicture.asset(
              svgAssetPath,
              width: svgSize.width,
              height: svgSize.height,
              fit: BoxFit.fill,
              placeholderBuilder: (context) => const Center(
                child: CircularProgressIndicator(),
              ),
              // Agregar error builder para debugging
              semanticsLabel: 'Mapa del piso $floor',
            ),
            // CustomPaint para dibujar la ruta
            if (pathNodes.isNotEmpty)
              CustomPaint(
                painter: MapRoutePainter(
                  pathNodes: pathNodes,
                ),
                size: svgSize,
              ),
          ],
        ),
      ),
    );
  }
}

