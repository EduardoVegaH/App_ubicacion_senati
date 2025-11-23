import 'package:flutter/services.dart';
import '../models/edge.dart';
import '../models/map_node.dart';
import '../parsers/svg_route_parser.dart';

/// Configuración manual de edges (conexiones) entre nodos
/// Define explícitamente qué nodos están conectados, sin generación automática
class GraphEdgesConfig {
  /// Edges manuales para el piso 2
  /// Define las conexiones exactas que deben existir entre nodos
  /// Extrae los segmentos físicos del SVG para cada edge
  static Future<List<Edge>> getPiso2EdgesManual(
    List<MapNode> nodes, {
    String? svgPath,
  }) async {
    // Crear mapa de nodos por ID para calcular pesos
    final nodeMap = {for (var node in nodes) node.id: node};
    
    // Cargar ruta física del SVG si está disponible
    List<Offset> routePoints = [];
    if (svgPath != null) {
      try {
        routePoints = await SvgRouteParser.parseRoutePath(svgPath);
        if (routePoints.isNotEmpty) {
          print('✅ Ruta física cargada para extraer shapes: ${routePoints.length} puntos');
        }
      } catch (e) {
        print('⚠️ No se pudo cargar la ruta física para shapes: $e');
      }
    }
    
    // Lista de conexiones manuales (fromId, toId)
    final connections = [
      ('node37', 'node35'),
      ('node37', 'node16'),
      ('node35', 'node36'),
      ('node36', 'node33'),
      ('node33', 'node34'),
      ('node35', 'node25'),
      ('node25', 'node24'),
      ('node24', 'node-salon-B-200'),
      ('node25', 'node29'),
      ('node29', 'node-salon-B-200'),
      ('node29', 'node28'),
      ('node28', 'node27'),
      ('node27', 'node21'),
      ('node21', 'node-salon-A-200'),
      ('node28', 'node08'),
      ('node08', 'node09'),
      ('node21', 'node30'),
      ('node33', 'node30'),
      ('node30', 'node31'),
      ('node36', 'node17'),
      ('node17', 'node19'),
      ('node35', 'node23'),
      ('node16', 'node05'),
      ('node05', 'node06'),
      ('node05', 'node03'),
      ('node03', 'node04'),
      ('node03', 'node02'),
      ('node16', 'node14'),
      ('node14', 'node15'),
      ('node14', 'node12'),
      ('node12', 'node13'),
      ('node12', 'node10'),
      ('node10', 'node11'),
      ('node09', 'node10'),
    ];
    
    final edges = <Edge>[];
    
    for (final (fromId, toId) in connections) {
      final fromNode = nodeMap[fromId];
      final toNode = nodeMap[toId];
      
      if (fromNode == null || toNode == null) {
        print('⚠️ Advertencia: No se encontraron nodos para edge $fromId -> $toId');
        continue;
      }
      
      // Calcular peso (distancia) entre los nodos
      final weight = fromNode.distanceToReal(toNode);
      
      // Extraer el segmento físico del pasillo entre estos nodos
      final fromPoint = Offset(fromNode.x, fromNode.y);
      final toPoint = Offset(toNode.x, toNode.y);
      final shape = routePoints.isNotEmpty
          ? SvgRouteParser.extractSegmentBetweenNodes(fromPoint, toPoint, routePoints)
          : [fromPoint, toPoint]; // Fallback: solo los dos nodos
      
      // Crear edge bidireccional (ambas direcciones)
      // Nota: Para el edge inverso, invertir el shape
      final reversedShape = shape.reversed.toList();
      
      edges.add(Edge(
        fromId: fromId,
        toId: toId,
        weight: weight,
        piso: 2,
        tipo: 'pasillo',
        shape: shape,
      ));
      
      edges.add(Edge(
        fromId: toId,
        toId: fromId,
        weight: weight,
        piso: 2,
        tipo: 'pasillo',
        shape: reversedShape,
      ));
    }
    
    print('✅ Generados ${edges.length} edges manuales para piso 2 (${connections.length} conexiones bidireccionales)');
    return edges;
  }
  
  /// Obtiene edges manuales para un piso específico
  static Future<List<Edge>> getManualEdgesForFloor(
    int piso,
    List<MapNode> nodes, {
    String? svgPath,
  }) async {
    switch (piso) {
      case 2:
        return await getPiso2EdgesManual(nodes, svgPath: svgPath);
      default:
        print('⚠️ No hay edges manuales definidos para piso $piso');
        return [];
    }
  }
}

