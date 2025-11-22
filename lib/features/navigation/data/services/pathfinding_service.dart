import 'dart:math' as math;
import '../models/map_node_model.dart';
import '../models/edge_model.dart';

/// Implementación del algoritmo A* para encontrar el camino más corto
class PathfindingService {
  /// Encuentra el camino más corto entre dos nodos usando A*
  /// 
  /// [startNodeId] - ID del nodo de inicio
  /// [endNodeId] - ID del nodo destino
  /// [nodes] - Lista de todos los nodos del grafo
  /// [edges] - Lista de todas las conexiones (edges) del grafo
  /// 
  /// Retorna una lista de EdgeModels que representan el camino (con sus shapes)
  /// Si no hay camino, retorna una lista vacía
  static List<EdgeModel> findPathAStar({
    required String startNodeId,
    required String endNodeId,
    required List<MapNodeModel> nodes,
    required List<EdgeModel> edges,
  }) {
    // Crear mapas para acceso rápido
    final nodeMap = {for (var node in nodes) node.id: node};
    final adjacencyList = <String, List<EdgeModel>>{};
    
    // Construir lista de adyacencia
    for (final edge in edges) {
      adjacencyList.putIfAbsent(edge.fromId, () => []).add(edge);
    }
    
    // Validar que existan los nodos
    final startNode = nodeMap[startNodeId];
    final endNode = nodeMap[endNodeId];
    
    if (startNode == null) {
      throw ArgumentError('Nodo inicio "$startNodeId" no encontrado');
    }
    
    if (endNode == null) {
      throw ArgumentError('Nodo destino "$endNodeId" no encontrado');
    }
    
    // Si inicio y destino son el mismo
    if (startNodeId == endNodeId) {
      return [];
    }
    
    // Estructuras para A*
    final openSet = <String>{startNodeId};
    final cameFrom = <String, String?>{};
    final gScore = <String, double>{};
    final fScore = <String, double>{};
    
    // Inicializar scores
    for (final node in nodes) {
      gScore[node.id] = double.infinity;
      fScore[node.id] = double.infinity;
    }
    
    gScore[startNodeId] = 0.0;
    fScore[startNodeId] = _heuristic(startNode, endNode);
    
    // Algoritmo A*
    int iterations = 0;
    while (openSet.isNotEmpty) {
      iterations++;
      
      // Encontrar nodo con menor fScore
      String? currentId;
      double minFScore = double.infinity;
      
      for (final nodeId in openSet) {
        final f = fScore[nodeId] ?? double.infinity;
        if (f < minFScore) {
          minFScore = f;
          currentId = nodeId;
        }
      }
      
      if (currentId == null) break;
      
      // Si llegamos al destino, reconstruir camino
      if (currentId == endNodeId) {
        final pathNodeIds = _reconstructPath(cameFrom, currentId);
        print('🎯 A* completado en $iterations iteraciones, ruta con ${pathNodeIds.length} nodos');
        
        // Convertir lista de IDs a lista de EdgeModels
        return _reconstructPathEdges(pathNodeIds, edges);
      }
      
      openSet.remove(currentId);
      
      // Explorar vecinos
      final neighbors = adjacencyList[currentId] ?? [];
      
      for (final edge in neighbors) {
        final neighborId = edge.toId;
        final neighborNode = nodeMap[neighborId];
        
        if (neighborNode == null) continue;
        
        // Calcular gScore tentativo
        final tentativeGScore = (gScore[currentId] ?? double.infinity) + edge.weight;
        
        if (tentativeGScore < (gScore[neighborId] ?? double.infinity)) {
          // Este camino es mejor
          cameFrom[neighborId] = currentId;
          gScore[neighborId] = tentativeGScore;
          fScore[neighborId] = tentativeGScore + _heuristic(neighborNode, endNode);
          
          if (!openSet.contains(neighborId)) {
            openSet.add(neighborId);
          }
        }
      }
      
      // Límite de seguridad para evitar loops infinitos
      if (iterations > 10000) {
        print('⚠️ A* alcanzó límite de iteraciones (10000)');
        break;
      }
    }
    
    // No se encontró camino
    return [];
  }
  
  /// Reconstruye la lista de EdgeModels desde la lista de IDs de nodos
  static List<EdgeModel> _reconstructPathEdges(List<String> pathNodeIds, List<EdgeModel> allEdges) {
    if (pathNodeIds.length < 2) return [];
    
    final pathEdges = <EdgeModel>[];
    final edgeMap = <String, EdgeModel>{};
    
    // Crear mapa de edges para búsqueda rápida
    for (final edge in allEdges) {
      edgeMap['${edge.fromId}_${edge.toId}'] = edge;
    }
    
    // Reconstruir la secuencia de edges
    for (int i = 0; i < pathNodeIds.length - 1; i++) {
      final fromId = pathNodeIds[i];
      final toId = pathNodeIds[i + 1];
      final edgeKey = '${fromId}_${toId}';
      
      final edge = edgeMap[edgeKey];
      if (edge != null) {
        pathEdges.add(edge);
      } else {
        print('⚠️ No se encontró edge para $fromId -> $toId');
      }
    }
    
    return pathEdges;
  }

  /// Heurística para A* (distancia euclidiana)
  static double _heuristic(MapNodeModel from, MapNodeModel to) {
    final dx = from.x - to.x;
    final dy = from.y - to.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  /// Reconstruye el camino desde el destino hasta el inicio
  static List<String> _reconstructPath(
    Map<String, String?> cameFrom,
    String currentId,
  ) {
    final path = <String>[currentId];
    
    while (cameFrom[currentId] != null) {
      currentId = cameFrom[currentId]!;
      path.insert(0, currentId);
    }
    
    return path;
  }
}

