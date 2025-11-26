import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../app/styles/app_styles.dart';
import '../../../../core/widgets/app_bar/index.dart';
import '../../../../core/widgets/destination_photo_viewer/index.dart';
import '../../../../core/services/sensor_service.dart';
import '../../domain/index.dart';
import '../../domain/repositories/navigation_repository.dart';
import '../../domain/use_cases/get_route_to_room.dart';
import '../../data/utils/destination_info_extractor.dart';
import '../widgets/map_canvas.dart';

/// Página de navegación que muestra el mapa con la ruta calculada
class NavigationMapPage extends StatefulWidget {
  final int floor;
  final String fromNodeId;
  final String toNodeId;

  const NavigationMapPage({
    super.key,
    required this.floor,
    required this.fromNodeId,
    required this.toNodeId,
  });

  @override
  State<NavigationMapPage> createState() => _NavigationMapPageState();
}

class _NavigationMapPageState extends State<NavigationMapPage> {
  late final GetRouteToRoomUseCase _getRouteToRoomUseCase;
  late final SensorService _sensorService;
  List<MapNode>? _pathNodes;
  MapNode? _entranceNode;
  bool _loading = true;
  String? _errorMessage;
  bool _showNodes = true;

  @override
  void initState() {
    super.initState();
    // Usar el sensor singleton global (ya está iniciado)
    _sensorService = sl<SensorService>();
    _sensorService.onDataChanged = () => setState(() {});
    try {
      _getRouteToRoomUseCase = sl<GetRouteToRoomUseCase>();
      _loadRoute();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error inicializando: $e';
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    // NO detener el sensor aquí - es global y debe seguir funcionando
    // _sensorService.stop();
    super.dispose();
  }

  Future<void> _loadRoute() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final repository = sl<NavigationRepository>();
      final nodes = await repository.getNodesForFloor(widget.floor);
      
      if (nodes.isEmpty) {
        throw Exception('No hay nodos inicializados para el piso ${widget.floor}. '
            'Por favor, inicializa los nodos desde la pantalla de administración.');
      }
      
      final fromNodeExists = nodes.any((n) => n.id == widget.fromNodeId);
      if (!fromNodeExists) {
        throw Exception('Nodo origen "${widget.fromNodeId}" no encontrado en piso ${widget.floor}. '
            'Verifica que los nodos estén inicializados correctamente.');
      }
      
      final toNodeExists = nodes.any((n) => n.id == widget.toNodeId);
      if (!toNodeExists) {
        throw Exception('Nodo destino "${widget.toNodeId}" no encontrado en piso ${widget.floor}. '
            'Verifica que el ID del salón sea correcto.');
      }
      
      final path = await _getRouteToRoomUseCase.call(
        floor: widget.floor,
        fromNodeId: widget.fromNodeId,
        toNodeId: widget.toNodeId,
      );

      if (mounted) {
        setState(() {
          _pathNodes = path;
          _entranceNode = path.isNotEmpty ? path.first : null;
          _loading = false;
        });
      }
    } catch (e) {
      String errorMessage = e.toString();
      if (e.toString().contains('no encontrado')) {
        errorMessage = '${e.toString()}\n\n'
            '💡 Verifica que:\n'
            '1. Los nodos estén inicializados en Firestore\n'
            '2. Los IDs de nodos sean correctos\n'
            '3. El piso sea el correcto (${widget.floor})';
      }
      
      if (mounted) {
        setState(() {
          _errorMessage = errorMessage;
          _loading = false;
        });
      }
    }
  }

  String _getSvgAssetPath(int floor) {
    switch (floor) {
      case 1:
        return 'assets/mapas/MAP_PISO_1.svg';
      case 2:
        return 'assets/mapas/MAP_PISO_2.svg';
      default:
        return 'assets/mapas/MAP_PISO_1.svg';
    }
  }

  /// Extrae el nombre del salón o área desde el ID del nodo destino
  String? _extractSalonName() {
    // Usar el extractor mejorado que maneja tanto salones como áreas
    return DestinationInfoExtractor.extractAreaOrSalonName(widget.toNodeId);
  }

  void _showDestinationPhoto() {
    if (_pathNodes == null || _pathNodes!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay ruta disponible para mostrar el destino'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Extraer información del destino desde el node ID
    final destinationInfo = DestinationInfoExtractor.extractDestinationInfo(widget.toNodeId);
    final tower = destinationInfo['tower'];
    final roomNumber = destinationInfo['roomNumber'];
    final imagePath = destinationInfo['imagePath'] ?? 'assets/fotos/foto-salon-b-200.png'; // Fallback
    
    // Construir nombre del destino
    final destinationName = DestinationInfoExtractor.buildDestinationName(
      tower,
      roomNumber,
      widget.floor,
    );

    // Construir nombre del salón (ej: "Salón 200")
    final salonName = roomNumber != null ? 'Salón $roomNumber' : null;

    // Número de segmentos de la ruta
    final routeSegments = _pathNodes!.length - 1; // Los segmentos son las conexiones entre nodos

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DestinationPhotoViewer(
        imagePath: imagePath,
        destinationName: destinationName,
        routeSegments: routeSegments,
        salonName: salonName,
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.surfaceColor,
      appBar: AppBarWithTitle(
        title: 'Navegación Piso ${widget.floor}',
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: AppStyles.textOnDark,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                // Dimensiones del SVG original (igual que en la rama antigua)
                const double svgWidth = 1412;
                const double svgHeight = 2806;
                const double pixelScale = 10.8; // Igual que en la rama antigua
                
                // Calcular el tamaño del SVG renderizado (con BoxFit.contain)
                final double widgetWidth = constraints.maxWidth;
                final double widgetHeight = constraints.maxHeight;
                final double svgAspectRatio = svgWidth / svgHeight;
                final double widgetAspectRatio = widgetWidth / widgetHeight;
                
                double displayWidth;
                double displayHeight;
                double offsetX = 0;
                double offsetY = 0;
                
                if (svgAspectRatio > widgetAspectRatio) {
                  // SVG es más ancho, se ajusta al ancho
                  displayWidth = widgetWidth;
                  displayHeight = widgetWidth / svgAspectRatio;
                  offsetY = (widgetHeight - displayHeight) / 2;
                } else {
                  // SVG es más alto, se ajusta a la altura
                  displayHeight = widgetHeight;
                  displayWidth = widgetHeight * svgAspectRatio;
                  offsetX = (widgetWidth - displayWidth) / 2;
                }
                
                // Calcular posición del marcador del usuario (igual que en la rama antigua)
                double? markerScreenX;
                double? markerScreenY;
                if (_entranceNode != null) {
                  // Convertir posX y posY del sensor (en metros) a coordenadas del SVG
                  final double userSvgX = _entranceNode!.x + (_sensorService.posX * pixelScale);
                  final double userSvgY = _entranceNode!.y + (_sensorService.posY * pixelScale);
                  
                  // Convertir coordenadas del SVG a coordenadas de pantalla
                  markerScreenX = offsetX + (userSvgX / svgWidth) * displayWidth;
                  markerScreenY = offsetY + (userSvgY / svgHeight) * displayHeight;
                }
                
                return Stack(
                  children: [
                    // Mapa siempre visible, incluso si hay error
                    MapCanvas(
                      floor: widget.floor,
                      svgAssetPath: _getSvgAssetPath(widget.floor),
                      pathNodes: _pathNodes ?? [],
                      entranceNode: _entranceNode,
                      showNodes: _showNodes,
                      sensorService: _sensorService,
                      destinationSalonName: _extractSalonName(),
                    ),
                    // Marcador del usuario (igual que código antiguo - líneas 712-741)
                    if (_entranceNode != null && markerScreenX != null && markerScreenY != null)
                      Positioned(
                        left: markerScreenX - 15, // Centrar el marcador (30/2 = 15)
                        top: markerScreenY - 15,
                        child: Transform.rotate(
                          angle: _sensorService.heading,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1B38E3), // Azul del tema
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
                    // Toggle para mostrar/ocultar nodos
                    Positioned(
                      top: 16,
                      left: 16,
                      child: FloatingActionButton.small(
                        onPressed: () {
                          setState(() {
                            _showNodes = !_showNodes;
                          });
                        },
                        backgroundColor: AppStyles.primaryColor,
                        child: Icon(
                          _showNodes ? Icons.visibility : Icons.visibility_off,
                          color: AppStyles.textOnDark,
                        ),
                      ),
                    ),
                    // Botón para mostrar foto del destino
                    if (_pathNodes != null && _pathNodes!.isNotEmpty)
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: FloatingActionButton(
                          onPressed: _showDestinationPhoto,
                          backgroundColor: AppStyles.primaryColor,
                          child: const Icon(
                            Icons.photo,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    // Mensaje de error superpuesto (si hay error)
                    if (_errorMessage != null)
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Material(
                          elevation: 8,
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.error_outline,
                                      color: AppStyles.errorColor,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 8),
                                    const Expanded(
                                      child: Text(
                                        'Error al calcular la ruta',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppStyles.textPrimary,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: () {
                                        setState(() {
                                          _errorMessage = null;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _errorMessage!,
                                  textAlign: TextAlign.left,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppStyles.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _loadRoute,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppStyles.primaryColor,
                                      foregroundColor: AppStyles.textOnDark,
                                    ),
                                    child: const Text('Reintentar'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
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

