import '../../domain/entities/map_node_entity.dart';

/// Modelo de nodo del mapa (con serialización)
class MapNodeModel extends MapNodeEntity {
  const MapNodeModel({
    required super.id,
    required super.x,
    required super.y,
    required super.piso,
    super.tipo,
    super.salonId,
  });

  /// Crear desde JSON
  factory MapNodeModel.fromJson(Map<String, dynamic> json) {
    return MapNodeModel(
      id: json['id'] as String,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      piso: json['piso'] as int,
      tipo: json['tipo'] as String?,
      salonId: json['salonId'] as String?,
    );
  }

  /// Convertir a JSON
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

  /// Convertir a entidad
  MapNodeEntity toEntity() {
    return MapNodeEntity(
      id: id,
      x: x,
      y: y,
      piso: piso,
      tipo: tipo,
      salonId: salonId,
    );
  }
}

