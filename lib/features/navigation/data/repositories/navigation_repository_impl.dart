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
}

