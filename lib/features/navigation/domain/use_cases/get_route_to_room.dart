import '../entities/map_node.dart';
import '../repositories/navigation_repository.dart';
import 'a_star_algorithm.dart';

/// Excepción lanzada cuando no se encuentra una ruta
class RouteNotFoundException implements Exception {
  final String message;
  RouteNotFoundException(this.message);

  @override
  String toString() => 'RouteNotFoundException: $message';
}

/// Caso de uso para obtener la ruta entre dos nodos usando el algoritmo A*
/// 
/// Implementa el algoritmo A* en la capa domain sin dependencias externas
class GetRouteToRoomUseCase {
  final NavigationRepository repository;

  GetRouteToRoomUseCase(this.repository);

  /// Calcula la ruta desde un nodo origen hasta un nodo destino
  /// 
  /// [floor] El piso donde se busca la ruta
  /// [fromNodeId] ID del nodo de origen
  /// [toNodeId] ID del nodo de destino
  /// 
  /// Retorna una lista de MapNode que representa el camino encontrado
  /// Lanza [RouteNotFoundException] si no se encuentra una ruta
  Future<List<MapNode>> call({
    required int floor,
    required String fromNodeId,
    required String toNodeId,
  }) async {
    // Cargar el grafo del piso
    final mapFloor = await repository.getFloorGraph(floor);

    // Validar que existan los nodos
    final fromNode = mapFloor.nodes.firstWhere(
      (node) => node.id == fromNodeId,
      orElse: () => throw RouteNotFoundException(
        'Nodo origen no encontrado: $fromNodeId',
      ),
    );

    mapFloor.nodes.firstWhere(
      (node) => node.id == toNodeId,
      orElse: () => throw RouteNotFoundException(
        'Nodo destino no encontrado: $toNodeId',
      ),
    );

    // Si el origen y destino son el mismo, retornar solo ese nodo
    if (fromNodeId == toNodeId) {
      return [fromNode];
    }

    // Ejecutar algoritmo A*
    final path = AStarAlgorithm.findPath(
      nodes: mapFloor.nodes,
      edges: mapFloor.edges,
      startId: fromNodeId,
      goalId: toNodeId,
    );

    if (path.isEmpty) {
      throw RouteNotFoundException(
        'No se encontró una ruta desde $fromNodeId hasta $toNodeId en el piso $floor',
      );
    }

    return path;
  }
}

