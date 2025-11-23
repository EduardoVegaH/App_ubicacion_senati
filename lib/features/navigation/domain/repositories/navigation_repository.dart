import '../entities/map_floor.dart';
import '../entities/map_node.dart';
import '../entities/map_edge.dart';

/// Interfaz del repositorio de navegación
/// 
/// Define los contratos para acceder a los datos de navegación
/// sin depender de implementaciones concretas (Firestore, etc.)
abstract class NavigationRepository {
  /// Guarda el grafo completo de un piso (nodos + edges) en persistencia
  Future<void> saveFloorGraph(MapFloor floor);

  /// Obtiene el grafo completo de un piso
  Future<MapFloor> getFloorGraph(int floor);

  /// Obtiene todos los nodos de un piso específico
  Future<List<MapNode>> getNodesForFloor(int floor);

  /// Obtiene todos los edges de un piso específico
  Future<List<MapEdge>> getEdgesForFloor(int floor);
}

