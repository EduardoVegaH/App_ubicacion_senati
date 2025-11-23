import '../parsers/svg_node_parser.dart';
import '../parsers/svg_salon_parser.dart';
import '../services/graph_storage_service.dart';
import '../services/edge_generator_service.dart';
import '../models/map_node.dart';
import '../models/edge.dart';
import '../utils/salon_node_mapping.dart';
import '../config/graph_edges_config.dart';

/// Utilidad para inicializar el grafo completo desde los SVG
/// Parsea los SVG, genera edges automáticamente y guarda en Firestore
class GraphInitializer {
  final GraphStorageService _storageService = GraphStorageService();

  /// Inicializa el grafo completo para todos los pisos
  /// 
  /// [svgPaths] - Mapa de piso a ruta SVG: {1: "assets/mapas/map_ext.svg", 2: "assets/mapas/map_int_piso2.svg"}
  Future<void> initializeAllFloors({
    required Map<int, String> svgPaths,
  }) async {
    print('🚀 Iniciando inicialización del grafo de navegación...');
    
    // 1. Parsear todos los SVG
    final nodesByFloor = await SvgNodeParser.parseAllSvgs(svgPaths: svgPaths);
    
    print('✅ Parseados ${nodesByFloor.length} pisos');
    
    // 2. Para cada piso: generar edges y guardar en Firestore
    for (final entry in nodesByFloor.entries) {
      final piso = entry.key;
      final nodes = entry.value;
      final svgPathForFloor = svgPaths[piso]; // Obtener la ruta del SVG para este piso
      
      print('\n📦 Procesando piso $piso (${nodes.length} nodos)...');
      
      // Usar edges MANUALES en lugar de generación automática
      // Esto asegura que solo se usen las conexiones definidas explícitamente
      List<Edge> edges;
      
      if (piso == 2) {
        print('📋 Usando edges MANUALES para piso 2 (sin generación automática)');
        edges = await GraphEdgesConfig.getPiso2EdgesManual(
          nodes,
          svgPath: svgPathForFloor,
        );
      } else {
        // Para otros pisos, usar generación automática (si es necesario)
        print('⚠️ Piso $piso: usando generación automática (no hay edges manuales definidos)');
        edges = await EdgeGeneratorService.generateEdges(
          nodes: nodes,
          piso: piso,
          svgPath: svgPathForFloor,
        );
      }
      
      // Guardar en Firestore
      await _storageService.saveNodes(piso: piso, nodes: nodes);
      await _storageService.saveEdges(piso: piso, edges: edges);
      
      print('✅ Piso $piso inicializado: ${nodes.length} nodos, ${edges.length} edges');
    }
    
    print('\n🎉 Inicialización completa del grafo de navegación');
  }

  /// Inicializa un piso específico
  Future<void> initializeFloor({
    required int piso,
    required String svgPath,
  }) async {
    print('🚀 Inicializando piso $piso desde $svgPath...');
    
    // 1. Parsear SVG para obtener nodos
    final nodes = await SvgNodeParser.parseNodesFromSvg(
      svgPath: svgPath,
      piso: piso,
    );
    
    // 2. Parsear salones desde SVG (si tienen formato correcto: salon-{TORRE}-{NUMERO})
    // Esto creará mapeos automáticos si los IDs en Figma tienen el formato correcto
    Map<String, String> salonMappings = {};
    try {
      salonMappings = await SvgSalonParser.parseSalonsAndMapToNodes(
        svgPath: svgPath,
        nodes: nodes,
        piso: piso,
      );
      
      if (salonMappings.isNotEmpty) {
        print('✅ Detectados ${salonMappings.length} salones con formato estándar desde SVG');
      }
    } catch (e) {
      print('⚠️ No se pudieron parsear salones automáticamente: $e');
    }
    
    // 3. Asociar salones con nodos usando mapeos automáticos del SVG y mapeo manual (fallback)
    final nodesWithSalons = _associateSalonsWithNodes(nodes, piso, salonMappings);
    
    // 4. Usar edges MANUALES para piso 2, generación automática para otros pisos
    List<Edge> edges;
    
    if (piso == 2) {
      print('📋 Usando edges MANUALES para piso 2 (sin generación automática)');
      edges = await GraphEdgesConfig.getPiso2EdgesManual(
        nodesWithSalons,
        svgPath: svgPath,
      );
    } else {
      print('⚠️ Piso $piso: usando generación automática');
      edges = await EdgeGeneratorService.generateEdges(
        nodes: nodesWithSalons,
        piso: piso,
        svgPath: svgPath,
      );
    }
    
    // 5. Guardar en Firestore
    await _storageService.saveNodes(piso: piso, nodes: nodesWithSalons);
    await _storageService.saveEdges(piso: piso, edges: edges);
    
    print('✅ Piso $piso inicializado: ${nodesWithSalons.length} nodos, ${edges.length} edges');
    print('✅ ${nodesWithSalons.where((n) => n.salonId != null).length} nodos asociados con salones');
  }

  /// Asocia salones con nodos usando mapeos automáticos del SVG y mapeo manual (fallback)
  List<MapNode> _associateSalonsWithNodes(
    List<MapNode> nodes,
    int piso,
    Map<String, String> automaticMappings,
  ) {
    // Crear mapa de nodos por ID para acceso rápido
    final nodeMap = <String, MapNode>{};
    for (final node in nodes) {
      nodeMap[node.id] = node;
    }
    
    // Mapa inverso: nodeId -> salonId
    final nodeToSalonMap = <String, String>{};
    
    // 1. PRIORIDAD: Usar mapeos automáticos del SVG (si existen)
    // Estos vienen de los IDs en Figma con formato salon-{TORRE}-{NUMERO}
    for (final entry in automaticMappings.entries) {
      final salonId = entry.key;
      final nodeId = entry.value;
      if (nodeMap.containsKey(nodeId)) {
        nodeToSalonMap[nodeId] = salonId;
        print('✅ Mapeo automático del SVG: $salonId -> $nodeId');
      }
    }
    
    // 2. FALLBACK: Agregar mapeos manuales (si existen y no están ya mapeados)
    final manualMappings = SalonNodeMapping.getMappingsForFloor(piso);
    if (manualMappings != null) {
      for (final entry in manualMappings.entries) {
        final salonId = entry.key;
        final nodeId = entry.value;
        // Solo agregar si no está ya mapeado automáticamente
        if (nodeMap.containsKey(nodeId) && !nodeToSalonMap.containsKey(nodeId)) {
          nodeToSalonMap[nodeId] = salonId;
          print('✅ Mapeo manual (fallback): $salonId -> $nodeId');
        }
      }
    }
    
    // 3. Asociar salones con nodos
    final updatedNodes = <MapNode>[];
    for (final node in nodes) {
      // Si el nodo ya tiene salonId (de nodos especiales como node-salon-A-200), mantenerlo
      final salonId = node.salonId ?? nodeToSalonMap[node.id];
      
      // Crear nodo actualizado con el salonId si existe
      updatedNodes.add(MapNode(
        id: node.id,
        x: node.x,
        y: node.y,
        piso: node.piso,
        tipo: node.tipo,
        salonId: salonId,
      ));
      
      if (salonId != null && node.salonId == null) {
        print('✅ Asociado: $salonId -> ${node.id}');
      }
    }
    
    return updatedNodes;
  }

  /// Limpia y reinicializa un piso
  Future<void> reinitializeFloor({
    required int piso,
    required String svgPath,
  }) async {
    print('🔄 Reinicializando piso $piso...');
    
    // Limpiar primero
    await _storageService.clearFloor(piso);
    
    // Inicializar de nuevo
    await initializeFloor(piso: piso, svgPath: svgPath);
  }

  /// Limpia todos los pisos
  Future<void> clearAllFloors(List<int> pisos) async {
    print('🗑️ Limpiando todos los pisos...');
    
    for (final piso in pisos) {
      await _storageService.clearFloor(piso);
    }
    
    print('✅ Todos los pisos limpiados');
  }
}

