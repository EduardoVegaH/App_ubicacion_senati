import 'package:flutter/material.dart';

/// Modelo que representa una conexión (arista) entre dos nodos
/// Usado para construir el grafo de navegación
class Edge {
  /// ID del nodo origen
  final String fromId;
  
  /// ID del nodo destino
  final String toId;
  
  /// Peso de la arista (distancia entre nodos)
  final double weight;
  
  /// Piso al que pertenece esta conexión
  final int piso;
  
  /// Tipo de conexión (pasillo, escalera, ascensor, conexion)
  final String? tipo;
  
  /// Forma del segmento físico del pasillo entre los dos nodos
  /// Lista de puntos (Offset) que representan el camino real a seguir
  final List<Offset> shape;

  const Edge({
    required this.fromId,
    required this.toId,
    required this.weight,
    required this.piso,
    this.tipo,
    this.shape = const [],
  });

  /// Crea un Edge desde un Map (útil para deserialización de Firestore)
  factory Edge.fromJson(Map<String, dynamic> json) {
    // Parsear shape si existe
    List<Offset> shape = [];
    if (json['shape'] != null) {
      final shapeList = json['shape'] as List;
      shape = shapeList.map((item) {
        if (item is Map) {
          return Offset(
            (item['x'] as num).toDouble(),
            (item['y'] as num).toDouble(),
          );
        }
        return Offset(0, 0);
      }).toList();
    }
    
    return Edge(
      fromId: json['fromId'] as String,
      toId: json['toId'] as String,
      weight: (json['weight'] as num).toDouble(),
      piso: json['piso'] as int,
      tipo: json['tipo'] as String?,
      shape: shape,
    );
  }

  /// Convierte el Edge a un Map (útil para serialización a Firestore)
  Map<String, dynamic> toJson() {
    return {
      'fromId': fromId,
      'toId': toId,
      'weight': weight,
      'piso': piso,
      if (tipo != null) 'tipo': tipo,
      if (shape.isNotEmpty) 'shape': shape.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
    };
  }

  /// Crea un Edge bidireccional (retorna dos edges)
  static List<Edge> bidirectional({
    required String nodeA,
    required String nodeB,
    required double weight,
    required int piso,
    String? tipo,
  }) {
    return [
      Edge(fromId: nodeA, toId: nodeB, weight: weight, piso: piso, tipo: tipo),
      Edge(fromId: nodeB, toId: nodeA, weight: weight, piso: piso, tipo: tipo),
    ];
  }

  @override
  String toString() => 'Edge($fromId -> $toId, weight: $weight, piso: $piso)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Edge &&
          runtimeType == other.runtimeType &&
          fromId == other.fromId &&
          toId == other.toId &&
          piso == other.piso;

  @override
  int get hashCode => Object.hash(fromId, toId, piso);
}

