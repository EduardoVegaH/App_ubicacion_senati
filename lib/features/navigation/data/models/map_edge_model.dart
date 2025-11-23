import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/map_edge.dart';

/// Modelo de datos de edge del mapa (con serialización para Firestore)
class MapEdgeModel extends MapEdge {
  MapEdgeModel({
    required super.fromId,
    required super.toId,
    required super.weight,
    required super.floor,
  });

  /// Crear desde Firestore
  factory MapEdgeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return MapEdgeModel(
      fromId: data['fromId'] as String? ?? '',
      toId: data['toId'] as String? ?? '',
      weight: (data['weight'] as num?)?.toDouble() ?? 0.0,
      floor: data['floor'] as int? ?? 0,
    );
  }

  /// Convertir a Map para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'fromId': fromId,
      'toId': toId,
      'weight': weight,
      'floor': floor,
    };
  }

  /// Convertir a entidad
  MapEdge toEntity() {
    return MapEdge(
      fromId: fromId,
      toId: toId,
      weight: weight,
      floor: floor,
    );
  }

  /// Crear desde entidad
  factory MapEdgeModel.fromEntity(MapEdge entity) {
    return MapEdgeModel(
      fromId: entity.fromId,
      toId: entity.toId,
      weight: entity.weight,
      floor: entity.floor,
    );
  }
}

