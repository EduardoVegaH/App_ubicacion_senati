import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/services/sensor_service.dart';
import '../../domain/entities/map_node.dart';
import '../../data/utils/svg_node_hider.dart';
import 'map_route_painter.dart';

/// Widget que muestra el mapa SVG con la ruta dibujada encima
/// 
/// Usa InteractiveViewer para permitir zoom y pan
/// Oculta los nodos azules del SVG antes de renderizarlo
class MapCanvas extends StatefulWidget {
  final int floor;
  final String svgAssetPath;
  final List<MapNode> pathNodes;
  final MapNode? entranceNode;
  final bool showNodes; // Para mostrar/ocultar los nodos azules del SVG
  final SensorService? sensorService; // Servicio de sensores para el marcador del usuario

  const MapCanvas({
    super.key,
    required this.floor,
    required this.svgAssetPath,
    required this.pathNodes,
    this.entranceNode,
    this.showNodes = false, // Por defecto ocultos
    this.sensorService,
  });

  @override
  State<MapCanvas> createState() => _MapCanvasState();
}

class _MapCanvasState extends State<MapCanvas> {
  final TransformationController _transformationController =
      TransformationController();
  double _scale = 1.0;

  @override
  void initState() {
    super.initState();
    _transformationController.addListener(_onTransformChanged);
    // Escuchar cambios del sensor para actualizar el marcador
    if (widget.sensorService != null) {
      widget.sensorService!.onDataChanged = () {
        if (mounted) {
          setState(() {});
        }
      };
    }
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onTransformChanged);
    _transformationController.dispose();
    super.dispose();
  }

  void _onTransformChanged() {
    final value = _transformationController.value;
    final newScale = value.getMaxScaleOnAxis();
    if ((newScale - _scale).abs() > 0.01) {
      setState(() {
        _scale = newScale;
      });
    }
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    // Tamaño del SVG basado en el viewBox
    // Piso 1: 2808x1416, Piso 2: 2117x1729
    final svgSize = widget.floor == 1 
        ? const Size(2808, 1416)
        : const Size(2117, 1729);
    
    // Log para debugging (fuera del árbol de widgets)
    if (widget.pathNodes.isNotEmpty) {
      print('🎨 MapCanvas: Preparando overlay de ruta con ${widget.pathNodes.length} nodos');
      print('   SVG size: ${svgSize.width}x${svgSize.height}');
    } else {
      print('⚠️ MapCanvas: No hay nodos en la ruta para dibujar');
    }
    
    // Calcular posición del marcador del usuario si hay sensor y nodo de entrada
    Offset? userMarkerPosition;
    double? userHeading;
    if (widget.sensorService != null && widget.entranceNode != null) {
      // Convertir posX y posY del sensor (en metros) a coordenadas del SVG
      // Asumimos que 1 metro = aproximadamente 10 píxeles en el SVG
      const double pixelScale = 10.0;
      final double userSvgX = widget.entranceNode!.x + (widget.sensorService!.posX * pixelScale);
      final double userSvgY = widget.entranceNode!.y + (widget.sensorService!.posY * pixelScale);
      
      // Obtener el tamaño de la pantalla
      final screenSize = MediaQuery.of(context).size;
      final displayWidth = screenSize.width;
      final displayHeight = screenSize.height;
      
      // Convertir coordenadas del SVG a coordenadas de pantalla
      // El SVG se ajusta con BoxFit.contain, así que necesitamos calcular el factor de escala
      final svgAspectRatio = svgSize.width / svgSize.height;
      final screenAspectRatio = displayWidth / displayHeight;
      
      double scaleX, scaleY, offsetX, offsetY;
      if (svgAspectRatio > screenAspectRatio) {
        // SVG es más ancho, se ajusta al ancho
        scaleX = displayWidth / svgSize.width;
        scaleY = scaleX;
        offsetX = 0;
        offsetY = (displayHeight - svgSize.height * scaleY) / 2;
      } else {
        // SVG es más alto, se ajusta al alto
        scaleY = displayHeight / svgSize.height;
        scaleX = scaleY;
        offsetX = (displayWidth - svgSize.width * scaleX) / 2;
        offsetY = 0;
      }
      
      final double markerScreenX = offsetX + (userSvgX * scaleX);
      final double markerScreenY = offsetY + (userSvgY * scaleY);
      
      userMarkerPosition = Offset(markerScreenX, markerScreenY);
      userHeading = widget.sensorService!.heading;
    }
    
    return Stack(
      children: [
        // Mapa SVG con zoom y pan
        InteractiveViewer(
          transformationController: _transformationController,
          minScale: 0.5,
          maxScale: 8.0,
          panEnabled: true,
          scaleEnabled: true,
          boundaryMargin: const EdgeInsets.all(double.infinity),
          child: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: FutureBuilder<String>(
              future: rootBundle.loadString(widget.svgAssetPath),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error cargando SVG: ${snapshot.error}'),
                  );
                }
                if (snapshot.hasData) {
                  // Mostrar u ocultar los nodos azules según la configuración
                  final svgContent = widget.showNodes
                      ? snapshot.data! // Mostrar nodos originales
                      : SvgNodeHider.hideNodesInSvg(snapshot.data!); // Ocultar nodos
                  return SvgPicture.string(
                    svgContent,
                    fit: BoxFit.contain,
                  );
                }
                return const Center(
                  child: CircularProgressIndicator(),
                );
              },
            ),
          ),
        ),
        
        // Overlay con la ruta (sincronizado con el mismo controller)
        if (widget.pathNodes.isNotEmpty)
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _transformationController,
              builder: (context, child) {
                return Transform(
                  transform: _transformationController.value,
                  child: SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child: CustomPaint(
                      size: Size.infinite,
                      painter: MapRoutePainter(
                        pathNodes: widget.pathNodes,
                        entranceNode: widget.entranceNode,
                        routeColor: const Color(0xFF1B38E3),
                        routeWidth: 5.0, // Aumentado aún más para mejor visibilidad
                        destinationColor: const Color(0xFF87CEEB),
                        svgWidth: svgSize.width,
                        svgHeight: svgSize.height,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        
        // Marcador del usuario
        if (userMarkerPosition != null && userHeading != null)
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _transformationController,
              builder: (context, child) {
                // Recalcular posición dentro del builder para que use valores actuales del sensor
                Offset? currentMarkerPosition;
                double? currentHeading;
                if (widget.sensorService != null && widget.entranceNode != null) {
                  const double pixelScale = 10.0;
                  final double userSvgX = widget.entranceNode!.x + (widget.sensorService!.posX * pixelScale);
                  final double userSvgY = widget.entranceNode!.y + (widget.sensorService!.posY * pixelScale);
                  
                  final screenSize = MediaQuery.of(context).size;
                  final displayWidth = screenSize.width;
                  final displayHeight = screenSize.height;
                  
                  final svgAspectRatio = svgSize.width / svgSize.height;
                  final screenAspectRatio = displayWidth / displayHeight;
                  
                  double scaleX, scaleY, offsetX, offsetY;
                  if (svgAspectRatio > screenAspectRatio) {
                    scaleX = displayWidth / svgSize.width;
                    scaleY = scaleX;
                    offsetX = 0;
                    offsetY = (displayHeight - svgSize.height * scaleY) / 2;
                  } else {
                    scaleY = displayHeight / svgSize.height;
                    scaleX = scaleY;
                    offsetX = (displayWidth - svgSize.width * scaleX) / 2;
                    offsetY = 0;
                  }
                  
                  final double markerScreenX = offsetX + (userSvgX * scaleX);
                  final double markerScreenY = offsetY + (userSvgY * scaleY);
                  
                  currentMarkerPosition = Offset(markerScreenX, markerScreenY);
                  currentHeading = widget.sensorService!.heading;
                }
                
                if (currentMarkerPosition == null || currentHeading == null) {
                  return const SizedBox.shrink();
                }
                
                return Transform(
                  transform: _transformationController.value,
                  child: Positioned(
                    left: currentMarkerPosition!.dx - 15,
                    top: currentMarkerPosition!.dy - 15,
                    child: Transform.rotate(
                      angle: currentHeading!,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B38E3),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: CustomPaint(
                          painter: _UserMarkerPainter(),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        
        // Botón de reset zoom (solo visible cuando hay zoom)
        if (_scale > 1.1)
          Positioned(
            top: 16,
            right: 16,
            child: FloatingActionButton.small(
              onPressed: _resetZoom,
              backgroundColor: Colors.white,
              child: const Icon(Icons.center_focus_strong, color: Colors.black87),
            ),
          ),
      ],
    );
  }
}

/// Painter para el marcador del usuario (flecha direccional)
class _UserMarkerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Dibujar una flecha apuntando hacia arriba (norte = 0°)
    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    final arrowSize = size.width * 0.4;

    // Punto superior (punta de la flecha)
    path.moveTo(center.dx, center.dy - arrowSize);
    // Punto inferior izquierdo
    path.lineTo(center.dx - arrowSize * 0.6, center.dy + arrowSize * 0.3);
    // Punto inferior derecho
    path.lineTo(center.dx + arrowSize * 0.6, center.dy + arrowSize * 0.3);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
