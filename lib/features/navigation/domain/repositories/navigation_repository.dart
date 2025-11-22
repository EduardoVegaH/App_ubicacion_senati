import '../entities/map_node_entity.dart';
import '../entities/edge_entity.dart';

/// Interfaz del repositorio de navegación
abstract class NavigationRepository {
  Future<Map<String, dynamic>> loadGraph(int piso);
  Future<List<EdgeEntity>> findPath({
    required int piso,
    required String startNodeId,
    required String endNodeId,
  });
  Future<MapNodeEntity?> findEntranceNode(int piso);
  Future<MapNodeEntity?> findNearestElevatorNode(int piso);
  Future<MapNodeEntity?> findNodeBySalon({
    required int piso,
    required String salonId,
  });
}

