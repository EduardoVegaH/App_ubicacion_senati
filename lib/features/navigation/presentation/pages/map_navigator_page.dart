import 'package:flutter/material.dart';
import '../../../../../app/styles/app_styles.dart';
import '../../../../../app/styles/app_shadows.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../data/index.dart';
import '../../data/use_cases/calculate_route_with_models_use_case.dart';
import '../../domain/index.dart';
import '../widgets/map_overlay_painter.dart';
import '../widgets/salon_photo_popup.dart';
// Usar config migrado
import '../../data/config/graph_edges_config.dart';

/// Pantalla de navegación que muestra el mapa SVG con la ruta trazada
class MapNavigatorPage extends StatefulWidget {
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
  State<MapNavigatorPage> createState() => _MapNavigatorPageState();
}

class _MapNavigatorPageState extends State<MapNavigatorPage> with TickerProviderStateMixin {
  late final NavigationRemoteDataSource _dataSource;
  late final NavigationRepositoryImpl _repository;
  late final CalculateRouteWithModelsUseCase _calculateRouteWithModelsUseCase;
  late final FindNodeBySalonUseCase _findNodeBySalonUseCase;
  
  final TransformationController _transformationController = TransformationController();
  
  List<EdgeModel> _pathEdges = [];
  MapNodeModel? _destinationNode;
  MapNodeModel? _entranceNode;
  List<MapNodeModel> _allNodes = [];
  bool _loading = true;
  String? _errorMessage;
  double _scale = 1.0;
  int _pisoCargado = 1;
  
  MapNodeModel? _currentUserNode;
  bool _showPhoto = false;
  late AnimationController _photoAnimationController;

  @override
  void initState() {
    super.initState();
    _dataSource = NavigationRemoteDataSource();
    _repository = NavigationRepositoryImpl(_dataSource);
    _calculateRouteWithModelsUseCase = CalculateRouteWithModelsUseCase(_repository);
    _findNodeBySalonUseCase = FindNodeBySalonUseCase(_repository);
    
    _transformationController.addListener(_onTransformChanged);
    
    _photoAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _loadMapAndCalculateRoute();
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onTransformChanged);
    _transformationController.dispose();
    _photoAnimationController.dispose();
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

  void _showSalonPhoto() {
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

  String _getSalonImagePath() {
    String salonId = widget.objetivoSalonId.toLowerCase().trim();
    
    if (salonId.startsWith('salon-')) {
      salonId = salonId.substring(6);
    }
    
    final imagePath = 'assets/fotosalon/foto-salon-$salonId.png';
    
    print('🖼️ Ruta de imagen calculada: $imagePath para salón: ${widget.objetivoSalonId}');
    
    return imagePath;
  }

  bool _hasSalonImage() {
    String salonId = widget.objetivoSalonId.toLowerCase().trim();
    if (salonId.startsWith('salon-')) {
      salonId = salonId.substring(6);
    }
    
    final salonesConFoto = ['b-200'];
    
    return salonesConFoto.contains(salonId);
  }

  Future<void> _loadMapAndCalculateRoute() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      int pisoACargar = widget.piso;
      if (pisoACargar != 1 && pisoACargar != 2) {
        print('⚠️ Piso ${widget.piso} no existe, usando piso 2 como fallback');
        pisoACargar = 2;
      }
      _pisoCargado = pisoACargar;
      
      final graph = await _dataSource.loadGraph(pisoACargar);
      _allNodes = graph['nodes'] as List<MapNodeModel>;
      
      if (_allNodes.isEmpty) {
        throw Exception(
          'No se encontraron nodos para el piso $pisoACargar.\n\n'
          'Por favor, contacta al administrador para inicializar el grafo.',
        );
      }

      print('🔍 Buscando nodo más cercano a los ascensores...');
      final entranceEntity = await _repository.findNearestElevatorNode(pisoACargar);
      if (entranceEntity != null) {
        _entranceNode = MapNodeModel(
          id: entranceEntity.id,
          x: entranceEntity.x,
          y: entranceEntity.y,
          piso: entranceEntity.piso,
          tipo: entranceEntity.tipo,
          salonId: entranceEntity.salonId,
        );
      } else {
        print('⚠️ No se encontró nodo cercano a ascensores, usando entrada principal');
        final entranceEntity2 = await _repository.findEntranceNode(pisoACargar);
        if (entranceEntity2 != null) {
          _entranceNode = MapNodeModel(
            id: entranceEntity2.id,
            x: entranceEntity2.x,
            y: entranceEntity2.y,
            piso: entranceEntity2.piso,
            tipo: entranceEntity2.tipo,
            salonId: entranceEntity2.salonId,
          );
        } else {
          _entranceNode = _allNodes.first;
        }
      }
      print('✅ Nodo de inicio seleccionado: ${_entranceNode!.id}');

      print('🔍 Buscando nodo para salón: ${widget.objetivoSalonId} en piso $pisoACargar');
      final destinationEntity = await _findNodeBySalonUseCase.call(
        piso: pisoACargar,
        salonId: widget.objetivoSalonId,
      );
      
      if (destinationEntity != null) {
        // Convertir entidad a modelo para usar en UI
        _destinationNode = MapNodeModel(
          id: destinationEntity.id,
          x: destinationEntity.x,
          y: destinationEntity.y,
          piso: destinationEntity.piso,
          tipo: destinationEntity.tipo,
          salonId: destinationEntity.salonId,
        );
        print('✅ Nodo destino encontrado: ${_destinationNode!.id}');
      } else {
        // Búsqueda flexible
        final salonNumber = widget.objetivoSalonId.replaceAll(RegExp(r'[^0-9]'), '');
        print('🔍 Número del salón extraído: $salonNumber');
        
        if (salonNumber.isNotEmpty) {
          try {
            final found = _allNodes.firstWhere(
              (node) => node.id.contains(salonNumber) ||
                        (node.salonId != null && node.salonId!.contains(salonNumber)),
            );
            _destinationNode = found;
            print('✅ Nodo encontrado por búsqueda flexible: ${_destinationNode!.id}');
          } catch (e) {
            print('⚠️ No se encontró nodo con búsqueda flexible: $e');
            if (_allNodes.isNotEmpty) {
              double sumX = 0, sumY = 0;
              for (final node in _allNodes) {
                sumX += node.x;
                sumY += node.y;
              }
              final centerX = sumX / _allNodes.length;
              final centerY = sumY / _allNodes.length;
              
              MapNodeModel? nearest;
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
        
        if (_destinationNode == null) {
          throw Exception(
            'No se encontró nodo para el salón ${widget.objetivoSalonId}.\n\n'
            'El salón puede no estar mapeado en el grafo.\n'
            'Intenta inicializar el grafo nuevamente o verifica que el salón existe.',
          );
        }
      }

      print('🗺️ Calculando ruta desde ${_entranceNode!.id} hasta ${_destinationNode!.id}');
      final edges = graph['edges'] as List<EdgeModel>;
      print('📊 Total de edges disponibles: ${edges.length}');
      
      if (_pisoCargado == 2) {
        print('🔍 Verificando que solo se usen edges manuales para piso 2...');
        // Verificar edges manuales usando config migrado
        final manualEdges = await GraphEdgesConfig.getManualEdgesForFloor(2, _allNodes);
        final manualEdgeIds = manualEdges.map((e) => '${e.fromId}_${e.toId}').toSet();
        final currentEdgeIds = edges.map((e) => '${e.fromId}_${e.toId}').toSet();
        
        if (manualEdgeIds != currentEdgeIds) {
          print('⚠️ ADVERTENCIA: Los edges cargados no coinciden exactamente con los manuales');
        } else {
          print('✅ Confirmado: Solo se están usando edges manuales (${edges.length} edges)');
        }
      }
      
      final startEdges = edges.where((e) => e.fromId == _entranceNode!.id).toList();
      final endEdges = edges.where((e) => e.toId == _destinationNode!.id || e.fromId == _destinationNode!.id).toList();
      print('🔗 Edges desde entrada (${_entranceNode!.id}): ${startEdges.map((e) => e.toId).join(", ")}');
      print('🔗 Edges hacia/hasta destino (${_destinationNode!.id}): ${endEdges.length}');
      
      // Delegar cálculo de ruta y conversión al use case
      _pathEdges = await _calculateRouteWithModelsUseCase.call(
        piso: pisoACargar,
        startNodeId: _entranceNode!.id,
        endNodeId: _destinationNode!.id,
      );

      if (_pathEdges.isEmpty) {
        print('❌ No se encontró ruta. Entrada: ${_entranceNode!.id}, Destino: ${_destinationNode!.id}');
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
      
      final pathNodeIds = <String>[];
      if (_pathEdges.isNotEmpty) {
        pathNodeIds.add(_pathEdges.first.fromId);
        for (final edge in _pathEdges) {
          pathNodeIds.add(edge.toId);
        }
      }
      
      print('📊 Ruta completa (${_pathEdges.length} edges): ${pathNodeIds.join(" -> ")}');
      
      final distance = _pathEdges.fold<double>(
        0.0,
        (sum, edge) => sum + edge.weight,
      );

      if (mounted) {
        setState(() {
          _loading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ruta encontrada: ${_pathEdges.length} segmentos (${distance.toStringAsFixed(1)} unidades)',
            ),
            duration: const Duration(seconds: 3),
            backgroundColor: AppStyles.primaryColor,
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
    final newScale = (currentScale * 1.2).clamp(0.5, 8.0);
    
    final screenSize = MediaQuery.of(context).size;
    final focalPoint = Offset(screenSize.width / 2, screenSize.height / 2);
    
    final scaleFactor = newScale / currentScale;
    
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
    final newScale = (currentScale / 1.2).clamp(0.5, 8.0);
    
    final screenSize = MediaQuery.of(context).size;
    final focalPoint = Offset(screenSize.width / 2, screenSize.height / 2);
    
    final scaleFactor = newScale / currentScale;
    
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

  String _hideNodesInSvg(String svgString) {
    final nodePattern = RegExp(
      r'(<circle\s+id="node[^"]*"[^>]*fill=")#0066FF(")',
      multiLine: true,
    );
    
    String modifiedSvg = svgString.replaceAllMapped(
      nodePattern,
      (match) => '${match.group(1)}none${match.group(2)}',
    );
    
    final nodePatternFlexible = RegExp(
      r'(<circle\s+id="node[^"]*"[^>]*?)(fill="#0066FF")([^>]*>)',
      multiLine: true,
    );
    
    modifiedSvg = modifiedSvg.replaceAllMapped(
      nodePatternFlexible,
      (match) {
        final before = match.group(1)!;
        final after = match.group(3)!;
        return '$before fill="none" opacity="0"$after';
      },
    );
    
    return modifiedSvg;
  }

  String _getSvgPath() {
    switch (_pisoCargado) {
      case 1:
        return 'assets/mapas/map_ext.svg';
      case 2:
        return 'assets/mapas/map_int_piso2 (1).svg';
      default:
        return 'assets/mapas/map_int_piso2 (1).svg';
    }
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
                            Icon(Icons.error_outline, color: AppStyles.errorColor, size: 64),
                            const SizedBox(height: 24),
                            const Text(
                              'Error al cargar el mapa',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppStyles.errorColor,
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
                      maxScale: 8.0,
                      panEnabled: true,
                      scaleEnabled: true,
                      boundaryMargin: const EdgeInsets.all(double.infinity),
                      child: SizedBox(
                        width: double.infinity,
                        height: double.infinity,
                        child: FutureBuilder<String>(
                          future: rootBundle.loadString(_getSvgPath()),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
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
                              final svgWithoutNodes = _hideNodesInSvg(snapshot.data!);
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
                    
                    // Overlay con la ruta
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
                                    pathEdges: _pathEdges,
                                    entranceNode: _entranceNode,
                                    destinationNode: _destinationNode,
                                    currentUserNode: _currentUserNode,
                                    routeColor: AppStyles.primaryColor,
                                    routeStrokeWidth: 2.5,
                                    nodeRadius: 6.0,
                                    destinationColor: AppStyles.secondaryColor,
                                    userNodeColor: AppStyles.redStatus,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                    // Pop-up de foto
                    if (_showPhoto)
                      Positioned.fill(
                        child: SalonPhotoPopup(
                          imagePath: _getSalonImagePath(),
                          onClose: _hideSalonPhoto,
                          animationController: _photoAnimationController,
                        ),
                      ),

                    // Controles de zoom flotantes
                    Positioned(
                      right: 16,
                      bottom: _showPhoto ? 400 : 220,
                      child: Builder(
                        builder: (context) => Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Botón de cámara
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
                                    if (_hasSalonImage()) {
                                      _showSalonPhoto();
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('No hay foto disponible para ${widget.salonNombre ?? widget.objetivoSalonId}'),
                                          duration: const Duration(seconds: 2),
                                          backgroundColor: AppStyles.warningColor,
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
                                      color: AppStyles.primaryColor.withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(28),
                                    child: Image.asset(
                                      'assets/logoappsenati.png',
                                      width: 56,
                                      height: 56,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Icon(
                                          Icons.photo_camera,
                                          color: AppStyles.primaryColor,
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
                                      color: AppStyles.primaryColor.withOpacity(0.2),
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
                                      color: AppStyles.primaryColor.withOpacity(0.2),
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
                                      color: AppStyles.primaryColor.withOpacity(0.2),
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
                          boxShadow: AppShadows.cardShadow,
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
