import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../app/styles/app_styles.dart';
import '../../../../core/widgets/app_bar/index.dart';
import '../../../../core/services/sensor_service.dart';
import '../../domain/index.dart';
import '../../domain/repositories/navigation_repository.dart';
import '../../domain/use_cases/get_route_to_room.dart';
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
  final SensorService _sensorService = SensorService();
  TransformationController? _mapTransformationController;
  List<MapNode>? _pathNodes;
  MapNode? _entranceNode; // Nodo de inicio (entrada)
  bool _loading = true;
  String? _errorMessage;
  bool _showNodes = true; // Mostrar nodos azules por defecto para debugging
  Matrix4 _currentTransform = Matrix4.identity();

  @override
  void initState() {
    super.initState();
    _sensorService.start();
    _sensorService.onDataChanged = () => setState(() {});
    print('🚀 NavigationMapPage initState: piso ${widget.floor}, desde ${widget.fromNodeId} hasta ${widget.toNodeId}');
    try {
      _getRouteToRoomUseCase = sl<GetRouteToRoomUseCase>();
      print('✅ GetRouteToRoomUseCase obtenido del service locator');
      _loadRoute();
    } catch (e, stackTrace) {
      print('❌ Error obteniendo GetRouteToRoomUseCase: $e');
      print('Stack trace: $stackTrace');
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
    _sensorService.stop();
    super.dispose();
  }

  Future<void> _loadRoute() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      print('🔍 Calculando ruta: piso ${widget.floor}, desde ${widget.fromNodeId} hasta ${widget.toNodeId}');
      
      // Verificar que los nodos existan antes de calcular la ruta
      final repository = sl<NavigationRepository>();
      final nodes = await repository.getNodesForFloor(widget.floor);
      print('📊 Nodos disponibles en piso ${widget.floor}: ${nodes.length}');
      
      if (nodes.isEmpty) {
        throw Exception('No hay nodos inicializados para el piso ${widget.floor}. '
            'Por favor, inicializa los nodos desde la pantalla de administración.');
      }
      
      // Listar algunos IDs de nodos disponibles para debugging
      print('📋 Ejemplos de IDs de nodos disponibles en Firestore:');
      for (var i = 0; i < (nodes.length > 10 ? 10 : nodes.length); i++) {
        final node = nodes[i];
        print('   - ${node.id} (${node.x.toStringAsFixed(1)}, ${node.y.toStringAsFixed(1)})');
      }
      
      // Verificar si los nodos tienen el formato correcto (node#XX)
      final hasNewFormat = nodes.any((n) => n.id.contains('#'));
      if (!hasNewFormat && widget.floor == 2) {
        print('⚠️ ADVERTENCIA: Los nodos en Firestore NO tienen el formato nuevo (node#XX)');
        print('⚠️ Los nodos deberían tener formato como: node#37, node#34_sal#A200, etc.');
        print('⚠️ Por favor, re-inicializa los nodos desde la pantalla de administración.');
      }
      
      // Verificar que el nodo origen existe
      final fromNodeExists = nodes.any((n) => n.id == widget.fromNodeId);
      if (!fromNodeExists) {
        print('❌ Nodo origen no encontrado: ${widget.fromNodeId}');
        print('💡 Nodos disponibles que podrían servir como origen:');
        // Buscar nodos de escalera o entrada
        final entranceNodes = nodes.where((n) => 
          n.id.contains('escalera') || 
          n.id.contains('puerta') || 
          n.id.contains('entrada') ||
          n.type == 'escalera'
        ).take(5).toList();
        for (var node in entranceNodes) {
          print('   - ${node.id} (${node.type ?? "sin tipo"})');
        }
        throw Exception('Nodo origen "${widget.fromNodeId}" no encontrado en piso ${widget.floor}. '
            'Verifica que los nodos estén inicializados correctamente.');
      }
      
      // Verificar que el nodo destino existe
      final toNodeExists = nodes.any((n) => n.id == widget.toNodeId);
      if (!toNodeExists) {
        print('❌ Nodo destino no encontrado: ${widget.toNodeId}');
        throw Exception('Nodo destino "${widget.toNodeId}" no encontrado en piso ${widget.floor}. '
            'Verifica que el ID del salón sea correcto.');
      }
      
      final path = await _getRouteToRoomUseCase.call(
        floor: widget.floor,
        fromNodeId: widget.fromNodeId,
        toNodeId: widget.toNodeId,
      );

      print('✅ Ruta encontrada: ${path.length} nodos');
      for (var i = 0; i < path.length; i++) {
        final node = path[i];
        print('  ${i + 1}. ${node.id} (${node.x.toStringAsFixed(1)}, ${node.y.toStringAsFixed(1)})');
      }
      
      // Verificar que la ruta comienza en el nodo correcto
      if (path.isNotEmpty && path.first.id != widget.fromNodeId) {
        print('⚠️ ADVERTENCIA: La ruta no comienza en el nodo de inicio esperado');
        print('   Esperado: ${widget.fromNodeId}');
        print('   Encontrado: ${path.first.id}');
      }
      
      // Verificar que la ruta termina en el nodo correcto
      if (path.isNotEmpty && path.last.id != widget.toNodeId) {
        print('⚠️ ADVERTENCIA: La ruta no termina en el nodo de destino esperado');
        print('   Esperado: ${widget.toNodeId}');
        print('   Encontrado: ${path.last.id}');
      }

      if (mounted) {
        // El primer nodo de la ruta es el nodo de entrada
        setState(() {
          _pathNodes = path;
          _entranceNode = path.isNotEmpty ? path.first : null;
          _loading = false;
        });
        print('✅ Estado actualizado: ${path.length} nodos en la ruta');
      }
    } catch (e, stackTrace) {
      print('❌ Error calculando ruta: $e');
      print('Stack trace: $stackTrace');
      
      // Mejorar el mensaje de error para que sea más útil
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

  @override
  Widget build(BuildContext context) {
    print('🎨 NavigationMapPage build: loading=$_loading, error=${_errorMessage != null}, pathNodes=${_pathNodes?.length ?? 0}');
    
    // Calcular posición del marcador del usuario (igual que en la rama antigua)
    Offset? userMarkerPosition;
    double? userHeading;
    if (_entranceNode != null) {
      // Convertir posX y posY del sensor (en metros) a coordenadas del SVG
      const double pixelScale = 10.0;
      final double userSvgX = _entranceNode!.x + (_sensorService.posX * pixelScale);
      final double userSvgY = _entranceNode!.y + (_sensorService.posY * pixelScale);
      
      // Obtener el tamaño de la pantalla
      final screenSize = MediaQuery.of(context).size;
      final displayWidth = screenSize.width;
      final displayHeight = screenSize.height;
      
      // Tamaño del SVG basado en el viewBox
      final svgSize = widget.floor == 1 
          ? const Size(2808, 1416)
          : const Size(2117, 1729);
      
      // Convertir coordenadas del SVG a coordenadas de pantalla
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
      
      userMarkerPosition = Offset(markerScreenX, markerScreenY);
      userHeading = _sensorService.heading;
      
      // Debug: verificar que se está calculando
      print('📍 Marcador: posX=${_sensorService.posX.toStringAsFixed(2)}, posY=${_sensorService.posY.toStringAsFixed(2)}, screenX=${markerScreenX.toStringAsFixed(1)}, screenY=${markerScreenY.toStringAsFixed(1)}');
    }
    
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
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppStyles.errorColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error al calcular la ruta',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppStyles.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppStyles.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _loadRoute,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              : _pathNodes != null && _pathNodes!.isNotEmpty
                  ? Stack(
                      children: [
                        MapCanvas(
                          floor: widget.floor,
                          svgAssetPath: _getSvgAssetPath(widget.floor),
                          pathNodes: _pathNodes!,
                          entranceNode: _entranceNode,
                          showNodes: _showNodes,
                          onControllerReady: (controller) {
                            _mapTransformationController = controller;
                            controller.addListener(() {
                              if (mounted) {
                                setState(() {
                                  _currentTransform = controller.value;
                                });
                              }
                            });
                          },
                        ),
                        // Marcador del usuario (directamente en el Stack del padre)
                        if (userMarkerPosition != null && userHeading != null)
                          IgnorePointer(
                            key: ValueKey('user_marker_${_sensorService.posX.toStringAsFixed(2)}_${_sensorService.posY.toStringAsFixed(2)}'),
                            child: Transform(
                              transform: _mapTransformationController?.value ?? Matrix4.identity(),
                              child: Positioned(
                                left: userMarkerPosition!.dx - 15,
                                top: userMarkerPosition!.dy - 15,
                                child: Transform.rotate(
                                  angle: userHeading!,
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
                      ],
                    )
                  : const Center(
                      child: Text('No se encontró una ruta'),
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

