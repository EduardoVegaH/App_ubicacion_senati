import 'package:flutter/material.dart';
import '../../domain/entities/edge_entity.dart';

/// Modelo de arista/conexión (con serialización)
class EdgeModel extends EdgeEntity {
  const EdgeModel({
    required super.fromId,
    required super.toId,
    required super.weight,
    required super.piso,
    super.tipo,
    super.shape = const [],
  });

  /// Crear desde JSON
  factory EdgeModel.fromJson(Map<String, dynamic> json) {
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

    return EdgeModel(
      fromId: json['fromId'] as String,
      toId: json['toId'] as String,
      weight: (json['weight'] as num).toDouble(),
      piso: json['piso'] as int,
      tipo: json['tipo'] as String?,
      shape: shape,
    );
  }

  /// Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'fromId': fromId,
      'toId': toId,
      'weight': weight,
      'piso': piso,
      if (tipo != null) 'tipo': tipo,
      'shape': shape.map((offset) => {'x': offset.dx, 'y': offset.dy}).toList(),
    };
  }

  /// Convertir a entidad
  EdgeEntity toEntity() {
    return EdgeEntity(
      fromId: fromId,
      toId: toId,
      weight: weight,
      piso: piso,
      tipo: tipo,
      shape: shape,
    );
  }
}

