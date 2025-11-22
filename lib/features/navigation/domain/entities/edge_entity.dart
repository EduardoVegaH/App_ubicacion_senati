import 'package:flutter/material.dart';

/// Entidad de arista/conexión (sin dependencias externas)
class EdgeEntity {
  final String fromId;
  final String toId;
  final double weight;
  final int piso;
  final String? tipo;
  final List<Offset> shape;

  const EdgeEntity({
    required this.fromId,
    required this.toId,
    required this.weight,
    required this.piso,
    this.tipo,
    this.shape = const [],
  });
}

