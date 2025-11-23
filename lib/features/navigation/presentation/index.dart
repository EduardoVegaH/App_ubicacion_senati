import 'package:flutter/material.dart';
import 'pages/navigation_map_page.dart';

/// Barrel export para presentation layer de navigation
export 'pages/index.dart';
export 'widgets/index.dart';

/// Helper function para construir la navegación hacia una sala
/// 
/// [floor] El número de piso
/// [fromNodeId] ID del nodo de origen
/// [toNodeId] ID del nodo de destino
Widget buildNavigationForRoom({
  required int floor,
  required String fromNodeId,
  required String toNodeId,
}) {
  return NavigationMapPage(
    floor: floor,
    fromNodeId: fromNodeId,
    toNodeId: toNodeId,
  );
}
