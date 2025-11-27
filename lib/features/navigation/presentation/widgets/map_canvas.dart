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

class _MapCanvasState extends State<MapCanvas> with SingleTickerProviderStateMixin {
  final TransformationController _transformationController =
      TransformationController();
  double _scale = 1.0;
  Matrix4 _currentTransform = Matrix4.identity();
  double _lastKnownGoodScale = 1.0; // Último scale conocido que funcionó bien
  
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
  bool _zoomRendered = false; // Si el zoom ya se renderizó visualmente
  bool _svgLoaded = false; // Si el SVG está completamente cargado
  
  // Última posición del marcador para detectar movimiento
  Offset? _lastMarkerPosition;
  
  // Rotación de la cámara para mirar hacia la dirección de la ruta
  double _cameraRotation = 0.0; // En radianes
  int _lastRotationNodeIndex = -1; // Último nodo donde se actualizó la rotación
  late AnimationController _rotationAnimationController;
  Animation<double>? _rotationAnimation;

  @override
  void initState() {
    super.initState();
    
    // Inicializar AnimationController para rotación suave
    _rotationAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    // Resetear completamente el estado al inicializar
    _currentNodeIndex = 0;
    _completedSegmentsIndex = -1;
    _lastMarkerX = null;
    _lastMarkerY = null;
    _nearestNodeIndex = null;
    _lastSensorPosX = null;
    _lastSensorPosY = null;
    _lastRotationNodeIndex = -1;
    _cameraRotation = 0.0;
    
    _transformationController.addListener(() {
      // NO llamar _onTransformChanged aquí para evitar que se rompa el zoom
      // Solo actualizar el estado si es necesario
      if (mounted) {
        // Solo actualizar _currentTransform, NO tocar _scale
        setState(() {
          _currentTransform = _transformationController.value;
        });
        
        // NO hacer nada aquí - el zoom y rotación inicial ya se aplicaron en _applyInitialRotationFirst
        // Este listener solo actualiza _currentTransform, no debe volver a aplicar zoom
        // Si el zoom inicial ya se aplicó, NO volver a aplicarlo
      }
    });
    
    // NO agregar listener duplicado - ya tenemos uno arriba que maneja todo
    // El listener duplicado puede estar causando que se rompa el zoom
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
                // Seguir al marcador automáticamente si está habilitado (fuera de setState)
                // PERO NO si el zoom inicial aún no se ha completado
                if (_autoFollowEnabled && !_hasUserInteracted && _initialZoomDone && newMarkerPos != null) {
                  Future.microtask(() => _followMarker());
                }
              }
            };
    }
    
    // Hacer zoom inicial al marcador después de que el widget esté construido
    // PERO solo después de que el SVG esté completamente cargado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Esperar a que el SVG esté cargado antes de aplicar zoom
      _waitForSvgAndApplyZoom();
    });
  }
  
  /// Espera a que el SVG esté cargado y luego aplica primero la rotación, luego el zoom
  void _waitForSvgAndApplyZoom() {
    // Verificar periódicamente si el SVG está cargado (delay mínimo)
    Future.delayed(const Duration(milliseconds: 30), () {
      if (mounted && !_initialZoomDone) {
        if (_svgLoaded) {
          // SVG está cargado, aplicar rotación inmediatamente
          Future.microtask(() {
            if (mounted && !_initialZoomDone && _svgLoaded) {
              // PASO 1: Aplicar rotación inicial (sin zoom)
              _applyInitialRotationFirst();
            }
          });
        } else {
          // SVG aún no está cargado, intentar de nuevo (más rápido)
          if (!_initialZoomDone) {
            _waitForSvgAndApplyZoom();
          }
        }
      }
    });
  }
  
  /// Aplica primero la rotación inicial (sin zoom), luego el zoom
  /// SOLO se ejecuta una vez cuando se carga el mapa
  void _applyInitialRotationFirst() {
    // Si el zoom inicial ya se aplicó, NO hacer nada (previene llamadas duplicadas)
    // Esto evita que se vuelva a aplicar el zoom cuando el marcador se mueve
    if (_initialZoomDone) {
      print("⚠️ Rotación inicial ya aplicada, ignorando llamada duplicada");
      return;
    }
    
    final routeDirection = _calculateRouteDirection();
    if (routeDirection != null) {
      _cameraRotation = routeDirection;
      _lastRotationNodeIndex = _currentNodeIndex;
      
      // Aplicar rotación SIN zoom (zoom = 1.0)
      final markerPos = _calculateMarkerPosition();
      if (markerPos != null) {
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
        
        final centerX = screenSize.width / 2;
        final centerY = screenSize.height / 2;
        
        // Aplicar solo rotación (sin zoom, scale = 1.0)
        final rotationMatrix = Matrix4.rotationZ(_cameraRotation);
        final matrix = Matrix4.identity()
          ..translate(centerX, centerY)
          ..scale(1.0) // Sin zoom todavía
          ..multiply(rotationMatrix)
          ..translate(-markerScreenX, -markerScreenY);
        
        _transformationController.value = matrix;
        
        // Aplicar zoom inmediatamente después de la rotación (sin delay)
        // PERO solo si el zoom inicial aún no se ha aplicado
        if (!_initialZoomDone) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Future.microtask(() {
              if (mounted && !_initialZoomDone) {
                // PASO 2: Aplicar zoom sobre la rotación
                _zoomToMarker(initialZoom: true);
              }
            });
          });
        }
      }
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
                // Recalcular posición del marcador cuando cambian los datos del sensor
                final newMarkerPos = _calculateMarkerPosition();
                setState(() {
                  // Actualizar UI
                });
                // Seguir al marcador automáticamente si está habilitado (fuera de setState)
                // PERO NO si el zoom inicial aún no se ha completado
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
                // Recalcular posición del marcador cuando cambian los datos del sensor
                final newMarkerPos = _calculateMarkerPosition();
                setState(() {
                  // Actualizar UI
                });
                // Seguir al marcador automáticamente si está habilitado (fuera de setState)
                // PERO NO si el zoom inicial aún no se ha completado
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
    _rotationAnimationController.dispose();
    // RESETEAR posX y posY del sensor al cerrar el mapa
    if (widget.sensorService != null) {
      widget.sensorService!.posX = 0;
      widget.sensorService!.posY = 0;
      widget.sensorService!.onDataChanged = null;
    }
    super.dispose();
  }

  void _onTransformChanged() {
    // NO actualizar _scale aquí para evitar parpadeo y pérdida de zoom
    // El scale solo se actualiza cuando:
    // 1. Se aplica el zoom inicial (_zoomToMarker)
    // 2. El usuario hace zoom manualmente (se detecta en onInteractionStart)
    // 3. Se actualiza la transformación programáticamente (_updateCameraTransform)
    
    // Este método ya no se usa directamente, se usa _debounceTransformUpdate
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
    _hasUserInteracted = false;
    _autoFollowEnabled = false;
  }
  
  /// Hace zoom al marcador centrándolo en la pantalla
  /// [initialZoom] indica si es el zoom inicial al abrir el mapa
  void _zoomToMarker({bool initialZoom = false}) {
    // Si el zoom inicial ya se aplicó y estamos intentando aplicarlo de nuevo, NO hacer nada
    // Esto previene llamadas duplicadas que causan que el zoom se aleje y luego se acerque
    if (initialZoom && _initialZoomDone) {
      print("⚠️ Zoom inicial ya aplicado, ignorando llamada duplicada");
      return;
    }
    
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
    final svgToScreenScale = scaleX < scaleY ? scaleX : scaleY; // Escala del SVG a pantalla
    
    // Calcular offset para centrar el SVG
    final scaledWidth = svgSize.width * svgToScreenScale;
    final scaledHeight = svgSize.height * svgToScreenScale;
    final offsetX = (screenSize.width - scaledWidth) / 2;
    final offsetY = (screenSize.height - scaledHeight) / 2;
    
    // Convertir coordenadas del marcador (SVG) a coordenadas de pantalla
    final markerScreenX = offsetX + markerPos.dx * svgToScreenScale;
    final markerScreenY = offsetY + markerPos.dy * svgToScreenScale;
    
    // Calcular escala para zoom (similar a Google Maps - zoom moderado)
    // Escala inicial: 2.5x (zoom moderado, no gigante)
    final targetScale = initialZoom ? 2.5 : _scale;
    
    // Calcular el centro del viewport
    final centerX = screenSize.width / 2;
    final centerY = screenSize.height / 2;
    
    // Calcular la transformación necesaria para centrar el marcador
    // Si ya hay rotación aplicada, mantenerla al aplicar el zoom
    if (_cameraRotation != 0.0) {
      // Aplicar zoom SOBRE la rotación existente
      // Orden: T(center) * S(scale) * R(rotation) * T(-marker)
      final rotationMatrix = Matrix4.rotationZ(_cameraRotation);
      final matrix = Matrix4.identity()
        ..translate(centerX, centerY)
        ..scale(targetScale) // Aplicar zoom
        ..multiply(rotationMatrix) // Mantener rotación
        ..translate(-markerScreenX, -markerScreenY);
      
      _transformationController.value = matrix;
    } else {
      // Sin rotación, aplicar solo zoom
      final matrix = Matrix4.identity()
        ..translate(centerX, centerY)
        ..scale(targetScale)
        ..translate(-markerScreenX, -markerScreenY);
      
      _transformationController.value = matrix;
    }
    
    _scale = targetScale;
    _lastKnownGoodScale = targetScale; // Guardar el scale inicial como conocido bueno
    _initialZoomDone = true;
    
    // IMPORTANTE: Marcar que el zoom inicial está completo
    // Esto previene que _followMarker() interfiera antes de que el zoom se complete
    print("✅ Zoom inicial aplicado: scale = $_scale");
  }
  
  /// Calcula el ángulo de dirección del siguiente segmento de la ruta
  /// Retorna el ángulo en radianes que la cámara debe rotar para "mirar" hacia la ruta
  double? _calculateRouteDirection() {
    if (widget.pathNodes.isEmpty || _currentNodeIndex < 0) return null;
    
    // Si estamos en el último nodo, usar el segmento anterior
    if (_currentNodeIndex >= widget.pathNodes.length - 1) {
      if (widget.pathNodes.length < 2) return null;
      final prevNode = widget.pathNodes[widget.pathNodes.length - 2];
      final currentNode = widget.pathNodes[widget.pathNodes.length - 1];
      final dx = currentNode.x - prevNode.x;
      final dy = currentNode.y - prevNode.y;
      // Calcular ángulo y ajustar para que "arriba" de la pantalla apunte hacia la dirección de la ruta
      final angle = math.atan2(dy, dx);
      // Ajustar: en Flutter, "arriba" es -Y, así que restamos π/2
      return angle - (math.pi / 2);
    }
    
    // Calcular dirección del segmento actual (del nodo actual al siguiente)
    final currentNode = widget.pathNodes[_currentNodeIndex];
    final nextNode = widget.pathNodes[_currentNodeIndex + 1];
    
    final dx = nextNode.x - currentNode.x;
    final dy = nextNode.y - currentNode.y;
    
    // Calcular ángulo de la ruta (0 = derecha, π/2 = abajo, -π/2 = arriba)
    final routeAngle = math.atan2(dy, dx);
    
    // Ajustar para que "arriba" de la pantalla apunte hacia donde va la ruta
    // En Flutter, "arriba" es -Y, así que restamos π/2
    return routeAngle - (math.pi / 2);
  }
  
  /// Actualiza la rotación de la cámara para mirar hacia la dirección de la ruta
  /// Solo se actualiza cuando el marcador llega a un nodo
  /// La rotación SIEMPRE funciona, incluso si el usuario interactuó (solo el zoom es estático)
  void _updateCameraRotation() {
    // La rotación SIEMPRE debe funcionar, incluso si el usuario interactuó
    // Solo el zoom es estático cuando el usuario interactúa
    final routeDirection = _calculateRouteDirection();
    if (routeDirection == null) return;
    
    // Verificar si la dirección realmente cambió (comparar con la rotación actual)
    // Normalizar ambos ángulos a [0, 2π] para comparar correctamente
    double normalizeAngle(double angle) {
      while (angle < 0) angle += 2 * math.pi;
      while (angle >= 2 * math.pi) angle -= 2 * math.pi;
      return angle;
    }
    
    final normalizedCurrent = normalizeAngle(_cameraRotation);
    final normalizedTarget = normalizeAngle(routeDirection);
    
    // Calcular la diferencia mínima de ángulo (considerando que puede ser en sentido horario o antihorario)
    double angleDiff = (normalizedTarget - normalizedCurrent).abs();
    if (angleDiff > math.pi) {
      angleDiff = 2 * math.pi - angleDiff;
    }
    
    // Solo actualizar si la dirección cambió significativamente (más de 5 grados)
    if (angleDiff < 0.087) { // ~5 grados en radianes
      // Actualizar el índice de nodo de rotación sin animar
      _lastRotationNodeIndex = _currentNodeIndex;
      return;
    }
    
    // Convertir el ángulo de la ruta a rotación de cámara
    final targetRotation = routeDirection;
    
    // Si ya hay una animación en curso, cancelarla
    if (_rotationAnimationController.isAnimating) {
      _rotationAnimationController.stop();
    }
    
    // Crear animación suave para la rotación
    _rotationAnimation = Tween<double>(
      begin: _cameraRotation,
      end: targetRotation,
    ).animate(CurvedAnimation(
      parent: _rotationAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _rotationAnimation!.addListener(() {
      if (mounted) {
        setState(() {
          _cameraRotation = _rotationAnimation!.value;
        });
        // Actualizar la transformación de la cámara con la nueva rotación
        // Esto mantendrá el zoom actual
        _updateCameraTransform();
      }
    });
    
    _lastRotationNodeIndex = _currentNodeIndex;
    _rotationAnimationController.forward(from: 0.0);
  }
  
  /// Actualiza la transformación de la cámara con rotación y posición
  /// El seguimiento y rotación SIEMPRE funcionan, solo el zoom es estático si el usuario interactuó
  void _updateCameraTransform() {
    // El seguimiento y rotación deben seguir funcionando incluso si el usuario interactuó
    // Solo el zoom se mantiene estático
    if (!_autoFollowEnabled) return;
    
    final markerPos = _calculateMarkerPosition();
    if (markerPos == null) return;
    
    final context = this.context;
    if (!context.mounted) return;
    final screenSize = MediaQuery.of(context).size;
    
    final svgSize = widget.floor == 1 
        ? const Size(2808, 1416)
        : const Size(2117, 1729);
    
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
    
    // Obtener la escala actual para mantener el zoom
    // SIEMPRE usar _scale si está disponible y es mayor que 1 (zoom aplicado)
    // NUNCA recalcular desde la matriz si ya tenemos un zoom aplicado
    // Esto asegura que el zoom no se pierda cuando el marcador se mueve
    double currentScale;
    if (_scale > 1.0 && _initialZoomDone) {
      // Usar el zoom que ya se estableció - NO cambiar esto NUNCA
      // Esto previene que el zoom se aleje cuando el marcador se mueve
      currentScale = _scale;
    } else if (_scale > 1.0) {
      // Si tenemos un scale guardado pero el zoom inicial aún no se completó, usarlo
      currentScale = _scale;
    } else {
      // Solo calcular desde la matriz si NO tenemos zoom aplicado
      currentScale = _transformationController.value.getMaxScaleOnAxis();
      // Si el scale calculado es razonable, guardarlo
      if (currentScale > 1.0) {
        _scale = currentScale;
      }
    }
    
    // PROTECCIÓN ADICIONAL: Si el zoom inicial ya se aplicó, SIEMPRE usar _scale
    // Nunca permitir que el zoom baje después de que se aplicó inicialmente
    if (_initialZoomDone && _scale > 1.0) {
      currentScale = _scale; // Forzar uso del scale guardado
    }
    
    // Calcular el centro del viewport
    final centerX = screenSize.width / 2;
    final centerY = screenSize.height / 2;
    
    // Calcular la transformación: rotar alrededor del marcador, luego centrar y escalar
    // Orden de transformaciones (aplicadas de derecha a izquierda en Matrix4):
    // 1. Mover el marcador al origen: translate(-markerScreenX, -markerScreenY)
    // 2. Rotar alrededor del origen: rotateZ
    // 3. Escalar: scale(currentScale) - MANTENER EL ZOOM EXACTO
    // 4. Mover al centro de la pantalla: translate(centerX, centerY)
    
    // Crear la matriz paso a paso para asegurar que el zoom se mantenga
    // Para rotar alrededor del marcador manteniendo el zoom:
    // M = T(center) * S(scale) * R(rotation) * T(-marker)
    //
    // Construir cada transformación por separado y multiplicar en orden
    final translateToOrigin = Matrix4.identity()..translate(-markerScreenX, -markerScreenY);
    final rotation = Matrix4.rotationZ(_cameraRotation);
    final scale = Matrix4.identity()..scale(currentScale); // MANTENER EL ZOOM EXACTO
    final translateToCenter = Matrix4.identity()..translate(centerX, centerY);
    
    // Multiplicar en el orden correcto: T(center) * S(scale) * R(rotation) * T(-marker)
    final matrix = translateToCenter * scale * rotation * translateToOrigin;
    
    // Aplicar la transformación
    _transformationController.value = matrix;
  }
  
  /// Sigue al marcador moviendo la cámara (solo si el seguimiento está activo)
  /// El seguimiento SIEMPRE funciona, incluso si el usuario interactuó (solo el zoom es estático)
  void _followMarker() {
    // El seguimiento debe seguir funcionando incluso si el usuario interactuó
    // Solo el zoom se mantiene estático
    if (!_autoFollowEnabled) return;
    // NO seguir si el zoom inicial aún no se ha completado (previene interferencia)
    if (!_initialZoomDone) return;
    
    final markerPos = _calculateMarkerPosition();
    if (markerPos == null) return;
    
    // Detectar si el marcador se movió (comparar con última posición conocida)
    if (_lastMarkerPosition != null) {
      final distance = (markerPos - _lastMarkerPosition!).distance;
      // Solo seguir si el marcador se movió más de 2 píxeles (evitar actualizaciones innecesarias)
      if (distance < 2.0) return;
    }
    _lastMarkerPosition = markerPos;
    
    // Actualizar rotación si llegamos a un nodo nuevo
    _updateCameraRotation();
    
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
        
        // Actualizar rotación de la cámara cuando llegamos a un nodo (cambio de dirección)
        Future.microtask(() => _updateCameraRotation());
        
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
            // Cuando el usuario empieza a interactuar, bloquear el seguimiento automático
            // El seguimiento se reactivará cuando suelte la pantalla
            if (mounted) {
              // Guardar el scale y la transformación actual ANTES de cualquier cambio
              final currentMatrix = _transformationController.value;
              var currentScale = currentMatrix.getMaxScaleOnAxis();
              
              // SIEMPRE guardar el scale si es razonable
              if (currentScale >= 1.0) {
                _scale = currentScale;
                _lastKnownGoodScale = currentScale;
              } else if (_scale > 1.0) {
                // Si el scale actual es menor pero tenemos uno guardado, usar el guardado
                // Esto previene que el zoom desaparezca
                currentScale = _scale;
              }
              
              setState(() {
                _hasUserInteracted = true; // Bloquear seguimiento automático
              });
              
              // Si el scale es menor que el guardado, restaurarlo para mantener el zoom
              if (_scale > 1.0 && currentScale < _scale * 0.9) {
                // El zoom se está perdiendo, restaurarlo
                final scaleFactor = _scale / currentScale;
                final restoredMatrix = currentMatrix.clone();
                restoredMatrix.scale(scaleFactor);
                _transformationController.value = restoredMatrix;
              }
            }
          },
          onInteractionEnd: (details) {
            // Cuando el usuario suelta la pantalla, reactivar el seguimiento automático
            if (mounted) {
              setState(() {
                _hasUserInteracted = false; // Reactivar seguimiento automático
              });
            }
          },
          onInteractionUpdate: (details) {
            // Cuando el usuario está interactuando, actualizar el scale si está haciendo zoom
            if (mounted && _hasUserInteracted) {
              final currentScale = _transformationController.value.getMaxScaleOnAxis();
              // Solo actualizar si el scale es razonable (>= 1.0) y es diferente
              if (currentScale >= 1.0 && (currentScale - _scale).abs() > 0.05) {
                setState(() {
                  _scale = currentScale;
                  _lastKnownGoodScale = currentScale;
                });
              }
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
                  
                  // Marcar que el SVG está cargado y esperar a que se renderice
                  // Reducir frame callbacks y delays para aplicar zoom más rápido
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        _svgLoaded = true;
                        // Aplicar zoom casi inmediatamente (delay mínimo)
                        Future.delayed(const Duration(milliseconds: 30), () {
                          if (mounted && !_initialZoomDone) {
                            _waitForSvgAndApplyZoom();
                          }
                        });
                      }
                    });
                  });
                  
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

