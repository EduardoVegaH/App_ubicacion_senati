import 'dart:math' as math;

/// Modelo que representa un nodo en el mapa SVG
/// Cada nodo corresponde a un <circle> en el SVG con id, cx, cy
class MapNode {
  /// ID del nodo (ej: "node01", "node_14", "entrada_principal")
  final String id;
  
  /// Coordenada X del nodo en el SVG
  final double x;
  
  /// Coordenada Y del nodo en el SVG
  final double y;
  
  /// Piso al que pertenece este nodo (1, 2, etc.)
  final int piso;
  
  /// Tipo de nodo (entrada, pasillo, salon, escalera, ascensor)
  final String? tipo;
  
  /// ID del salón asociado (si aplica)
  final String? salonId;

  const MapNode({
    required this.id,
    required this.x,
    required this.y,
    required this.piso,
    this.tipo,
    this.salonId,
  });

  /// Crea un MapNode desde un Map (útil para deserialización de Firestore)
  factory MapNode.fromJson(Map<String, dynamic> json) {
    return MapNode(
      id: json['id'] as String,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      piso: json['piso'] as int,
      tipo: json['tipo'] as String?,
      salonId: json['salonId'] as String?,
    );
  }

  /// Convierte el MapNode a un Map (útil para serialización a Firestore)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'x': x,
      'y': y,
      'piso': piso,
      if (tipo != null) 'tipo': tipo,
      if (salonId != null) 'salonId': salonId,
    };
  }

  /// Calcula la distancia euclidiana al cuadrado a otro nodo (sin raíz cuadrada, más eficiente)
  double distanceTo(MapNode other) {
    final dx = x - other.x;
    final dy = y - other.y;
    return (dx * dx + dy * dy);
  }

  /// Calcula la distancia euclidiana real (con raíz cuadrada)
  double distanceToReal(MapNode other) {
    final dx = x - other.x;
    final dy = y - other.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  @override
  String toString() => 'MapNode(id: $id, x: $x, y: $y, piso: $piso)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapNode && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

