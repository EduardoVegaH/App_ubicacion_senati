import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../domain/entities/map_node.dart';
import '../../data/utils/svg_node_hider.dart';
import 'map_route_painter.dart';
import '../../../../core/services/sensor_service.dart';

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
  final SensorService? sensorService; // Sensor service para el marcador
  final ValueChanged<TransformationController>? onControllerReady; // Callback para exponer el controller

  const MapCanvas({
    super.key,
    required this.floor,
    required this.svgAssetPath,
    required this.pathNodes,
    this.entranceNode,
    this.showNodes = false, // Por defecto ocultos
    this.sensorService,
    this.onControllerReady,
  });

  @override
  State<MapCanvas> createState() => _MapCanvasState();
}

class _MapCanvasState extends State<MapCanvas> {
  final TransformationController _transformationController =
      TransformationController();
  double _scale = 1.0;
  Matrix4 _currentTransform = Matrix4.identity();
  
  // Última posición conocida del marcador (para detectar llegada a nodos)
  double? _lastMarkerX;
  double? _lastMarkerY;
  
  // Índice del nodo actual en la ruta (para seguir orden secuencial)
  int _currentNodeIndex = 0;
  
  // Índice del último segmento completado (para "comerse" la ruta ya recorrida)
  int _completedSegmentsIndex = -1;
  
  // Índice del nodo más cercano (para dibujar segmento dinámico)
  int? _nearestNodeIndex;
  
  // Últimos valores de posX/posY del sensor para detectar movimiento
  double? _lastSensorPosX;
  double? _lastSensorPosY;
  
  // Valores iniciales de posX/posY cuando se abre el mapa (para calcular movimiento relativo)
  double? _initialSensorPosX;
  double? _initialSensorPosY;

  @override
  void initState() {
    super.initState();
    
    // Resetear completamente el estado al inicializar
    _currentNodeIndex = 0;
    _completedSegmentsIndex = -1;
    _lastMarkerX = null;
    _lastMarkerY = null;
    _nearestNodeIndex = null;
    _lastSensorPosX = null;
    _lastSensorPosY = null;
    
    _transformationController.addListener(() {
      _onTransformChanged();
      if (mounted) {
        setState(() {
          _currentTransform = _transformationController.value;
        });
      }
    });
    // Exponer el controller al padre
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onControllerReady?.call(_transformationController);
    });
    
    // Configurar callback del sensor para actualizar cuando cambie el heading o posición
    if (widget.sensorService != null) {
      // RESETEAR posX y posY del sensor al abrir el mapa
      // Esto asegura que el marcador siempre comience desde cero
      widget.sensorService!.posX = 0;
      widget.sensorService!.posY = 0;
      
      // Guardar valores iniciales (serán 0 después del reset)
      _initialSensorPosX = 0;
      _initialSensorPosY = 0;
      _lastSensorPosX = null;
      _lastSensorPosY = null;
      
      widget.sensorService!.onDataChanged = () {
        if (mounted) {
          setState(() {
            // Recalcular posición del marcador cuando cambian los datos del sensor
            _calculateMarkerPosition();
          });
        }
      };
    }
  }

  @override
  void didUpdateWidget(MapCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Resetear solo si cambió la ruta o el nodo de entrada
    if (oldWidget.pathNodes != widget.pathNodes || oldWidget.entranceNode != widget.entranceNode) {
      _currentNodeIndex = 0;
      _completedSegmentsIndex = -1;
      _lastMarkerX = null;
      _lastMarkerY = null;
      _nearestNodeIndex = null;
      _lastSensorPosX = null;
      _lastSensorPosY = null;
    }
    
    // Reconfigurar el callback del sensor si cambió el sensor service
    // Esto asegura que funcione cuando se cambia de mapa
    if (oldWidget.sensorService != widget.sensorService) {
      // Limpiar el callback anterior si es diferente
      if (oldWidget.sensorService != null) {
        oldWidget.sensorService!.onDataChanged = null;
      }
      // Configurar el nuevo callback
      if (widget.sensorService != null) {
        // RESETEAR posX y posY cuando cambia el mapa
        widget.sensorService!.posX = 0;
        widget.sensorService!.posY = 0;
        _initialSensorPosX = 0;
        _initialSensorPosY = 0;
        _lastSensorPosX = null;
        _lastSensorPosY = null;
        widget.sensorService!.onDataChanged = () {
          if (mounted) {
            setState(() {
              // Recalcular posición del marcador cuando cambian los datos del sensor
              _calculateMarkerPosition();
            });
          }
        };
      }
    } else if (widget.sensorService != null) {
      // Si cambió la ruta o el nodo de entrada, resetear también
      if (oldWidget.pathNodes != widget.pathNodes || oldWidget.entranceNode != widget.entranceNode) {
        widget.sensorService!.posX = 0;
        widget.sensorService!.posY = 0;
        _initialSensorPosX = 0;
        _initialSensorPosY = 0;
        _lastSensorPosX = null;
        _lastSensorPosY = null;
      }
      // Asegurar que el callback esté configurado incluso si el sensor no cambió
      widget.sensorService!.onDataChanged = () {
        if (mounted) {
          setState(() {
            // Recalcular posición del marcador cuando cambian los datos del sensor
            _calculateMarkerPosition();
          });
        }
      };
    }
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onTransformChanged);
    _transformationController.dispose();
    // RESETEAR posX y posY del sensor al cerrar el mapa
    if (widget.sensorService != null) {
      widget.sensorService!.posX = 0;
      widget.sensorService!.posY = 0;
      widget.sensorService!.onDataChanged = null;
    }
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

  /// Calcula la posición final del marcador proyectando sobre la ruta
  /// El marcador sigue un orden secuencial de nodos, sin saltarse ninguno
  Offset? _calculateMarkerPosition() {
    if (widget.entranceNode == null || widget.sensorService == null || widget.pathNodes.isEmpty) {
      return null;
    }

    // Asegurar que el índice actual esté en rango válido
    if (_currentNodeIndex < 0) _currentNodeIndex = 0;
    if (_currentNodeIndex >= widget.pathNodes.length) {
      _currentNodeIndex = widget.pathNodes.length - 1;
    }

    const double pixelScale = 10.8; // Factor de conversión metros a píxeles SVG
    const double maxDistanceFromRoute = 200.0; // Máxima distancia permitida desde la ruta (píxeles)
    const double minMovementThreshold = 2.0; // Mínimo movimiento en píxeles para considerar actualización

    // Calcular posición del sensor basada en posX y posY
    final sensorX = widget.entranceNode!.x + (widget.sensorService!.posX * pixelScale);
    final sensorY = widget.entranceNode!.y + (widget.sensorService!.posY * pixelScale);
    final sensorPoint = Offset(sensorX, sensorY);

    // Actualizar última posición del sensor SIEMPRE
    // NO verificar movimiento, el marcador debe moverse siempre
    _lastSensorPosX = sensorX;
    _lastSensorPosY = sensorY;

    // Si estamos en el último nodo, permitir movimiento pero mantener en el nodo final
    // RESETEAR posX y posY cuando se llega al destino final
    if (_currentNodeIndex >= widget.pathNodes.length - 1) {
      final lastNode = widget.pathNodes[widget.pathNodes.length - 1];
      _nearestNodeIndex = widget.pathNodes.length - 1;
      
      // RESETEAR posX y posY del sensor al llegar al destino
      // Esto permite que el siguiente mapa comience desde cero
      if (widget.sensorService != null) {
        widget.sensorService!.posX = 0;
        widget.sensorService!.posY = 0;
        _initialSensorPosX = 0;
        _initialSensorPosY = 0;
        _lastSensorPosX = null;
        _lastSensorPosY = null;
      }
      
      return Offset(lastNode.x, lastNode.y);
    }

    // Obtener el segmento actual (del nodo actual al siguiente)
    final currentNode = widget.pathNodes[_currentNodeIndex];
    final nextNode = widget.pathNodes[_currentNodeIndex + 1];
    
    // Proyectar el punto del sensor sobre el segmento actual
    final projection = _projectPointOntoSegmentWithParam(
      sensorPoint,
      Offset(currentNode.x, currentNode.y),
      Offset(nextNode.x, nextNode.y),
    );
    
    final projectedPoint = projection.point;
    final t = projection.t; // 0 = inicio del segmento, 1 = fin del segmento
    
    // Calcular distancia del sensor al punto proyectado
    final dxToProjected = sensorPoint.dx - projectedPoint.dx;
    final dyToProjected = sensorPoint.dy - projectedPoint.dy;
    final distanceToRoute = math.sqrt(dxToProjected * dxToProjected + dyToProjected * dyToProjected);

    // SIEMPRE usar la proyección si está dentro del umbral
    // El marcador DEBE moverse siempre, sin condiciones
    if (distanceToRoute < maxDistanceFromRoute) {
      Offset finalPoint;
      
      if (t >= 1.0) {
        // Llegó al final del segmento: avanzar al siguiente nodo
        // Marcar el segmento actual como completado
        _completedSegmentsIndex = _currentNodeIndex;
        _currentNodeIndex++;
        _nearestNodeIndex = _currentNodeIndex;
        print("✅ Marcador llegó al nodo ${_currentNodeIndex} (${nextNode.id}), segmento ${_completedSegmentsIndex} completado");
        _lastMarkerX = nextNode.x;
        _lastMarkerY = nextNode.y;
        return Offset(nextNode.x, nextNode.y);
      } else {
        // SIEMPRE usar la proyección, sin importar t
        // Esto asegura movimiento continuo
        finalPoint = projectedPoint;
      }
      
      _nearestNodeIndex = _currentNodeIndex;
      _lastMarkerX = finalPoint.dx;
      _lastMarkerY = finalPoint.dy;
      return finalPoint;
    }

    // Si está lejos de la ruta, usar la proyección de todas formas si existe última posición
    // O usar el nodo actual como fallback
    if (_lastMarkerX != null && _lastMarkerY != null) {
      _nearestNodeIndex = _currentNodeIndex;
      return Offset(_lastMarkerX!, _lastMarkerY!);
    }

    _nearestNodeIndex = _currentNodeIndex;
    return Offset(currentNode.x, currentNode.y);
  }

  /// Proyecta un punto sobre un segmento de línea
  /// Retorna el punto proyectado y el parámetro t (0 = inicio, 1 = fin del segmento)
  ({Offset point, double t}) _projectPointOntoSegmentWithParam(Offset point, Offset segmentStart, Offset segmentEnd) {
    final A = point.dx - segmentStart.dx;
    final B = point.dy - segmentStart.dy;
    final C = segmentEnd.dx - segmentStart.dx;
    final D = segmentEnd.dy - segmentStart.dy;

    final dot = A * C + B * D;
    final lenSq = C * C + D * D;

    if (lenSq == 0) {
      return (point: segmentStart, t: 0.0); // Segmento es un punto
    }

    final param = dot / lenSq;

    // Clampear al segmento
    final t = param.clamp(0.0, 1.0);

    return (
      point: Offset(
        segmentStart.dx + t * C,
        segmentStart.dy + t * D,
      ),
      t: t,
    );
  }

  /// Proyecta un punto sobre un segmento de línea (versión simple)
  Offset _projectPointOntoSegment(Offset point, Offset segmentStart, Offset segmentEnd) {
    return _projectPointOntoSegmentWithParam(point, segmentStart, segmentEnd).point;
  }

  /// Encuentra el nodo más cercano a un punto
  ({int index, double distance}) _findNearestNodeToPoint(Offset point) {
    double minDistance = double.infinity;
    int nearestIndex = -1;

    for (int i = 0; i < widget.pathNodes.length; i++) {
      final node = widget.pathNodes[i];
      final dx = point.dx - node.x;
      final dy = point.dy - node.y;
      final distance = (dx * dx + dy * dy);

      if (distance < minDistance) {
        minDistance = distance;
        nearestIndex = i;
      }
    }

    return (index: nearestIndex, distance: minDistance);
  }

  /// Valida si puede avanzar a lo largo de un segmento según el heading
  bool _validateSegmentDirection(int segmentStartIndex, double heading) {
    if (segmentStartIndex < 0 || segmentStartIndex >= widget.pathNodes.length - 1) {
      return false;
    }

    final fromNode = widget.pathNodes[segmentStartIndex];
    final toNode = widget.pathNodes[segmentStartIndex + 1];
    final dx = toNode.x - fromNode.x;
    final dy = toNode.y - fromNode.y;
    
    // Calcular ángulo del segmento (0 = norte)
    double segmentAngle = math.atan2(dx, -dy);
    if (segmentAngle < 0) segmentAngle += 2 * math.pi;
    
    // Normalizar heading a [0, 2π]
    double normalizedHeading = heading;
    while (normalizedHeading < 0) normalizedHeading += 2 * math.pi;
    while (normalizedHeading >= 2 * math.pi) normalizedHeading -= 2 * math.pi;
    
    // Tolerancia de 60 grados (π/3 radianes)
    const double angleTolerance = math.pi / 3;
    
    double angleDiff = (normalizedHeading - segmentAngle).abs();
    if (angleDiff > math.pi) angleDiff = 2 * math.pi - angleDiff;
    
    return angleDiff < angleTolerance;
  }

  /// Valida si el movimiento es válido según el heading
  /// Retorna si puede moverse y hacia qué nodo
  ({bool canMove, int targetIndex}) _validateMovementDirection(int currentNodeIndex, double heading) {
    if (currentNodeIndex < 0 || currentNodeIndex >= widget.pathNodes.length) {
      return (canMove: false, targetIndex: currentNodeIndex);
    }

    final currentNode = widget.pathNodes[currentNodeIndex];
    
    // Calcular ángulo del segmento hacia adelante (si existe)
    double? forwardAngle;
    if (currentNodeIndex < widget.pathNodes.length - 1) {
      final nextNode = widget.pathNodes[currentNodeIndex + 1];
      final dx = nextNode.x - currentNode.x;
      final dy = nextNode.y - currentNode.y;
      // atan2(dy, dx) da el ángulo desde el eje X positivo
      // Convertir a sistema donde 0 = norte (como el heading del sensor)
      forwardAngle = math.atan2(dx, -dy); // Rotar 90°: norte = 0
      if (forwardAngle < 0) forwardAngle += 2 * math.pi;
    }
    
    // Calcular ángulo del segmento hacia atrás (si existe)
    double? backwardAngle;
    if (currentNodeIndex > 0) {
      final prevNode = widget.pathNodes[currentNodeIndex - 1];
      final dx = prevNode.x - currentNode.x;
      final dy = prevNode.y - currentNode.y;
      backwardAngle = math.atan2(dx, -dy);
      if (backwardAngle < 0) backwardAngle += 2 * math.pi;
    }
    
    // Normalizar heading a [0, 2π]
    double normalizedHeading = heading;
    while (normalizedHeading < 0) normalizedHeading += 2 * math.pi;
    while (normalizedHeading >= 2 * math.pi) normalizedHeading -= 2 * math.pi;
    
    // Tolerancia de 60 grados (π/3 radianes)
    const double angleTolerance = math.pi / 3;
    
    // Verificar si puede avanzar hacia adelante
    if (forwardAngle != null) {
      double angleDiff = (normalizedHeading - forwardAngle).abs();
      if (angleDiff > math.pi) angleDiff = 2 * math.pi - angleDiff;
      
      if (angleDiff < angleTolerance) {
        return (canMove: true, targetIndex: currentNodeIndex + 1);
      }
    }
    
    // Verificar si puede retroceder
    if (backwardAngle != null) {
      double angleDiff = (normalizedHeading - backwardAngle).abs();
      if (angleDiff > math.pi) angleDiff = 2 * math.pi - angleDiff;
      
      if (angleDiff < angleTolerance) {
        return (canMove: true, targetIndex: currentNodeIndex - 1);
      }
    }
    
    // No puede avanzar ni retroceder, mantener posición
    return (canMove: false, targetIndex: currentNodeIndex);
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
                        markerX: _calculateMarkerPosition()?.dx,
                        markerY: _calculateMarkerPosition()?.dy,
                        nearestNodeIndex: _nearestNodeIndex,
                        markerHeading: widget.sensorService?.heading,
                        completedSegmentsIndex: _completedSegmentsIndex,
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
        
        // El marcador del usuario se renderiza en NavigationMapPage para que se actualice correctamente
        
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
