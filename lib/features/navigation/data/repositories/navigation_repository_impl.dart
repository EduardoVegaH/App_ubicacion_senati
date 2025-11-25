import '../../domain/entities/map_floor.dart';
import '../../domain/entities/map_node.dart';
import '../../domain/entities/map_edge.dart';
import '../../domain/repositories/navigation_repository.dart';
import '../data_sources/svg_map_data_source.dart';
import '../data_sources/firestore_navigation_data_source.dart';

/// Implementación del repositorio de navegación
class NavigationRepositoryImpl implements NavigationRepository {
  final SvgMapDataSource svgDataSource;
  final FirestoreNavigationDataSource firestoreDataSource;

  NavigationRepositoryImpl({
    required this.svgDataSource,
    required this.firestoreDataSource,
  });

  @override
  Future<void> saveFloorGraph(MapFloor floor) {
    return firestoreDataSource.saveFloorGraph(floor);
  }

  @override
  Future<MapFloor> getFloorGraph(int floor) {
    return firestoreDataSource.getFloorGraph(floor);
  }

  @override
  Future<List<MapNode>> getNodesForFloor(int floor) {
    return firestoreDataSource.getNodesForFloor(floor);
  }

  @override
  Future<List<MapEdge>> getEdgesForFloor(int floor) {
    return firestoreDataSource.getEdgesForFloor(floor);
  }
  
  /// Guarda el grafo reemplazando los existentes
  Future<void> saveFloorGraphReplacing(MapFloor floor) async {
    return await firestoreDataSource.saveFloorGraph(floor, replaceExisting: true);
  }

  /// Elimina todos los edges de un piso
  Future<void> deleteAllEdgesForFloor(int floor) async {
    return await firestoreDataSource.deleteAllEdgesForFloor(floor);
  }

  /// Guarda solo los edges de un piso (sin tocar los nodos)
  Future<void> saveEdgesForFloor(
    int floor,
    List<MapEdge> edges, {
    bool deleteExisting = true,
  }) async {
    return await firestoreDataSource.saveEdgesForFloor(
      floor,
      edges,
      deleteExisting: deleteExisting,
    );
  }
}

