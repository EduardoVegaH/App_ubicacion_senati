import '../../domain/entities/map_node.dart';
import '../../domain/entities/map_edge.dart';
import '../../domain/entities/map_floor.dart';
import '../../domain/repositories/navigation_repository.dart';
import '../config/graph_edges_config.dart';

/// Servicio para inicializar los edges del grafo basándose en configuración manual
/// 
/// Lee los nodos desde Firestore, genera edges bidireccionales con pesos calculados
/// y los guarda en Firestore
class GraphInitializer {
  final NavigationRepository repository;

  GraphInitializer(this.repository);

  /// Calcula la distancia euclidiana entre dos nodos
  static double _calculateEuclideanDistance(MapNode from, MapNode to) {
    final dx = from.x - to.x;
    final dy = from.y - to.y;
    return (dx * dx + dy * dy);
  }

  /// Inicializa los edges para un piso específico
  /// 
  /// [floor] El número de piso
  /// 
  /// Retorna el número de edges creados
  Future<int> initializeEdgesForFloor(int floor) async {
    // Verificar que existe configuración para este piso
    if (!GraphEdgesConfig.hasConfigForFloor(floor)) {
      throw Exception('No hay configuración de edges para el piso $floor');
    }

    // Obtener los nodos del piso desde Firestore
    final nodes = await repository.getNodesForFloor(floor);
    if (nodes.isEmpty) {
      throw Exception('No hay nodos cargados para el piso $floor. Inicializa primero los nodos desde SVG.');
    }

    // Crear un mapa de nodos por ID para acceso rápido
    final nodeMap = {for (var node in nodes) node.id: node};

    // Obtener la configuración de edges manuales
    final edgesConfig = GraphEdgesConfig.getEdgesForFloor(floor);

    // Generar edges desde la configuración
    // La configuración ya incluye edges bidireccionales explícitos
    final edges = <MapEdge>[];
    final processedEdges = <String>{}; // Para evitar duplicados exactos

    for (final edgeConfig in edgesConfig) {
      if (edgeConfig.length != 2) continue;

      final fromId = edgeConfig[0];
      final toId = edgeConfig[1];

      // Verificar que ambos nodos existen
      if (!nodeMap.containsKey(fromId) || !nodeMap.containsKey(toId)) {
        // Continuar sin lanzar error, algunos nodos pueden no existir en el SVG
        continue;
      }

      final fromNode = nodeMap[fromId]!;
      final toNode = nodeMap[toId]!;

      // Crear clave única para este edge específico (direccional)
      final edgeKey = '$fromId->$toId';

      // Solo procesar si no hemos procesado este edge exacto antes
      if (!processedEdges.contains(edgeKey)) {
        // Calcular peso (distancia euclidiana)
        final weight = _calculateEuclideanDistance(fromNode, toNode);

        // Crear edge
        edges.add(MapEdge(
          fromId: fromId,
          toId: toId,
          weight: weight,
          floor: floor,
        ));

        processedEdges.add(edgeKey);
      }
    }

    // Obtener el grafo actual del piso
    final currentFloor = await repository.getFloorGraph(floor);

    // Crear nuevo MapFloor con los nodos existentes y los nuevos edges
    final updatedFloor = MapFloor(
      floor: floor,
      nodes: currentFloor.nodes,
      edges: edges,
    );

    // Guardar en Firestore (esto reemplazará los edges existentes)
    await repository.saveFloorGraph(updatedFloor);

    return edges.length;
  }

  /// Inicializa los edges para todos los pisos configurados
  /// 
  /// Retorna un mapa con el número de edges creados por piso
  Future<Map<int, int>> initializeAllEdges() async {
    final results = <int, int>{};

    for (final floorKey in GraphEdgesConfig.floorEdges.keys) {
      final floor = int.parse(floorKey.split('_')[1]);
      try {
        final count = await initializeEdgesForFloor(floor);
        results[floor] = count;
      } catch (e) {
        // Continuar con otros pisos si uno falla
        print('Error inicializando edges para piso $floor: $e');
      }
    }

    return results;
  }
}

