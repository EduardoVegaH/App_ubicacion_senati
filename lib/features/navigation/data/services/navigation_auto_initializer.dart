import '../../domain/repositories/navigation_repository.dart';
import '../data_sources/svg_map_data_source.dart';
import '../repositories/navigation_repository_impl.dart';
import 'graph_initializer.dart';

/// Servicio para inicializar automáticamente los nodos y edges de navegación
/// 
/// Verifica si los datos existen en Firestore y los inicializa si es necesario
class NavigationAutoInitializer {
  final NavigationRepository repository;
  final SvgMapDataSource svgDataSource;
  final GraphInitializer graphInitializer;

  NavigationAutoInitializer({
    required this.repository,
    required this.svgDataSource,
    required this.graphInitializer,
  });

  /// Inicializa automáticamente los nodos y edges para todos los pisos
  /// 
  /// Verifica si los datos existen antes de inicializar
  Future<void> initializeIfNeeded() async {
    final floors = [1, 2];
    
    for (final floor in floors) {
      try {
        final existingNodes = await repository.getNodesForFloor(floor);
        final existingEdges = await repository.getEdgesForFloor(floor);
        
        if (existingNodes.isEmpty) {
          await _initializeFloorFromSvg(floor);
          await _initializeEdgesForFloor(floor);
        } else if (existingEdges.isEmpty) {
          await _initializeEdgesForFloor(floor);
        }
      } catch (e) {
        // Continuar con el siguiente piso aunque uno falle
      }
    }
  }

  /// Inicializa los nodos de un piso desde el SVG
  Future<void> _initializeFloorFromSvg(int floor) async {
    final svgAssetPath = floor == 1
        ? 'assets/mapas/MAP_PISO_1.svg'
        : 'assets/mapas/MAP_PISO_2.svg';
    
    final mapFloor = await svgDataSource.buildFloorFromSvg(
      floor: floor,
      assetPath: svgAssetPath,
    );
    
    if (repository is NavigationRepositoryImpl) {
      await (repository as NavigationRepositoryImpl).saveFloorGraphReplacing(mapFloor);
    } else {
      await repository.saveFloorGraph(mapFloor);
    }
  }

  /// Inicializa los edges de un piso
  Future<void> _initializeEdgesForFloor(int floor) async {
    await graphInitializer.initializeEdgesForFloor(floor);
  }

  /// Inicializa solo los nodos (sin edges) para un piso específico
  Future<void> initializeNodesForFloor(int floor) async {
    await _initializeFloorFromSvg(floor);
  }

  /// Inicializa solo los edges para un piso específico
  Future<void> initializeEdgesForFloor(int floor) async {
    await _initializeEdgesForFloor(floor);
  }
}

