import 'map_node.dart';
import 'map_edge.dart';

/// Entidad que representa el grafo completo de un piso
/// 
/// Contiene todos los nodos y edges que forman el grafo de navegación
/// para un piso específico
class MapFloor {
  final int floor;
  final List<MapNode> nodes;
  final List<MapEdge> edges;

  const MapFloor({
    required this.floor,
    required this.nodes,
    required this.edges,
  });

  /// Crea un MapFloor vacío para un piso
  factory MapFloor.empty(int floor) {
    return MapFloor(
      floor: floor,
      nodes: const [],
      edges: const [],
    );
  }

  /// Verifica si el grafo está vacío
  bool get isEmpty => nodes.isEmpty && edges.isEmpty;

  /// Verifica si el grafo tiene contenido
  bool get isNotEmpty => !isEmpty;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MapFloor &&
        other.floor == floor &&
        _listEquals(other.nodes, nodes) &&
        _listEquals(other.edges, edges);
  }

  @override
  int get hashCode {
    return Object.hash(floor, nodes.length, edges.length);
  }

  @override
  String toString() {
    return 'MapFloor(floor: $floor, nodes: ${nodes.length}, edges: ${edges.length})';
  }

  /// Compara dos listas de forma profunda
  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

