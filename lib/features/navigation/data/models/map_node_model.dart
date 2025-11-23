import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/map_node.dart';

/// Modelo de datos de nodo del mapa (con serialización para Firestore)
class MapNodeModel extends MapNode {
  MapNodeModel({
    required super.id,
    required super.x,
    required super.y,
    required super.floor,
    super.type,
    super.refId,
  });

  /// Crear desde Firestore
  factory MapNodeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return MapNodeModel(
      id: doc.id,
      x: (data['x'] as num?)?.toDouble() ?? 0.0,
      y: (data['y'] as num?)?.toDouble() ?? 0.0,
      floor: data['floor'] as int? ?? 0,
      type: data['type'] as String?,
      refId: data['refId'] as String?,
    );
  }

  /// Convertir a Map para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'x': x,
      'y': y,
      'floor': floor,
      'type': type,
      'refId': refId,
    };
  }

  /// Convertir a entidad
  MapNode toEntity() {
    return MapNode(
      id: id,
      x: x,
      y: y,
      floor: floor,
      type: type,
      refId: refId,
    );
  }

  /// Crear desde entidad
  factory MapNodeModel.fromEntity(MapNode entity) {
    return MapNodeModel(
      id: entity.id,
      x: entity.x,
      y: entity.y,
      floor: entity.floor,
      type: entity.type,
      refId: entity.refId,
    );
  }
}

