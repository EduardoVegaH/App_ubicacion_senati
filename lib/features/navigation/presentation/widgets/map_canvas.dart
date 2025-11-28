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
  final String? destinationSalonName; // Nombre del salón destino para la etiqueta

  const MapCanvas({
    super.key,
    required this.floor,
    required this.svgAssetPath,
    required this.pathNodes,
    this.entranceNode,
    this.showNodes = false, // Por defecto ocultos
    this.sensorService,
    this.onControllerReady,
    this.destinationSalonName,
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
  
  // Control de seguimiento automático de la cámara
  bool _autoFollowEnabled = true; // Activo solo al inicio
  bool _hasUserInteracted = false; // Si el usuario ha interactuado manualmente
  bool _initialZoomDone = false; // Si ya se hizo el zoom inicial
  
  // Última posición del marcador para detectar movimiento
  Offset? _lastMarkerPosition;
  
  // Rotación de la cámara para mirar hacia la dirección de la ruta
  double _cameraRotation = 0.0; // En radianes
  int _lastRotationNodeIndex = -1; // Último nodo donde se actualizó la rotación

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
      widget.sensorService!.posX = 0;
      widget.sensorService!.posY = 0;
      
      // Guardar valores iniciales (serán 0 después del reset)
      _initialSensorPosX = 0;
      _initialSensorPosY = 0;
      _lastSensorPosX = null;
      _lastSensorPosY = null;
      
      widget.sensorService!.onDataChanged = () {
        if (mounted) {
          // Recalcular posición del marcador cuando cambian los datos del sensor
          final newMarkerPos = _calculateMarkerPosition();
          setState(() {
            // Actualizar UI
          });
          // Seguir al marcador automáticamente si está habilitado
          if (_autoFollowEnabled && !_hasUserInteracted && _initialZoomDone && newMarkerPos != null) {
            Future.microtask(() => _followMarker());
          }
        }
      };
    }
    
    // Hacer zoom inicial al marcador después de que el widget esté construido
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && !_initialZoomDone) {
          _zoomToMarker();
        }
      });
    });
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
            final newMarkerPos = _calculateMarkerPosition();
            setState(() {
              // Actualizar UI
            });
            if (_autoFollowEnabled && !_hasUserInteracted && _initialZoomDone && newMarkerPos != null) {
              Future.microtask(() => _followMarker());
            }
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
          final newMarkerPos = _calculateMarkerPosition();
          setState(() {
            // Actualizar UI
          });
          if (_autoFollowEnabled && !_hasUserInteracted && _initialZoomDone && newMarkerPos != null) {
            Future.microtask(() => _followMarker());
          }
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
    _hasUserInteracted = false;
    _autoFollowEnabled = false;
  }
  
  /// Hace zoom al marcador centrándolo en la pantalla
  void _zoomToMarker() {
    final markerPos = _calculateMarkerPosition();
    if (markerPos == null) return;
    
    final svgSize = widget.floor == 1 
        ? const Size(2808, 1416)
        : const Size(2117, 1729);
    
    // Obtener el tamaño del viewport
    final context = this.context;
    if (!context.mounted) return;
    final screenSize = MediaQuery.of(context).size;
    
    // Calcular cómo el SVG se renderiza en la pantalla (BoxFit.contain)
    final scaleX = screenSize.width / svgSize.width;
    final scaleY = screenSize.height / svgSize.height;
    final svgToScreenScale = scaleX < scaleY ? scaleX : scaleY;
    
    // Calcular offset para centrar el SVG
    final scaledWidth = svgSize.width * svgToScreenScale;
    final scaledHeight = svgSize.height * svgToScreenScale;
    final offsetX = (screenSize.width - scaledWidth) / 2;
    final offsetY = (screenSize.height - scaledHeight) / 2;
    
    // Convertir coordenadas del marcador (SVG) a coordenadas de pantalla
    final markerScreenX = offsetX + markerPos.dx * svgToScreenScale;
    final markerScreenY = offsetY + markerPos.dy * svgToScreenScale;
    
    // Calcular escala para zoom (similar a Google Maps - zoom moderado)
    final targetScale = 2.5; // Zoom moderado
    
    // Calcular el centro del viewport
    final centerX = screenSize.width / 2;
    final centerY = screenSize.height / 2;
    
    // Calcular la transformación necesaria para centrar el marcador
    final rotationMatrix = Matrix4.rotationZ(_cameraRotation);
    final matrix = Matrix4.identity()
      ..translate(centerX, centerY)
      ..scale(targetScale)
      ..multiply(rotationMatrix)
      ..translate(-markerScreenX, -markerScreenY);
    
    _transformationController.value = matrix;
    _scale = targetScale;
    _initialZoomDone = true;
  }
  
  /// Calcula el ángulo de dirección del siguiente segmento de la ruta
  double? _calculateRouteDirection() {
    if (widget.pathNodes.isEmpty || _currentNodeIndex < 0) return null;
    
    // Si estamos en el último nodo, usar el segmento anterior
    if (_currentNodeIndex >= widget.pathNodes.length - 1) {
      if (widget.pathNodes.length < 2) return null;
      final prevNode = widget.pathNodes[widget.pathNodes.length - 2];
      final currentNode = widget.pathNodes[widget.pathNodes.length - 1];
      final dx = currentNode.x - prevNode.x;
      final dy = currentNode.y - prevNode.y;
      final angle = math.atan2(dy, dx);
      return angle - (math.pi / 2);
    }
    
    // Calcular dirección del segmento actual
    final currentNode = widget.pathNodes[_currentNodeIndex];
    final nextNode = widget.pathNodes[_currentNodeIndex + 1];
    
    final dx = nextNode.x - currentNode.x;
    final dy = nextNode.y - currentNode.y;
    
    final routeAngle = math.atan2(dy, dx);
    return routeAngle - (math.pi / 2);
  }
  
  /// Actualiza la rotación de la cámara para mirar hacia la dirección de la ruta
  void _updateCameraRotation() {
    final routeDirection = _calculateRouteDirection();
    if (routeDirection == null) return;
    
    // Solo actualizar si la dirección cambió significativamente
    double normalizeAngle(double angle) {
      while (angle < 0) angle += 2 * math.pi;
      while (angle >= 2 * math.pi) angle -= 2 * math.pi;
      return angle;
    }
    
    final normalizedCurrent = normalizeAngle(_cameraRotation);
    final normalizedTarget = normalizeAngle(routeDirection);
    
    double angleDiff = (normalizedTarget - normalizedCurrent).abs();
    if (angleDiff > math.pi) {
      angleDiff = 2 * math.pi - angleDiff;
    }
    
    if (angleDiff < 0.087) { // ~5 grados
      _lastRotationNodeIndex = _currentNodeIndex;
      return;
    }
    
    _cameraRotation = routeDirection;
    _lastRotationNodeIndex = _currentNodeIndex;
    _updateCameraTransform();
  }
  
  /// Actualiza la transformación de la cámara con rotación y posición
  void _updateCameraTransform() {
    if (!_autoFollowEnabled) return;
    
    final markerPos = _calculateMarkerPosition();
    if (markerPos == null) return;
    
    final context = this.context;
    if (!context.mounted) return;
    final screenSize = MediaQuery.of(context).size;
    
    final svgSize = widget.floor == 1 
        ? const Size(2808, 1416)
        : const Size(2117, 1729);
    
    final scaleX = screenSize.width / svgSize.width;
    final scaleY = screenSize.height / svgSize.height;
    final svgToScreenScale = scaleX < scaleY ? scaleX : scaleY;
    
    final scaledWidth = svgSize.width * svgToScreenScale;
    final scaledHeight = svgSize.height * svgToScreenScale;
    final offsetX = (screenSize.width - scaledWidth) / 2;
    final offsetY = (screenSize.height - scaledHeight) / 2;
    
    final markerScreenX = offsetX + markerPos.dx * svgToScreenScale;
    final markerScreenY = offsetY + markerPos.dy * svgToScreenScale;
    
    // Mantener el zoom actual
    double currentScale = _scale > 1.0 ? _scale : 1.0;
    
    final centerX = screenSize.width / 2;
    final centerY = screenSize.height / 2;
    
    final translateToOrigin = Matrix4.identity()..translate(-markerScreenX, -markerScreenY);
    final rotation = Matrix4.rotationZ(_cameraRotation);
    final scale = Matrix4.identity()..scale(currentScale);
    final translateToCenter = Matrix4.identity()..translate(centerX, centerY);
    
    final matrix = translateToCenter * scale * rotation * translateToOrigin;
    
    _transformationController.value = matrix;
  }
  
  /// Sigue al marcador moviendo la cámara
  void _followMarker() {
    if (!_autoFollowEnabled) return;
    if (!_initialZoomDone) return;
    
    final markerPos = _calculateMarkerPosition();
    if (markerPos == null) return;
    
    // Detectar si el marcador se movió
    if (_lastMarkerPosition != null) {
      final distance = (markerPos - _lastMarkerPosition!).distance;
      if (distance < 2.0) return;
    }
    _lastMarkerPosition = markerPos;
    
    // Actualizar rotación si llegamos a un nodo nuevo
    if (_lastRotationNodeIndex != _currentNodeIndex) {
      _updateCameraRotation();
    }
    
    // Actualizar la transformación de la cámara
    _updateCameraTransform();
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
    const double maxDistanceFromRoute = 500.0; // Máxima distancia permitida desde la ruta (píxeles) - aumentado para evitar que se quede pegado

    // Calcular posición del sensor basada en posX y posY
    final sensorX = widget.entranceNode!.x + (widget.sensorService!.posX * pixelScale);
    final sensorY = widget.entranceNode!.y + (widget.sensorService!.posY * pixelScale);
    final sensorPoint = Offset(sensorX, sensorY);

    // Detectar si el sensor se está moviendo
    final sensorMoved = _lastSensorPosX != null && _lastSensorPosY != null &&
        (math.sqrt(math.pow(sensorX - _lastSensorPosX!, 2) + math.pow(sensorY - _lastSensorPosY!, 2)) > 0.5);

    // Actualizar última posición del sensor SIEMPRE
    _lastSensorPosX = sensorX;
    _lastSensorPosY = sensorY;

    // Si estamos en el último nodo, permitir movimiento pero mantener en el nodo final
    // RESETEAR posX y posY cuando se llega al destino final
    if (_currentNodeIndex >= widget.pathNodes.length - 1) {
      final lastNode = widget.pathNodes[widget.pathNodes.length - 1];
      _nearestNodeIndex = widget.pathNodes.length - 1;
      
      // RESETEAR posX y posY del sensor al llegar al destino
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

    // Verificar si el marcador debe avanzar basado en el progreso en el segmento
    // Comparar t actual con el t de la última posición
    double? lastT;
    if (_lastMarkerX != null && _lastMarkerY != null) {
      final lastProjection = _projectPointOntoSegmentWithParam(
        Offset(_lastMarkerX!, _lastMarkerY!),
        Offset(currentNode.x, currentNode.y),
        Offset(nextNode.x, nextNode.y),
      );
      lastT = lastProjection.t;
    }

    // SIEMPRE usar la proyección si está dentro del umbral O si el sensor se está moviendo
    if (distanceToRoute < maxDistanceFromRoute || (sensorMoved && t >= 0.0)) {
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
      } else if (t < 0.0 && lastT != null && lastT! > 0.0) {
        // Si t < 0 pero ya había progreso, mantener la última posición válida
        // pero solo si el sensor no se está moviendo hacia atrás
        _nearestNodeIndex = _currentNodeIndex;
        return Offset(_lastMarkerX!, _lastMarkerY!);
      } else if (t >= 0.0) {
        // Usar la proyección si t >= 0 (dentro o más adelante del segmento)
        finalPoint = projectedPoint;
        // Solo actualizar si es más adelante que la última posición o si el sensor se movió
        if (lastT == null || t >= lastT! || sensorMoved) {
          _nearestNodeIndex = _currentNodeIndex;
          _lastMarkerX = finalPoint.dx;
          _lastMarkerY = finalPoint.dy;
          return finalPoint;
        } else {
          // Mantener la última posición si no hay progreso hacia adelante
          _nearestNodeIndex = _currentNodeIndex;
          return Offset(_lastMarkerX!, _lastMarkerY!);
        }
      } else {
        // t < 0, usar el nodo actual como fallback
        finalPoint = Offset(currentNode.x, currentNode.y);
      }
      
      _nearestNodeIndex = _currentNodeIndex;
      _lastMarkerX = finalPoint.dx;
      _lastMarkerY = finalPoint.dy;
      return finalPoint;
    }

    // Si está lejos de la ruta pero el sensor se movió, intentar usar la proyección de todas formas
    if (sensorMoved && t >= 0.0 && t <= 1.0) {
      _nearestNodeIndex = _currentNodeIndex;
      _lastMarkerX = projectedPoint.dx;
      _lastMarkerY = projectedPoint.dy;
      return projectedPoint;
    }

    // Si existe última posición válida y el sensor no se movió, mantenerla
    // Pero si el sensor se movió y hay progreso, avanzar
    if (_lastMarkerX != null && _lastMarkerY != null) {
      if (!sensorMoved) {
        // Sensor no se movió, mantener posición
        _nearestNodeIndex = _currentNodeIndex;
        return Offset(_lastMarkerX!, _lastMarkerY!);
      } else if (t >= 0.0 && t <= 1.0) {
        // Sensor se movió y hay proyección válida, usarla
        _nearestNodeIndex = _currentNodeIndex;
        _lastMarkerX = projectedPoint.dx;
        _lastMarkerY = projectedPoint.dy;
        return projectedPoint;
      }
    }

    // Fallback: usar el nodo actual
    _nearestNodeIndex = _currentNodeIndex;
    _lastMarkerX = currentNode.x;
    _lastMarkerY = currentNode.y;
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

  @override
  Widget build(BuildContext context) {
    final svgSize = widget.floor == 1 
        ? const Size(2808, 1416)
        : const Size(2117, 1729);
    
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
          onInteractionStart: (details) {
            if (mounted) {
              setState(() {
                _hasUserInteracted = true; // Bloquear seguimiento automático
              });
            }
          },
          onInteractionEnd: (details) {
            if (mounted) {
              setState(() {
                _hasUserInteracted = false; // Reactivar seguimiento automático
              });
            }
          },
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
                        routeWidth: 3.0,
                        destinationColor: const Color(0xFF00C853),
                        svgWidth: svgSize.width,
                        svgHeight: svgSize.height,
                        startNodeRadius: 5.0, // Tamaño del punto de inicio
                        destinationNodeRadius: 5.0, // Tamaño del punto de destino
                        destinationSalonName: widget.destinationSalonName,
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

