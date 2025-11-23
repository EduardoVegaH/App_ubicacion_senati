import '../models/map_node.dart';
import '../models/edge.dart';
import '../services/graph_storage_service.dart';
import '../services/pathfinding_service.dart';
import '../utils/salon_node_mapper.dart';
import '../utils/salon_node_mapping.dart';
import 'dart:math' as math;

/// Repositorio que abstrae el acceso al grafo de navegación
/// Combina almacenamiento y pathfinding
class GraphRepository {
  final GraphStorageService _storageService = GraphStorageService();

  /// Carga el grafo completo de un piso (nodos + edges)
  Future<Map<String, dynamic>> loadGraph(int piso) async {
    return await _storageService.loadGraph(piso);
  }

  /// Encuentra el camino más corto entre dos nodos
  /// Retorna una lista de Edges (con sus shapes) que representan el camino
  Future<List<Edge>> findPath({
    required int piso,
    required String startNodeId,
    required String endNodeId,
  }) async {
    final graph = await loadGraph(piso);
    final nodes = graph['nodes'] as List<MapNode>;
    final edges = graph['edges'] as List<Edge>;
    
    return PathfindingService.findPathAStar(
      startNodeId: startNodeId,
      endNodeId: endNodeId,
      nodes: nodes,
      edges: edges,
    );
  }

  /// Busca el nodo de entrada principal de un piso
  Future<MapNode?> findEntranceNode(int piso) async {
    return await _storageService.findEntranceNode(piso);
  }

  /// Busca el nodo más cercano a los ascensores
  /// Retorna el nodo más cercano a cualquiera de los ascensores del piso
  Future<MapNode?> findNearestElevatorNode(int piso) async {
    try {
      final nodes = await _storageService.loadNodes(piso);
      if (nodes.isEmpty) return null;
      
      // Coordenadas aproximadas de los ascensores en el piso 2
      // Basadas en el SVG: Asensor01-06
      final elevatorPositions = [
        {'x': 1147.52, 'y': 563.907}, // Asensor01
        {'x': 1066.52, 'y': 565.907}, // Asensor02
        {'x': 987.517, 'y': 567.907}, // Asensor03
        {'x': 1040.52, 'y': 754.907}, // Asensor04
        {'x': 962.517, 'y': 758.907}, // Asensor05
        {'x': 908.517, 'y': 572.571}, // Asensor06
      ];
      
      MapNode? nearestNode;
      double minDistance = double.infinity;
      
      // Buscar el nodo más cercano a cualquiera de los ascensores
      for (final node in nodes) {
        for (final elevator in elevatorPositions) {
          final dx = node.x - elevator['x']!;
          final dy = node.y - elevator['y']!;
          final distance = math.sqrt(dx * dx + dy * dy);
          
          if (distance < minDistance) {
            minDistance = distance;
            nearestNode = node;
          }
        }
      }
      
      if (nearestNode != null) {
        print('✅ Nodo más cercano a ascensores: ${nearestNode.id} (distancia: ${minDistance.toStringAsFixed(2)})');
      }
      
      return nearestNode;
    } catch (e) {
      print('❌ Error al buscar nodo cercano a ascensores en piso $piso: $e');
      return null;
    }
  }

  /// Busca un nodo por ID
  Future<MapNode?> findNodeById(int piso, String nodeId) async {
    return await _storageService.findNodeById(piso, nodeId);
  }

  /// Busca un nodo asociado a un salón
  /// Estrategia:
  /// 1. Buscar en mapeo manual (salon_node_mapping.dart) - MÁS CONFIABLE
  /// 2. Buscar por salonId exacto en el campo salonId del nodo
  /// 3. Usar fallback del mapeo
  /// 4. Buscar por número del salón en los IDs de nodos
  /// 5. Si no encuentra, usar el mapper inteligente
  Future<MapNode?> findNodeBySalon({
    required int piso,
    required String salonId, // ej: "salon-A-604" o "A-604"
  }) async {
    print('🔍 [findNodeBySalon] Buscando nodo para: $salonId en piso $piso');
    final nodes = await _storageService.loadNodes(piso);
    if (nodes.isEmpty) {
      print('❌ No hay nodos cargados para el piso $piso');
      return null;
    }
    print('📊 Total de nodos disponibles: ${nodes.length}');
    
    // 0. Buscar nodo especial de salón primero (formato: node-salon-{TORRE}-{NUMERO})
    // Estos nodos están directamente en las puertas de los salones
    final salonNodeId = 'node-$salonId';
    try {
      final salonNode = nodes.firstWhere((n) => n.id == salonNodeId);
      print('✅ Nodo especial de salón encontrado: $salonId -> $salonNodeId');
      return salonNode;
    } catch (e) {
      // No hay nodo especial, continuar con otras estrategias
    }
    
    // 0.5. Buscar nodos que tengan el salonId en su campo salonId
    try {
      final nodeWithSalonId = nodes.firstWhere(
        (n) => n.salonId == salonId || n.salonId == salonId.replaceFirst('salon-', ''),
      );
      print('✅ Nodo encontrado por salonId en campo: $salonId -> ${nodeWithSalonId.id}');
      return nodeWithSalonId;
    } catch (e) {
      // Continuar con otras estrategias
    }
    
    // 1. Buscar en mapeo manual (más confiable)
    print('🔍 Intentando mapeo manual...');
    final mappedNodeId = SalonNodeMapping.getNodeIdForSalon(
      piso: piso,
      salonId: salonId,
    );
    
    if (mappedNodeId != null) {
      print('✅ Mapeo manual encontrado: $salonId -> $mappedNodeId');
      try {
        final node = nodes.firstWhere((n) => n.id == mappedNodeId);
        print('✅ Nodo encontrado por mapeo manual: $salonId -> $mappedNodeId');
        return node;
      } catch (e) {
        print('⚠️ Nodo $mappedNodeId del mapeo no existe en los nodos cargados: $e');
        print('📋 IDs de nodos disponibles: ${nodes.map((n) => n.id).take(10).join(", ")}...');
      }
    } else {
      print('⚠️ No se encontró mapeo manual para: $salonId');
    }
    
    // 2. Buscar por salonId exacto en los nodos
    print('🔍 Buscando por salonId exacto en nodos...');
    try {
      final node = nodes.firstWhere(
        (n) => n.salonId == salonId || n.salonId == salonId.replaceFirst('salon-', ''),
      );
      print('✅ Nodo encontrado por salonId exacto: ${node.id}');
      return node;
    } catch (e) {
      print('⚠️ No se encontró por salonId exacto: $e');
      // Continuar con otras estrategias
    }
    
    // 3. Usar fallback del mapeo
    print('🔍 Intentando fallback del mapeo...');
    final fallbackNodeId = SalonNodeMapping.getFallbackNodeForSalon(
      piso: piso,
      salonId: salonId,
    );
    
    if (fallbackNodeId != null) {
      print('✅ Fallback encontrado: $salonId -> $fallbackNodeId');
      try {
        final node = nodes.firstWhere((n) => n.id == fallbackNodeId);
        print('✅ Nodo encontrado por fallback: $salonId -> $fallbackNodeId');
        return node;
      } catch (e) {
        print('⚠️ Nodo $fallbackNodeId del fallback no existe: $e');
      }
    } else {
      print('⚠️ No se encontró fallback para: $salonId');
    }
    
    // 4. Buscar por número del salón
    final salonNumber = salonId.replaceAll(RegExp(r'[^0-9]'), '');
    print('🔍 Buscando por número del salón: $salonNumber');
    
    if (salonNumber.isNotEmpty) {
      // Buscar nodos que contengan el número
      final matchingNodes = nodes.where(
        (n) => n.id.contains(salonNumber) || 
               (n.salonId != null && n.salonId!.contains(salonNumber)),
      ).toList();
      
      if (matchingNodes.isNotEmpty) {
        print('✅ Nodo encontrado por número: ${matchingNodes.first.id}');
        return matchingNodes.first;
      } else {
        print('⚠️ No se encontraron nodos con el número $salonNumber');
      }
    }
    
    // 5. Último recurso: usar el mapper inteligente
    print('⚠️ No se encontró nodo específico para $salonId, usando mapper inteligente');
    final intelligentNode = SalonNodeMapper.findNodeForSalon(
      salonId: salonId,
      nodes: nodes,
    );
    if (intelligentNode != null) {
      print('✅ Nodo encontrado por mapper inteligente: ${intelligentNode.id}');
    } else {
      print('❌ Mapper inteligente tampoco encontró nodo');
    }
    return intelligentNode;
  }

  /// Obtiene todos los nodos de un piso
  Future<List<MapNode>> getAllNodes(int piso) async {
    return await _storageService.loadNodes(piso);
  }

  /// Obtiene todas las conexiones de un piso
  Future<List<Edge>> getAllEdges(int piso) async {
    return await _storageService.loadEdges(piso);
  }
}
