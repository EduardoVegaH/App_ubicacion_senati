/// Entidad que representa un nodo en el mapa (punto de interés o conexión)
/// 
/// Un nodo puede ser un salón, baño, escalera, pasillo, etc.
class MapNode {
  final String id;
  final double x;
  final double y;
  final int floor;
  final String? type; // 'pasillo', 'salon', 'escalera', 'bano', etc.
  final String? refId; // id de salón/sala asociado si aplica

  const MapNode({
    required this.id,
    required this.x,
    required this.y,
    required this.floor,
    this.type,
    this.refId,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MapNode &&
        other.id == id &&
        other.x == x &&
        other.y == y &&
        other.floor == floor &&
        other.type == type &&
        other.refId == refId;
  }

  @override
  int get hashCode {
    return Object.hash(id, x, y, floor, type, refId);
  }

  @override
  String toString() {
    return 'MapNode(id: $id, x: $x, y: $y, floor: $floor, type: $type, refId: $refId)';
  }
}

