import '../entities/map_node.dart';
import '../entities/map_edge.dart';

/// Implementación del algoritmo A* para encontrar el camino más corto
/// 
/// Algoritmo puro sin dependencias externas, implementado en la capa domain
class AStarAlgorithm {
  /// Encuentra el camino más corto desde un nodo de inicio hasta un nodo objetivo
  /// 
  /// [nodes] Lista de todos los nodos del grafo
  /// [edges] Lista de todos los edges del grafo
  /// [startId] ID del nodo de inicio
  /// [goalId] ID del nodo objetivo
  /// 
  /// Retorna una lista de MapNode que representa el camino encontrado
  /// Retorna lista vacía si no se encuentra camino
  static List<MapNode> findPath({
    required List<MapNode> nodes,
    required List<MapEdge> edges,
    required String startId,
    required String goalId,
  }) {
    // Crear mapas para acceso rápido
    final nodeMap = {for (var node in nodes) node.id: node};
    final adjacencyList = _buildAdjacencyList(edges);

    // Verificar que los nodos existan
    if (!nodeMap.containsKey(startId) || !nodeMap.containsKey(goalId)) {
      return [];
    }

    final startNode = nodeMap[startId]!;
    final goalNode = nodeMap[goalId]!;

    // Estructuras para A*
    final openSet = <String>{startId};
    final cameFrom = <String, String>{};
    final gScore = <String, double>{startId: 0.0};
    final fScore = <String, double>{startId: _heuristic(startNode, goalNode)};

    while (openSet.isNotEmpty) {
      // Encontrar el nodo con menor fScore
      String? currentId;
      double minFScore = double.infinity;
      for (final id in openSet) {
        final f = fScore[id] ?? double.infinity;
        if (f < minFScore) {
          minFScore = f;
          currentId = id;
        }
      }

      if (currentId == null) break;

      // Si llegamos al objetivo, reconstruir el camino
      if (currentId == goalId) {
        return _reconstructPath(cameFrom, currentId, nodeMap);
      }

      openSet.remove(currentId);

      // Explorar vecinos
      final neighbors = adjacencyList[currentId] ?? [];
      for (final edge in neighbors) {
        final neighborId = edge.toId == currentId ? edge.fromId : edge.toId;
        if (neighborId == currentId) continue;

        final neighborNode = nodeMap[neighborId];
        if (neighborNode == null) continue;

        final tentativeGScore = (gScore[currentId] ?? double.infinity) + edge.weight;

        if (tentativeGScore < (gScore[neighborId] ?? double.infinity)) {
          cameFrom[neighborId] = currentId;
          gScore[neighborId] = tentativeGScore;
          fScore[neighborId] = tentativeGScore + _heuristic(neighborNode, goalNode);

          if (!openSet.contains(neighborId)) {
            openSet.add(neighborId);
          }
        }
      }
    }

    // No se encontró camino
    return [];
  }

  /// Construye una lista de adyacencia a partir de los edges
  static Map<String, List<MapEdge>> _buildAdjacencyList(List<MapEdge> edges) {
    final adjacencyList = <String, List<MapEdge>>{};

    for (final edge in edges) {
      adjacencyList.putIfAbsent(edge.fromId, () => []).add(edge);
      adjacencyList.putIfAbsent(edge.toId, () => []).add(edge);
    }

    return adjacencyList;
  }

  /// Calcula la heurística (distancia euclidiana) entre dos nodos
  static double _heuristic(MapNode a, MapNode b) {
    final dx = a.x - b.x;
    final dy = a.y - b.y;
    return (dx * dx + dy * dy);
  }

  /// Reconstruye el camino desde el objetivo hasta el inicio
  static List<MapNode> _reconstructPath(
    Map<String, String> cameFrom,
    String currentId,
    Map<String, MapNode> nodeMap,
  ) {
    final path = <MapNode>[];
    String? current = currentId;

    while (current != null) {
      final node = nodeMap[current];
      if (node != null) {
        path.insert(0, node);
      }
      current = cameFrom[current];
    }

    return path;
  }
}

