/// Entidad que representa una conexión entre dos nodos en el mapa
/// 
/// Un edge conecta dos nodos y tiene un peso (distancia) asociado
class MapEdge {
  final String fromId;
  final String toId;
  final double weight; // distancia, por defecto euclidiana
  final int floor;

  const MapEdge({
    required this.fromId,
    required this.toId,
    required this.weight,
    required this.floor,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MapEdge &&
        other.fromId == fromId &&
        other.toId == toId &&
        other.weight == weight &&
        other.floor == floor;
  }

  @override
  int get hashCode {
    return Object.hash(fromId, toId, weight, floor);
  }

  @override
  String toString() {
    return 'MapEdge(fromId: $fromId, toId: $toId, weight: $weight, floor: $floor)';
  }
}

