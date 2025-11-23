import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math' as math;
import '../models/map_node.dart';
import '../models/edge.dart';
import '../repos/graph_repository.dart';
import '../services/pathfinding_service.dart';
import '../config/graph_edges_config.dart';
import 'map_overlay_painter.dart';
import 'salon_photo_popup.dart';
import 'user_location_marker.dart';

/// Pantalla de navegación que muestra el mapa SVG con la ruta trazada
class MapNavigatorScreen extends StatefulWidget {
  /// ID del salón objetivo (ej: "salon-A-201" o "A-201")
  final String objetivoSalonId;
  
  /// Piso del mapa a mostrar
  final int piso;
  
  /// Nombre del salón (para mostrar en UI)
  final String? salonNombre;

  const MapNavigatorScreen({
    super.key,
    required this.objetivoSalonId,
    required this.piso,
    this.salonNombre,
  });

  @override
  State<MapNavigatorScreen> createState() => _MapNavigatorScreenState();
}

class _MapNavigatorScreenState extends State<MapNavigatorScreen> with TickerProviderStateMixin {
  final GraphRepository _graphRepository = GraphRepository();
  final TransformationController _transformationController =
      TransformationController();
  
  List<Edge> _pathEdges = []; // Lista de edges con shapes que forman la ruta
  MapNode? _destinationNode;
  MapNode? _entranceNode;
  List<MapNode> _allNodes = [];
  bool _loading = true;
  String? _errorMessage;
  double _scale = 1.0;
  int _pisoCargado = 1; // Piso que realmente se cargó (puede ser diferente al solicitado)
  
  // Preparado para futuro: nodo actual del usuario en tiempo real
  MapNode? _currentUserNode;
  
  // Control para mostrar/ocultar la foto del salón superpuesta sobre el mapa
  bool _showPhoto = false;
  
  // Controlador de animación para la foto
  late AnimationController _photoAnimationController;
  
  // Cache del SVG procesado para evitar reprocesarlo en cada build
  String? _cachedProcessedSvg;
  String? _cachedSvgPath;
  
  // Servicio de sensores para tracking del usuario
  SensorService? _sensorService;

  @override
  void initState() {
    super.initState();
    _transformationController.addListener(_onTransformChanged);
    
    // Inicializar controlador de animación para la foto
    _photoAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    // Inicializar servicio de sensores para el marcador del usuario
    _sensorService = SensorService();
    _sensorService!.onDataChanged = () {
      if (mounted) {
        setState(() {}); // Actualizar UI cuando cambie el heading, posX o posY
      }
    };
    _sensorService!.start();
    
    _loadMapAndCalculateRoute();
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onTransformChanged);
    _transformationController.dispose();
    _photoAnimationController.dispose();
    _sensorService?.stop();
    super.dispose();
  }

  void _onTransformChanged() {
    final value = _transformationController.value;
    final newScale = value.getMaxScaleOnAxis();
    if ((newScale - _scale).abs() > 0.01) {
      setState(() {
        _scale = newScale;
        // Forzar rebuild del overlay para que se actualice con la nueva transformación
      });
    }
  }

  /// Muestra la foto del salón con animación desde abajo
  void _showSalonPhoto() {
    // Solo mostrar si existe una imagen para este salón
    if (!_hasSalonImage()) {
      print('⚠️ No hay imagen disponible para el salón: ${widget.objetivoSalonId}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No hay foto disponible para ${widget.salonNombre ?? widget.objetivoSalonId}'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    print('📸 Mostrando foto del salón con animación');
    setState(() {
      _showPhoto = true;
    });
    _photoAnimationController.forward();
  }

  /// Oculta la foto del salón con animación hacia abajo
  void _hideSalonPhoto() {
    print('❌ Ocultando foto del salón');
    _photoAnimationController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _showPhoto = false;
        });
      }
    });
  }

  /// Obtiene la ruta de la imagen del salón basada en el ID del salón
  String _getSalonImagePath() {
    // Normalizar el ID del salón para construir la ruta
    String salonId = widget.objetivoSalonId.toLowerCase().trim();
    
    // Remover prefijos comunes como "salon-"
    if (salonId.startsWith('salon-')) {
      salonId = salonId.substring(6); // Remover "salon-"
    }
    
    // Construir la ruta de la imagen
    // Formato esperado: assets/fotosalon/foto-salon-{TORRE}-{NUMERO}.png
    // Ejemplo: "B-200" -> "foto-salon-b-200.png"
    // Ejemplo: "salon-B-200" -> "foto-salon-b-200.png"
    final imagePath = 'assets/fotosalon/foto-salon-$salonId.png';
    
    print('🖼️ Ruta de imagen calculada: $imagePath para salón: ${widget.objetivoSalonId}');
    
    return imagePath;
  }

  /// Verifica si existe una imagen para el salón actual
  /// Por ahora solo existe foto-salon-b-200.png
  bool _hasSalonImage() {
    String salonId = widget.objetivoSalonId.toLowerCase().trim();
    if (salonId.startsWith('salon-')) {
      salonId = salonId.substring(6);
    }
    
    // Lista de salones que tienen foto (por ahora solo B-200)
    final salonesConFoto = ['b-200'];
    
    return salonesConFoto.contains(salonId);
  }

  Future<void> _loadMapAndCalculateRoute() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      // 1. Cargar el grafo del piso
      // Si el piso solicitado no existe, intentar con piso 2 como fallback
      int pisoACargar = widget.piso;
      if (pisoACargar != 1 && pisoACargar != 2) {
        print('⚠️ Piso ${widget.piso} no existe, usando piso 2 como fallback');
        pisoACargar = 2;
      }
      _pisoCargado = pisoACargar; // Guardar el piso que realmente se carga
      
      final graph = await _graphRepository.loadGraph(pisoACargar);
      _allNodes = graph['nodes'] as List<MapNode>;
      
      if (_allNodes.isEmpty) {
        throw Exception(
          'No se encontraron nodos para el piso $pisoACargar.\n\n'
          'Por favor, contacta al administrador para inicializar el grafo.',
        );
      }

      // 2. Buscar nodo más cercano a los ascensores (punto de inicio)
      // OPTIMIZACIÓN: Pasar los nodos ya cargados para evitar otra consulta a Firestore
      print('🔍 Buscando nodo más cercano a los ascensores...');
      _entranceNode = await _graphRepository.findNearestElevatorNode(pisoACargar, nodes: _allNodes);
      if (_entranceNode == null) {
        // Si no se encuentra, intentar con la entrada principal
        // OPTIMIZACIÓN: Pasar los nodos ya cargados
        print('⚠️ No se encontró nodo cercano a ascensores, usando entrada principal');
        _entranceNode = await _graphRepository.findEntranceNode(pisoACargar, nodes: _allNodes);
        if (_entranceNode == null) {
          // Si aún no hay, usar el primer nodo
          _entranceNode = _allNodes.first;
        }
      }
      print('✅ Nodo de inicio seleccionado: ${_entranceNode!.id}');

      // 3. Buscar nodo destino (asociado al salón)
      // OPTIMIZACIÓN: Pasar los nodos ya cargados para evitar otra consulta a Firestore
      print('🔍 Buscando nodo para salón: ${widget.objetivoSalonId} en piso $pisoACargar');
      _destinationNode = await _graphRepository.findNodeBySalon(
        piso: pisoACargar,
        salonId: widget.objetivoSalonId,
        nodes: _allNodes, // Pasar nodos ya cargados
      );

      if (_destinationNode == null) {
        print('⚠️ No se encontró nodo con el método principal, intentando búsqueda flexible...');
        // Si aún no se encontró, intentar una búsqueda más flexible
        final salonNumber = widget.objetivoSalonId.replaceAll(RegExp(r'[^0-9]'), '');
        print('🔍 Número del salón extraído: $salonNumber');
        
        if (salonNumber.isNotEmpty) {
          // Buscar cualquier nodo que tenga el número
          try {
            _destinationNode = _allNodes.firstWhere(
              (node) => node.id.contains(salonNumber) ||
                        (node.salonId != null && node.salonId!.contains(salonNumber)),
            );
            print('✅ Nodo encontrado por búsqueda flexible: ${_destinationNode!.id}');
          } catch (e) {
            print('⚠️ No se encontró nodo con búsqueda flexible: $e');
            // Si aún no se encuentra, usar el nodo más cercano al centro
            print('⚠️ Usando nodo central como destino');
            if (_allNodes.isNotEmpty) {
              // Calcular centro y encontrar nodo más cercano
              double sumX = 0, sumY = 0;
              for (final node in _allNodes) {
                sumX += node.x;
                sumY += node.y;
              }
              final centerX = sumX / _allNodes.length;
              final centerY = sumY / _allNodes.length;
              
              MapNode? nearest;
              double minDist = double.infinity;
              for (final node in _allNodes) {
                final dx = node.x - centerX;
                final dy = node.y - centerY;
                final dist = (dx * dx + dy * dy);
                if (dist < minDist) {
                  minDist = dist;
                  nearest = node;
                }
              }
              _destinationNode = nearest;
              print('✅ Usando nodo central: ${_destinationNode!.id}');
            }
          }
        }
        
        // Si aún es null, lanzar excepción
        if (_destinationNode == null) {
          print('❌ No se pudo encontrar ningún nodo para el salón ${widget.objetivoSalonId}');
          throw Exception(
            'No se encontró nodo para el salón ${widget.objetivoSalonId}.\n\n'
            'El salón puede no estar mapeado en el grafo.\n'
            'Intenta inicializar el grafo nuevamente o verifica que el salón existe.',
          );
        }
      } else {
        print('✅ Nodo destino encontrado: ${_destinationNode!.id}');
      }

      // 4. Calcular ruta con A*
      print('🗺️ Calculando ruta desde ${_entranceNode!.id} hasta ${_destinationNode!.id}');
      final edges = (graph['edges'] as List).cast<Edge>();
      print('📊 Total de edges disponibles: ${edges.length}');
      
      // Para piso 2, verificar que solo se usen edges manuales
      if (_pisoCargado == 2) {
        print('🔍 Verificando que solo se usen edges manuales para piso 2...');
        final manualEdges = await GraphEdgesConfig.getManualEdgesForFloor(2, _allNodes);
        final manualEdgeIds = manualEdges.map((e) => '${e.fromId}_${e.toId}').toSet();
        final currentEdgeIds = edges.map((e) => '${e.fromId}_${e.toId}').toSet();
        
        if (manualEdgeIds != currentEdgeIds) {
          print('⚠️ ADVERTENCIA: Los edges cargados no coinciden exactamente con los manuales');
          print('   Edges manuales esperados: ${manualEdgeIds.length}');
          print('   Edges cargados: ${currentEdgeIds.length}');
        } else {
          print('✅ Confirmado: Solo se están usando edges manuales (${edges.length} edges)');
        }
      }
      
      // Verificar que ambos nodos estén conectados
      final startEdges = edges.where((e) => e.fromId == _entranceNode!.id).toList();
      final endEdges = edges.where((e) => e.toId == _destinationNode!.id || e.fromId == _destinationNode!.id).toList();
      print('🔗 Edges desde entrada (${_entranceNode!.id}): ${startEdges.map((e) => e.toId).join(", ")}');
      print('🔗 Edges hacia/hasta destino (${_destinationNode!.id}): ${endEdges.length}');
      
      _pathEdges = PathfindingService.findPathAStar(
        startNodeId: _entranceNode!.id,
        endNodeId: _destinationNode!.id,
        nodes: _allNodes,
        edges: edges,
      );

      if (_pathEdges.isEmpty) {
        print('❌ No se encontró ruta. Entrada: ${_entranceNode!.id}, Destino: ${_destinationNode!.id}');
        print('📊 Nodos totales: ${_allNodes.length}, Edges totales: ${edges.length}');
        throw Exception(
          'No se encontró ruta al salón ${widget.objetivoSalonId}.\n\n'
          'Nodo destino: ${_destinationNode!.id}\n'
          'Nodo entrada: ${_entranceNode!.id}\n\n'
          'Posibles causas:\n'
          '1. El grafo no está completamente conectado\n'
          '2. El nodo destino no tiene conexiones\n'
          '3. Necesitas reinicializar el grafo con más conexiones',
        );
      }
      
      print('✅ Ruta encontrada con ${_pathEdges.length} edges');
      
      // Extraer IDs de nodos para logging
      final pathNodeIds = <String>[];
      if (_pathEdges.isNotEmpty) {
        pathNodeIds.add(_pathEdges.first.fromId);
        for (final edge in _pathEdges) {
          pathNodeIds.add(edge.toId);
        }
      }
      
      print('📊 Ruta completa (${_pathEdges.length} edges): ${pathNodeIds.join(" -> ")}');
      print('📊 Shapes en edges: ${_pathEdges.where((e) => e.shape.isNotEmpty).length} edges con shapes');
      
      // 7. Calcular distancia total
      final distance = _pathEdges.fold<double>(
        0.0,
        (sum, edge) => sum + edge.weight,
      );

      if (mounted) {
        setState(() {
          _loading = false;
        });

        // Mostrar información de la ruta
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ruta encontrada: ${_pathEdges.length} segmentos (${distance.toStringAsFixed(1)} unidades)',
            ),
            duration: const Duration(seconds: 3),
            backgroundColor: const Color(0xFF1B38E3),
          ),
        );
      }
    } catch (e) {
      print('❌ Error al cargar mapa y calcular ruta: $e');
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
    setState(() {
      _scale = 1.0;
    });
  }

  void _zoomIn(BuildContext context) {
    final currentMatrix = _transformationController.value;
    final currentScale = currentMatrix.getMaxScaleOnAxis();
    final newScale = (currentScale * 1.2).clamp(0.5, 8.0); // Zoom más suave (1.2x en lugar de 1.5x)
    
    // Obtener el tamaño de la pantalla y el punto focal (centro)
    final screenSize = MediaQuery.of(context).size;
    final focalPoint = Offset(screenSize.width / 2, screenSize.height / 2);
    
    // Calcular el zoom desde el centro de la pantalla
    final scaleFactor = newScale / currentScale;
    
    // Crear nueva matriz: trasladar al punto focal, escalar, trasladar de vuelta
    final newMatrix = Matrix4.identity()
      ..translate(focalPoint.dx, focalPoint.dy)
      ..scale(scaleFactor)
      ..translate(-focalPoint.dx, -focalPoint.dy)
      ..multiplied(currentMatrix);
    
    _transformationController.value = newMatrix;
    setState(() {
      _scale = newScale;
    });
  }

  void _zoomOut(BuildContext context) {
    final currentMatrix = _transformationController.value;
    final currentScale = currentMatrix.getMaxScaleOnAxis();
    final newScale = (currentScale / 1.2).clamp(0.5, 8.0); // Zoom más suave (1.2x en lugar de 1.5x)
    
    // Obtener el tamaño de la pantalla y el punto focal (centro)
    final screenSize = MediaQuery.of(context).size;
    final focalPoint = Offset(screenSize.width / 2, screenSize.height / 2);
    
    // Calcular el zoom desde el centro de la pantalla
    final scaleFactor = newScale / currentScale;
    
    // Crear nueva matriz: trasladar al punto focal, escalar, trasladar de vuelta
    final newMatrix = Matrix4.identity()
      ..translate(focalPoint.dx, focalPoint.dy)
      ..scale(scaleFactor)
      ..translate(-focalPoint.dx, -focalPoint.dy)
      ..multiplied(currentMatrix);
    
    _transformationController.value = newMatrix;
    setState(() {
      _scale = newScale;
    });
  }


  /// Oculta los nodos azules del SVG procesando el string
  /// Los nodos siguen existiendo en el SVG pero no son visibles
  /// Esto permite que el sistema de navegación funcione sin mostrar los nodos al usuario
  /// OPTIMIZACIÓN: Cachea el resultado para evitar reprocesar
  String _hideNodesInSvg(String svgString, String svgPath) {
    // Si ya tenemos el SVG procesado en cache para esta ruta, retornarlo
    if (_cachedProcessedSvg != null && _cachedSvgPath == svgPath) {
      return _cachedProcessedSvg!;
    }
    
    // Patrón para encontrar círculos con id que empieza con "node" y fill="#0066FF"
    // Ejemplo: <circle id="node37" cx="1063" cy="697" r="10" fill="#0066FF"/>
    final nodePattern = RegExp(
      r'(<circle\s+id="node[^"]*"[^>]*fill=")#0066FF(")',
      multiLine: true,
    );
    
    // Reemplazar fill="#0066FF" por fill="none" para ocultar los nodos
    String modifiedSvg = svgString.replaceAllMapped(
      nodePattern,
      (match) => '${match.group(1)}none${match.group(2)}',
    );
    
    // También buscar y ocultar nodos que puedan tener el fill en diferentes posiciones
    // Patrón más flexible que busca cualquier círculo con id="node..." y fill="#0066FF"
    final nodePatternFlexible = RegExp(
      r'(<circle\s+id="node[^"]*"[^>]*?)(fill="#0066FF")([^>]*>)',
      multiLine: true,
    );
    
    modifiedSvg = modifiedSvg.replaceAllMapped(
      nodePatternFlexible,
      (match) {
        // Reemplazar fill="#0066FF" por fill="none" y agregar opacity="0"
        final before = match.group(1)!;
        final after = match.group(3)!;
        return '$before fill="none" opacity="0"$after';
      },
    );
    
    // Guardar en cache
    _cachedProcessedSvg = modifiedSvg;
    _cachedSvgPath = svgPath;
    
    return modifiedSvg;
  }

  String _getSvgPath() {
    // Usar el piso que realmente se cargó (puede ser diferente al solicitado)
    switch (_pisoCargado) {
      case 1:
        return 'assets/mapas/map_ext.svg';
      case 2:
        return 'assets/mapas/map_int_piso2 (1).svg';
      default:
        // Fallback al piso 2
        return 'assets/mapas/map_int_piso2 (1).svg';
    }
  }

  /// Transforma coordenadas del SVG a coordenadas de pantalla
  /// Similar al método en MapOverlayPainter pero para uso en widgets
  Offset _transformSvgToScreen(double svgX, double svgY, Size screenSize) {
    const double svgWidth = 2117.0;
    const double svgHeight = 1729.0;
    
    // Calcular escala para mantener aspect ratio (BoxFit.contain)
    final scaleX = screenSize.width / svgWidth;
    final scaleY = screenSize.height / svgHeight;
    final scale = scaleX < scaleY ? scaleX : scaleY;
    
    // Calcular offset para centrar
    final scaledWidth = svgWidth * scale;
    final scaledHeight = svgHeight * scale;
    final offsetX = (screenSize.width - scaledWidth) / 2;
    final offsetY = (screenSize.height - scaledHeight) / 2;
    
    // Transformar coordenadas
    return Offset(
      offsetX + svgX * scale,
      offsetY + svgY * scale,
    );
  }
  
  /// Calcula las coordenadas del punto de partida (entranceNode) transformadas
  /// ⚠️ COORDENADAS DEL PUNTO DE PARTIDA - NO SERÁN PERMANENTES
  /// Estas coordenadas se calculan desde el entranceNode y se transforman
  /// según la transformación actual del InteractiveViewer
  /// Usa exactamente la misma transformación que el overlay para garantizar alineación perfecta
  Offset? _getStartPointCoordinates(Size screenSize) {
    if (_entranceNode == null) return null;
    
    // Transformar coordenadas SVG a coordenadas de pantalla base
    // Usar exactamente el mismo método que MapOverlayPainter._transformPoint
    final basePoint = _transformSvgToScreen(
      _entranceNode!.x,
      _entranceNode!.y,
      screenSize,
    );
    
    // Aplicar transformación del InteractiveViewer (zoom y pan)
    // Transformar el punto usando la matriz de transformación 2D
    // Para transformaciones 2D: [x', y'] = [x, y, 1] * matriz
    final matrix = _transformationController.value;
    final x = basePoint.dx;
    final y = basePoint.dy;
    
    // Multiplicar punto por matriz: punto * matriz = [x, y, 1] * matriz
    // Para una transformación 2D, usamos solo los componentes x, y y w (traslación)
    final transformedX = matrix.getRow(0).x * x + 
                        matrix.getRow(0).y * y + 
                        matrix.getRow(0).w; // w contiene la traslación X
    final transformedY = matrix.getRow(1).x * x + 
                        matrix.getRow(1).y * y + 
                        matrix.getRow(1).w; // w contiene la traslación Y
    
    return Offset(transformedX, transformedY);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.salonNombre ?? 'Navegación al Salón',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1B38E3),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_scale > 1.1)
            IconButton(
              icon: const Icon(Icons.center_focus_strong),
              onPressed: _resetZoom,
              tooltip: 'Resetear zoom',
            ),
        ],
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
                            const Icon(Icons.error_outline, color: Colors.red, size: 64),
                            const SizedBox(height: 24),
                            const Text(
                              'Error al cargar el mapa',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
                            TextButton(
                              onPressed: _loadMapAndCalculateRoute,
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      ),
                    )
              : Stack(
                  children: [
                    // Mapa SVG con zoom y pan
                    InteractiveViewer(
                      transformationController: _transformationController,
                      minScale: 0.5,
                      maxScale: 8.0, // Aumentado para permitir más zoom
                      panEnabled: true,
                      scaleEnabled: true,
                      boundaryMargin: const EdgeInsets.all(double.infinity), // Permitir pan ilimitado
                      child: SizedBox(
                        width: double.infinity,
                        height: double.infinity,
                        child: FutureBuilder<String>(
                          future: rootBundle.loadString(_getSvgPath()),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            if (snapshot.hasError) {
                              return Center(
                                child: Text('Error: ${snapshot.error}'),
                              );
                            }
                            if (snapshot.hasData) {
                              // Ocultar los nodos azules procesando el SVG
                              // OPTIMIZACIÓN: Cachea el resultado para evitar reprocesar
                              final svgPath = _getSvgPath();
                              final svgWithoutNodes = _hideNodesInSvg(snapshot.data!, svgPath);
                              return SvgPicture.string(
                                svgWithoutNodes,
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
                    
                    // Overlay con la ruta (se transforma con el mismo controller, pero ignora gestos)
                    if (_pathEdges.isNotEmpty)
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
                                  painter: MapOverlayPainter(
                                    pathEdges: _pathEdges, // Pasar edges con shapes
                                    entranceNode: _entranceNode, // Punto inicial en azul
                                    destinationNode: _destinationNode,
                                    currentUserNode: _currentUserNode, // Preparado para futuro
                                    routeColor: const Color(0xFF1B38E3),
                                    routeStrokeWidth: 2.5, // Línea más delgada
                                    nodeRadius: 6.0,
                                    destinationColor: const Color(0xFF87CEEB), // Celeste claro (Sky Blue)
                                    userNodeColor: Colors.red,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                    // --- MARCADOR DEL USUARIO (ESTILO GOOGLE MAPS) ---
                    if (_entranceNode != null && _sensorService != null)
                      AnimatedBuilder(
                        animation: _transformationController,
                        builder: (context, child) {
                          return LayoutBuilder(
                            builder: (context, constraints) {
                              return UserLocationWidget(
                                entranceNode: _entranceNode,
                                sensorService: _sensorService!,
                                transformationController: _transformationController,
                                screenSize: constraints.biggest,
                              );
                            },
                          );
                        },
                      ),

                    // Componente separado para el pop-up de la foto (fuera del Stack del mapa)
                    if (_showPhoto)
                      Positioned.fill(
                        child: SalonPhotoPopup(
                          imagePath: _getSalonImagePath(),
                          onClose: _hideSalonPhoto,
                          animationController: _photoAnimationController,
                        ),
                      ),

                    // Controles de zoom flotantes (deben estar DESPUÉS del pop-up para quedar por encima)
                    Positioned(
                      right: 16,
                      bottom: _showPhoto ? 400 : 220, // Ajustar posición cuando la imagen está visible
                      child: Builder(
                        builder: (context) => Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Botón de cámara (aparece siempre en cada mapa de clases)
                            Material(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(28),
                              elevation: 4,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(28),
                                onTap: () {
                                  print('📸 Botón cámara presionado');
                                  if (_showPhoto) {
                                    _hideSalonPhoto();
                                  } else {
                                    // Si hay imagen, mostrarla; si no, mostrar mensaje
                                    if (_hasSalonImage()) {
                                      _showSalonPhoto();
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('No hay foto disponible para ${widget.salonNombre ?? widget.objetivoSalonId}'),
                                          duration: const Duration(seconds: 2),
                                          backgroundColor: Colors.orange,
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(28),
                                    border: Border.all(
                                      color: const Color(0xFF1B38E3).withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(28),
                                    child: Image.asset(
                                      'assets/logoappsenati.png', // Cambia esta ruta por la imagen que quieras usar
                                      width: 56,
                                      height: 56,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        // Si la imagen no existe, mostrar el ícono como fallback
                                        return const Icon(
                                          Icons.photo_camera,
                                          color: Color(0xFF1B38E3),
                                          size: 28,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Botón zoom in
                            Material(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(28),
                              elevation: 4,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(28),
                                onTap: () => _zoomIn(context),
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(28),
                                  border: Border.all(
                                    color: const Color(0xFF1B38E3).withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.add,
                                  color: Color(0xFF1B38E3),
                                  size: 28,
                                ),
                              ),
                            ),
                          ),
                            const SizedBox(height: 12),
                            // Botón zoom out
                            Material(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(28),
                              elevation: 4,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(28),
                                onTap: () => _zoomOut(context),
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(28),
                                  border: Border.all(
                                    color: const Color(0xFF1B38E3).withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.remove,
                                  color: Color(0xFF1B38E3),
                                  size: 28,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Botón reset zoom
                          Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            elevation: 4,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(28),
                              onTap: _resetZoom,
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(28),
                                  border: Border.all(
                                    color: const Color(0xFF1B38E3).withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.refresh,
                                  color: Color(0xFF1B38E3),
                                  size: 24,
                                ),
                              ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Información de la ruta
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  color: Color(0xFF1B38E3),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    widget.salonNombre ?? widget.objetivoSalonId,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Ruta: ${_pathEdges.length} segmentos',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            if (_destinationNode != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Destino: ${_destinationNode!.id}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

