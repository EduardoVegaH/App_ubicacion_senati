import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/map_node.dart';
import '../models/edge.dart';
import '../parsers/svg_route_parser.dart';

/// Servicio para generar automáticamente las conexiones (edges) entre nodos
/// Basado en distancia mínima y proximidad física
class EdgeGeneratorService {
  /// Distancia máxima para considerar dos nodos como conectados (en píxeles SVG)
  /// Reducido a 250 para evitar conexiones directas entre nodos muy lejanos
  /// Esto fuerza rutas más geométricas pasando por nodos intermedios
  static const double maxConnectionDistance = 250.0;
  
  /// Distancia mínima para evitar conexiones demasiado cortas
  static const double minConnectionDistance = 10.0;

  /// Genera edges automáticamente para una lista de nodos
  /// 
  /// Estrategia:
  /// 1. Conecta nodos que están dentro de maxConnectionDistance
  /// 2. SOLO conecta nodos que estén cerca de la ruta física del SVG
  /// 3. Prioriza conexiones a nodos de tipo "pasillo"
  /// 4. Evita conexiones demasiado cortas
  static Future<List<Edge>> generateEdges({
    required List<MapNode> nodes,
    required int piso,
    String? svgPath, // Ruta del SVG para parsear la ruta física
  }) async {
    final List<Edge> edges = [];
    final Set<String> edgeSet = {}; // Para evitar duplicados
    
    print('🔗 Generando edges para ${nodes.length} nodos del piso $piso...');
    
    // Parsear la ruta física del SVG si está disponible
    List<Offset> routePoints = [];
    if (svgPath != null) {
      try {
        routePoints = await SvgRouteParser.parseRoutePath(svgPath);
        if (routePoints.isNotEmpty) {
          print('✅ Ruta física cargada: ${routePoints.length} puntos');
        }
      } catch (e) {
        print('⚠️ No se pudo cargar la ruta física: $e');
      }
    }
    
    // Umbral de distancia a la ruta (en píxeles SVG)
    // Solo conectaremos nodos que estén cerca de la ruta física
    const double routeThreshold = 50.0; // 50 píxeles de tolerancia para nodos
    
    // Máxima desviación permitida para SEGMENTOS (más estricto, actúa como "paredes")
    // Si un segmento se desvía más de esto, NO se crea el edge (bloquea saltos diagonales)
    const double maxSegmentDeviation = 30.0; // 30 píxeles máximo - muy estricto
    
    // Reducir distancia máxima de conexión para forzar más nodos intermedios
    // Esto asegura que A* siga la ruta paso a paso
    const double maxConnectionDistanceForRoute = 120.0; // Reducido para más nodos intermedios
    
    // Ordenar nodos por tipo (priorizar pasillos y entradas)
    final sortedNodes = List<MapNode>.from(nodes);
    sortedNodes.sort((a, b) {
      final aPriority = _getNodePriority(a);
      final bPriority = _getNodePriority(b);
      return bPriority.compareTo(aPriority); // Mayor prioridad primero
    });
    
    for (int i = 0; i < sortedNodes.length; i++) {
      final fromNode = sortedNodes[i];
      final fromPoint = Offset(fromNode.x, fromNode.y);
      
      // Obtener posición del nodo origen en la ruta (si hay ruta)
      double? fromNodeRoutePos;
      if (routePoints.isNotEmpty) {
        fromNodeRoutePos = SvgRouteParser.getRoutePosition(fromPoint, routePoints);
      }
      
      // Verificar si el nodo origen está cerca de la ruta (si hay ruta definida)
      bool fromNodeOnRoute = true;
      if (routePoints.isNotEmpty) {
        fromNodeOnRoute = SvgRouteParser.isNearRoute(fromPoint, routePoints, routeThreshold);
      }
      
      // Buscar nodos cercanos
      final nearbyNodes = <MapNode>[];
      
      for (int j = i + 1; j < sortedNodes.length; j++) {
        final toNode = sortedNodes[j];
        final toPoint = Offset(toNode.x, toNode.y);
        
        // Verificar distancia entre nodos
        final distance = fromNode.distanceToReal(toNode);
        
        // Si hay ruta definida, usar distancia más corta para forzar más nodos intermedios
        final effectiveMaxDistance = routePoints.isNotEmpty 
            ? maxConnectionDistanceForRoute 
            : maxConnectionDistance;
        
        if (distance <= effectiveMaxDistance && 
            distance >= minConnectionDistance) {
          
          // Si hay ruta definida, verificar que ambos nodos estén cerca de la ruta
          // Y que el segmento entre ellos siga la ruta física
          bool shouldConnect = true;
          
          if (routePoints.isNotEmpty) {
            final toNodeOnRoute = SvgRouteParser.isNearRoute(toPoint, routePoints, routeThreshold);
            
            // Ambos nodos deben estar cerca de la ruta
            if (!fromNodeOnRoute || !toNodeOnRoute) {
              shouldConnect = false;
            } else {
              // CRÍTICO: Verificar que el SEGMENTO COMPLETO esté dentro de la ruta física
              // Esto actúa como "paredes" que impiden saltos diagonales
              // Si el segmento cruza fuera de la ruta (atraviesa una pared), NO crear el edge
              final segmentStart = Offset(fromNode.x, fromNode.y);
              final segmentEnd = Offset(toNode.x, toNode.y);
              
              final isInsideRoute = SvgRouteParser.isSegmentInsideRoute(
                segmentStart,
                segmentEnd,
                routePoints,
                maxSegmentDeviation, // Máximo 30px de desviación - muy estricto
              );
              
              if (!isInsideRoute) {
                shouldConnect = false;
                // Log para debugging
                if (distance > 100.0) {
                  print('🚫 Edge bloqueado (segmento fuera de ruta): ${fromNode.id} -> ${toNode.id} (distancia: ${distance.toStringAsFixed(1)}px)');
                }
              }
            }
          }
          
          if (shouldConnect) {
            nearbyNodes.add(toNode);
          }
        }
      }
      
      // Si hay ruta definida, ordenar nodos por su posición secuencial en la ruta
      // Esto asegura que conectemos nodos adyacentes en la ruta física
      if (routePoints.isNotEmpty && fromNodeRoutePos != null) {
        final fromPos = fromNodeRoutePos; // Variable local no-nullable
        nearbyNodes.sort((a, b) {
          final aPoint = Offset(a.x, a.y);
          final bPoint = Offset(b.x, b.y);
          
          // Obtener posición en la ruta (0.0 a 1.0)
          final aPosition = SvgRouteParser.getRoutePosition(aPoint, routePoints);
          final bPosition = SvgRouteParser.getRoutePosition(bPoint, routePoints);
          
          // Calcular diferencia de posición respecto al nodo origen
          // Preferir nodos que estén "adelante" en la ruta (mayor posición)
          final aDiff = (aPosition - fromPos).abs();
          final bDiff = (bPosition - fromPos).abs();
          
          // Si están en posiciones similares, priorizar por distancia euclidiana
          if ((aDiff - bDiff).abs() < 0.05) {
            final aDist = fromNode.distanceToReal(a);
            final bDist = fromNode.distanceToReal(b);
            return aDist.compareTo(bDist);
          }
          
          // Priorizar nodos más cercanos en posición secuencial
          return aDiff.compareTo(bDiff);
        });
        
        // Filtrar nodos que estén "muy atrás" en la ruta (solo conectar hacia adelante)
        // Esto evita crear edges que vayan en dirección contraria
        nearbyNodes.removeWhere((node) {
          final nodePos = SvgRouteParser.getRoutePosition(
            Offset(node.x, node.y),
            routePoints,
          );
          // Solo permitir nodos que estén adelante o muy cerca (diferencia < 0.2)
          final posDiff = nodePos - fromPos;
          return posDiff < -0.2; // Eliminar nodos que estén más de 20% atrás
        });
      } else {
        // Sin ruta, ordenar solo por distancia
        nearbyNodes.sort((a, b) {
          final distA = fromNode.distanceToReal(a);
          final distB = fromNode.distanceToReal(b);
          return distA.compareTo(distB);
        });
      }
      
      // Conectar con menos nodos para forzar más pasos intermedios
      // Reducido a 2 para que A* siga la ruta más fielmente, paso a paso
      final maxConnections = routePoints.isNotEmpty 
          ? math.min(2, nearbyNodes.length) // Solo 2 conexiones si hay ruta (nodos adyacentes)
          : math.min(8, nearbyNodes.length); // Más conexiones si no hay ruta
      
      for (int k = 0; k < maxConnections; k++) {
        final toNode = nearbyNodes[k];
        final distance = fromNode.distanceToReal(toNode);
        
        // Crear edge bidireccional
        final edgeKey1 = '${fromNode.id}_${toNode.id}';
        final edgeKey2 = '${toNode.id}_${fromNode.id}';
        
        if (!edgeSet.contains(edgeKey1) && !edgeSet.contains(edgeKey2)) {
          // Determinar tipo de conexión
          String? tipo;
          if (fromNode.tipo == 'pasillo' || toNode.tipo == 'pasillo') {
            tipo = 'pasillo';
          } else if (fromNode.tipo == 'escalera' || toNode.tipo == 'escalera') {
            tipo = 'escalera';
          } else if (fromNode.tipo == 'ascensor' || toNode.tipo == 'ascensor') {
            tipo = 'ascensor';
          }
          
          // Calcular peso del edge
          // Si hay ruta definida, penalizar edges largos para forzar más nodos intermedios
          double edgeWeight = distance;
          if (routePoints.isNotEmpty) {
            // Penalizar edges largos: cuanto más largo, más peso adicional
            // Esto hace que A* prefiera rutas con más nodos intermedios
            if (distance > 80.0) {
              // Penalización progresiva para edges largos
              // Edges de 80-120px: 30% de penalización
              // Edges > 120px: 60% de penalización
              final penaltyFactor = distance > 120.0 ? 0.6 : 0.3;
              final penalty = (distance - 80.0) * penaltyFactor;
              edgeWeight = distance + penalty;
            }
          }
          
          // Crear edge bidireccional (ambas direcciones)
          edges.add(Edge(
            fromId: fromNode.id,
            toId: toNode.id,
            weight: edgeWeight,
            piso: piso,
            tipo: tipo,
          ));
          
          edges.add(Edge(
            fromId: toNode.id,
            toId: fromNode.id,
            weight: edgeWeight,
            piso: piso,
            tipo: tipo,
          ));
          
          edgeSet.add(edgeKey1);
          edgeSet.add(edgeKey2);
        }
      }
    }
    
    print('✅ Generados ${edges.length} edges iniciales para el piso $piso');
    
    // Si hay ruta física, filtrar edges que "saltan" nodos intermedios
    List<Edge> filteredEdges = edges;
    if (routePoints.isNotEmpty) {
      print('🔍 Filtrando edges largos (ruta física con ${routePoints.length} puntos)...');
      filteredEdges = _filterLongJumps(edges, nodes, routePoints);
      print('✅ Después de filtrar saltos largos: ${filteredEdges.length} edges (se eliminaron ${edges.length - filteredEdges.length} edges)');
      
      // Mostrar estadísticas de edges filtrados
      final longEdges = edges.where((e) => e.weight > 100.0).length;
      final filteredLongEdges = filteredEdges.where((e) => e.weight > 100.0).length;
      print('📊 Edges largos (>100px): antes=$longEdges, después=$filteredLongEdges');
    }
    
    // Asegurar que el grafo sea conexo (todos los nodos alcanzables)
    // Nota: La conectividad se asegura respetando la ruta física
    final connectedEdges = await _ensureGraphConnectivity(nodes, filteredEdges, piso, svgPath, routePoints);
    
    print('✅ Total de edges después de asegurar conectividad: ${connectedEdges.length}');
    
    // Aplicar filtro FINAL para eliminar cualquier edge largo que se haya creado
    // Esto es crítico porque _ensureGraphConnectivity puede crear edges largos
    List<Edge> finalEdges = connectedEdges;
    if (routePoints.isNotEmpty) {
      print('🔍 Aplicando filtro final para eliminar edges largos...');
      finalEdges = _filterLongJumps(connectedEdges, nodes, routePoints);
      print('✅ Edges finales después del filtro: ${finalEdges.length} (se eliminaron ${connectedEdges.length - finalEdges.length} edges adicionales)');
    }
    
    return finalEdges;
  }

  /// Asegura que el grafo sea conexo conectando componentes desconectados
  /// Usa un algoritmo de Minimum Spanning Tree para conectar todos los nodos
  /// Respetando la ruta física del SVG
  static Future<List<Edge>> _ensureGraphConnectivity(
    List<MapNode> nodes,
    List<Edge> existingEdges,
    int piso,
    String? svgPath,
    List<Offset> routePoints,
  ) async {
    final allEdges = List<Edge>.from(existingEdges);
    final edgeSet = <String>{};
    
    // Agregar edges existentes al set
    for (final edge in existingEdges) {
      edgeSet.add('${edge.fromId}_${edge.toId}');
      edgeSet.add('${edge.toId}_${edge.fromId}');
    }
    
    // Crear lista de adyacencia para verificar conectividad
    final adjacencyList = <String, Set<String>>{};
    for (final node in nodes) {
      adjacencyList[node.id] = <String>{};
    }
    
    for (final edge in existingEdges) {
      adjacencyList[edge.fromId]!.add(edge.toId);
      adjacencyList[edge.toId]!.add(edge.fromId);
    }
    
    // Encontrar componentes conectados usando BFS
    final visited = <String>{};
    final components = <List<String>>[];
    
    for (final node in nodes) {
      if (!visited.contains(node.id)) {
        final component = <String>[];
        final queue = <String>[node.id];
        visited.add(node.id);
        
        while (queue.isNotEmpty) {
          final current = queue.removeAt(0);
          component.add(current);
          
          for (final neighbor in adjacencyList[current]!) {
            if (!visited.contains(neighbor)) {
              visited.add(neighbor);
              queue.add(neighbor);
            }
          }
        }
        
        components.add(component);
      }
    }
    
    print('📊 Componentes conectados encontrados: ${components.length}');
    
    // Si hay más de un componente, conectar el más cercano de cada componente
    if (components.length > 1) {
      print('🔗 Conectando componentes desconectados...');
      
      for (int i = 0; i < components.length - 1; i++) {
        final component1 = components[i];
        final component2 = components[i + 1];
        
        // Encontrar los dos nodos más cercanos entre los componentes
        MapNode? closestNode1;
        MapNode? closestNode2;
        double minDistance = double.infinity;
        
        for (final nodeId1 in component1) {
          final node1 = nodes.firstWhere((n) => n.id == nodeId1);
          for (final nodeId2 in component2) {
            final node2 = nodes.firstWhere((n) => n.id == nodeId2);
            final distance = node1.distanceToReal(node2);
            
            if (distance < minDistance) {
              minDistance = distance;
              closestNode1 = node1;
              closestNode2 = node2;
            }
          }
        }
        
        if (closestNode1 != null && closestNode2 != null) {
          // CRÍTICO: No crear edges largos (máximo 100px)
          // Si la distancia es mayor, no crear la conexión directa
          // Esto fuerza que A* pase por nodos intermedios
          const double maxConnectionDistance = 100.0;
          
          if (minDistance > maxConnectionDistance) {
            print('⚠️ No se conectó ${closestNode1.id} <-> ${closestNode2.id} (distancia ${minDistance.toStringAsFixed(1)}px > ${maxConnectionDistance}px)');
            continue; // Saltar esta conexión, es demasiado larga
          }
          
          // Verificar que la conexión esté cerca de la ruta física (si hay ruta)
          bool shouldConnect = true;
          
          if (routePoints.isNotEmpty) {
            final p1 = Offset(closestNode1.x, closestNode1.y);
            final p2 = Offset(closestNode2.x, closestNode2.y);
            final midPoint = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
            
            // Solo conectar si el punto medio está cerca de la ruta
            shouldConnect = SvgRouteParser.isNearRoute(midPoint, routePoints, 100.0);
          }
          
          if (shouldConnect) {
            final edgeKey1 = '${closestNode1.id}_${closestNode2.id}';
            final edgeKey2 = '${closestNode2.id}_${closestNode1.id}';
            
            if (!edgeSet.contains(edgeKey1)) {
              // Crear edge bidireccional
              allEdges.add(Edge(
                fromId: closestNode1.id,
                toId: closestNode2.id,
                weight: minDistance,
                piso: piso,
                tipo: 'conexion',
              ));
              
              allEdges.add(Edge(
                fromId: closestNode2.id,
                toId: closestNode1.id,
                weight: minDistance,
                piso: piso,
                tipo: 'conexion',
              ));
              
              edgeSet.add(edgeKey1);
              edgeSet.add(edgeKey2);
              
              print('✅ Conectado ${closestNode1.id} <-> ${closestNode2.id} (distancia: ${minDistance.toStringAsFixed(2)})');
            }
          } else {
            print('⚠️ No se conectó ${closestNode1.id} <-> ${closestNode2.id} (fuera de la ruta física)');
          }
        }
      }
    }
    
    return allEdges;
  }

  /// Filtra edges que "saltan" muchos nodos intermedios en la ruta física
  /// Esto asegura que A* siga la ruta paso a paso
  static List<Edge> _filterLongJumps(
    List<Edge> edges,
    List<MapNode> nodes,
    List<Offset> routePoints,
  ) {
    final nodeMap = {for (var node in nodes) node.id: node};
    final filteredEdges = <Edge>[];
    
    for (final edge in edges) {
      final fromNode = nodeMap[edge.fromId];
      final toNode = nodeMap[edge.toId];
      
      if (fromNode == null || toNode == null) continue;
      
      // Obtener posiciones en la ruta (0.0 a 1.0)
      final fromPos = SvgRouteParser.getRoutePosition(
        Offset(fromNode.x, fromNode.y),
        routePoints,
      );
      final toPos = SvgRouteParser.getRoutePosition(
        Offset(toNode.x, toNode.y),
        routePoints,
      );
      
      // Verificar que el SEGMENTO COMPLETO esté dentro de la ruta física
      // Esto es la verificación más importante: actúa como "paredes"
      final segmentStart = Offset(fromNode.x, fromNode.y);
      final segmentEnd = Offset(toNode.x, toNode.y);
      
      const double maxSegmentDeviation = 30.0; // Máximo 30px de desviación
      
      final isSegmentInside = SvgRouteParser.isSegmentInsideRoute(
        segmentStart,
        segmentEnd,
        routePoints,
        maxSegmentDeviation,
      );
      
      // También verificar distancia física y posición en la ruta
      final posDiff = (toPos - fromPos).abs();
      final maxPosDiff = 0.08; // 8% de la ruta
      final maxPhysicalDistance = 100.0; // 100px máximo
      
      if (isSegmentInside && posDiff < maxPosDiff && edge.weight <= maxPhysicalDistance) {
        // Permitir edge solo si:
        // 1. El segmento COMPLETO está dentro de la ruta (no atraviesa paredes), Y
        // 2. Los nodos están cerca en la secuencia (< 8% de diferencia), Y
        // 3. El edge es corto (<= 100px)
        filteredEdges.add(edge);
      } else {
        if (!isSegmentInside) {
          print('🚫 Edge filtrado (segmento fuera de ruta): ${edge.fromId} -> ${edge.toId} (distancia: ${edge.weight.toStringAsFixed(1)}px)');
        } else {
          print('🚫 Edge filtrado: ${edge.fromId} -> ${edge.toId} (salto de ${(posDiff * 100).toStringAsFixed(1)}% de la ruta, distancia: ${edge.weight.toStringAsFixed(1)}px)');
        }
      }
    }
    
    return filteredEdges;
  }

  /// Obtiene la prioridad de un nodo para conexiones
  /// Mayor prioridad = más importante para conectar
  static int _getNodePriority(MapNode node) {
    switch (node.tipo) {
      case 'entrada':
        return 5;
      case 'pasillo':
        return 4;
      case 'escalera':
      case 'ascensor':
        return 3;
      case 'salon':
        return 2;
      default:
        return 1;
    }
  }

  /// Genera edges manuales específicos (para casos especiales)
  /// Útil para conectar nodos que no están físicamente cercanos pero deben estar conectados
  static List<Edge> generateManualEdges({
    required List<MapNode> nodes,
    required int piso,
    required List<Map<String, String>> manualConnections, // [{"from": "node01", "to": "node05"}]
  }) {
    final List<Edge> edges = [];
    final nodeMap = {for (var node in nodes) node.id: node};
    
    for (final connection in manualConnections) {
      final fromId = connection['from'];
      final toId = connection['to'];
      
      if (fromId == null || toId == null) continue;
      
      final fromNode = nodeMap[fromId];
      final toNode = nodeMap[toId];
      
      if (fromNode == null || toNode == null) {
        print('⚠️ Advertencia: No se encontraron nodos para conexión manual $fromId -> $toId');
        continue;
      }
      
      final distance = math.sqrt(fromNode.distanceToReal(toNode));
      
      edges.add(Edge(
        fromId: fromId,
        toId: toId,
        weight: distance,
        piso: piso,
        tipo: 'manual',
      ));
    }
    
    return edges;
  }
}

